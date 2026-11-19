import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../shared/formatters.dart';
import '../../../shared/lds_colors.dart';
import '../../../shared/widgets/lds/lds.dart';
import '../../../shared/widgets/mobile_scaffold.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/workspace_shell.dart';
import '../../mailbox_sync/domain/mailbox_sync_status.dart';
import '../../workflow_log/presentation/workflow_log_view.dart';
import '../../workflow_log/presentation/workflow_log_view_model.dart';
import '../../mailbox_sync/presentation/mailbox_sync_view_model.dart';
import '../../send_settings/presentation/send_settings_dialog.dart';
import '../../server_status/domain/server_status.dart';
import '../../server_status/presentation/server_status_view_model.dart';
import '../domain/gmail_connection.dart';
import 'auth_connection_view.dart';
import 'auth_layout.dart';
import 'auth_session_view_model.dart';
import 'gmail_connection_view_model.dart';
import 'widgets/auth_failure_message.dart';
import 'widgets/sign_out_action.dart';
import '../../../app/app_paths.dart';

/// 휴대폰 아래 탭의 '계정 설정' 화면(`/account`). 웹에서는 계정 메뉴가
/// [showAccountSettingsDialog]로 같은 내용을 팝업으로 엽니다.
class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) => WorkspaceShell(
    child: Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: const AccountSettings(),
      ),
    ),
  );
}

/// 계정 설정 내용. 앱에서는 처리 이력과 앱 정보 탭도 제공합니다.
///
/// [inDialog]면 팝업 안에 넣는 모양(카드 틀 없음, 휴대폰 전용 버튼 없음)이고,
/// [requestClose]로 팝업을 닫은 뒤 다른 화면으로 갑니다.
class AccountSettings extends StatefulWidget {
  const AccountSettings({
    super.key,
    this.inDialog = false,
    this.returnTo = AppPaths.account,
    this.requestClose,
    this.onDirtyChanged,
    this.onSavingChanged,
  });

  final bool inDialog;

  /// 권한 화면에서 휴대폰 뒤로 가기가 돌아올 곳.
  final String returnTo;

  /// 팝업을 닫습니다(저장 안 한 설정이 있으면 먼저 묻고). 닫혔으면 true.
  final Future<bool> Function()? requestClose;

  /// 메일 발송 설정 탭에 저장하지 않은 변경이 있는지.
  final ValueChanged<bool>? onDirtyChanged;

  /// 메일 발송 설정을 저장하는 중인지.
  final ValueChanged<bool>? onSavingChanged;

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings>
    with SingleTickerProviderStateMixin {
  static const _pages = ['권한', '메일 발송 설정', '처리 이력', '앱 정보'];

  bool get _showAppTabs => !widget.inDialog && isCompactLayout(context);

  late final TabController _tabs = TabController(
    length: _pages.length,
    vsync: this,
  )..addListener(_syncIndex);
  int _index = 0;

  void _syncIndex() {
    if (_tabs.index != _index) setState(() => _index = _tabs.index);
  }

  void _swipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300 && _index < (_showAppTabs ? _pages.length - 1 : 1)) {
      _tabs.animateTo(_index + 1);
    } else if (velocity > 300 && _index > 0) {
      _tabs.animateTo(_index - 1);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inDialog = widget.inDialog;
    final pages = _showAppTabs ? _pages : _pages.take(2).toList();
    final selectedIndex = _index < pages.length ? _index : 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 화면 제목 '설정'은 상단 바(웹)·앱 바(휴대폰)에, 팝업이면 팝업 머리에 있습니다.
        // Tab text(6.1): 누르면 아래 내용이 바뀝니다.
        Row(
          children: [
            Expanded(
              child: LdsTabBar<int>(
                tabs: [
                  for (final (index, page) in pages.indexed)
                    LdsTabItem(value: index, label: page),
                ],
                selected: selectedIndex,
                onSelected: _tabs.animateTo,
              ),
            ),
            if (_showAppTabs && selectedIndex == 2)
              Transform.translate(
                offset: const Offset(0, -6),
                child: Consumer(
                  builder: (context, ref, child) => IconButton(
                    tooltip: '새로고침',
                    onPressed: () => ref
                        .read(workflowLogViewModelProvider.notifier)
                        .refresh(),
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: _showAppTabs && selectedIndex == 2 ? 8 : 24),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: _swipe,
          child: ClipRect(
            child: Stack(
              children: [
                // Keep each page state while another tab is shown.
                for (final (index, page) in [
                  _PermissionsPage(
                    inDialog: inDialog,
                    returnTo: widget.returnTo,
                    requestClose: widget.requestClose,
                  ),
                  _SendSettingsPage(
                    inDialog: inDialog,
                    onDirtyChanged: widget.onDirtyChanged,
                    onSavingChanged: widget.onSavingChanged,
                  ),
                  if (_showAppTabs) ...[
                    const WorkflowLogView(embedded: true),
                    SizedBox(
                      width: double.infinity,
                      height: MediaQuery.sizeOf(context).height * 0.55,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const BrandLogo(height: 64),
                          const SizedBox(height: 24),
                          SelectableText(
                            '빌드 ${AppConfig.buildRevision}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: LdsColors.mutedStrong,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ].indexed)
                  Visibility(
                    visible: index == selectedIndex,
                    maintainState: true,
                    child: AnimatedSlide(
                      offset: Offset(
                        index == selectedIndex
                            ? 0
                            : (index < selectedIndex ? -1.0 : 1.0),
                        0,
                      ),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: page,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // 앱의 빌드 정보는 앱 정보 탭에서 표시합니다.
        if (!inDialog &&
            !_showAppTabs &&
            AppConfig.buildRevision.isNotEmpty) ...[
          const SizedBox(height: 16),
          SelectableText(
            '빌드 ${AppConfig.buildRevision}',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, color: LdsColors.mutedStrong),
          ),
        ],
      ],
    );
  }
}

/// 권한 탭: 사용자 → 연결·권한 상태 이름표-값 표(값 = 설명, 오른쪽 상태 라벨)
/// → 큰 버튼.
class _PermissionsPage extends ConsumerWidget {
  const _PermissionsPage({
    required this.inDialog,
    required this.returnTo,
    this.requestClose,
  });

  final bool inDialog;
  final String returnTo;
  final Future<bool> Function()? requestClose;

  Future<void> _reconnect(BuildContext context) async {
    final router = GoRouter.of(context);
    final close = requestClose;
    if (close != null && !await close()) return;
    // extra: where phone back returns from the permissions screen.
    router.go('/login/permissions', extra: returnTo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionViewModelProvider).asData?.value;
    final connection = ref.watch(gmailConnectionViewModelProvider);
    final phase = connection.connectionPhase;
    final hasConnection = phase.hasConnection;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const AuthIconBox(icon: Icons.person_outline),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '구매담당자',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: LdsColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session?.email ?? 'Google 계정 정보는 로그인 후 표시됩니다.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: LdsColors.mutedStrong,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LdsKeyValueTable(
          labelWidth: 136,
          rows: [
            _statusRow(
              context,
              'Google 연결',
              connection.authFailure?.message ?? phase.description,
              phase.label,
              hasConnection ? _Status.ok : _Status.off,
            ),
            _statusRow(
              context,
              'Gmail 읽기',
              '수신 메일을 업무 큐로 가져오는 데 사용합니다.',
              !hasConnection
                  ? '연결 전'
                  : phase.canRead
                  ? '허용'
                  : '거부됨',
              !hasConnection
                  ? _Status.off
                  : phase.canRead
                  ? _Status.ok
                  : _Status.bad,
            ),
            _statusRow(
              context,
              'Gmail 발송',
              '메일 발송 권한과 실제 발송 승인 설정은 별개입니다.',
              !hasConnection
                  ? '연결 전'
                  : phase.canSend
                  ? '허용 · 발송 승인은 별도'
                  : '거부됨',
              !hasConnection
                  ? _Status.off
                  : phase.canSend
                  ? _Status.ok
                  : _Status.bad,
            ),
            if (hasConnection && phase.canRead) _mailboxSyncRow(context, ref),
            ?_serverLimitsRow(context, ref),
          ],
        ),
        const SizedBox(height: 24),
        AuthButton(
          label: phase == GmailConnectionPhase.connected
              ? '권한 다시 선택하기'
              : '다시 연결하기',
          onPressed: () => _reconnect(context),
        ),
        // On a phone there is no account menu; sign out lives here.
        if (!inDialog && isCompactLayout(context)) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => signOutAndLeave(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: LdsColors.errorText,
              side: const BorderSide(color: LdsColors.borderStrong),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LdsRadius.buttonLarge),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ],
    );
    // 팝업 안에서는 카드 틀 없이 바로 그립니다.
    return inDialog ? content : LdsPanel(child: content);
  }
}

enum _Status { ok, off, bad }

/// 이름표-값 줄: 값 = 설명(14), 오른쪽 = 상태 라벨.
LdsKeyValueRow _statusRow(
  BuildContext context,
  String label,
  String description,
  String status,
  _Status kind,
) {
  final descriptionText = Text(
    description,
    style: const TextStyle(fontSize: 14, height: 1.5, color: LdsColors.title),
  );
  final statusTag = switch (kind) {
    _Status.ok => LdsTag(
      status,
      tone: LdsTagTone.success,
      foreground: LdsColors.successText,
    ),
    _Status.off => LdsTag(
      status,
      tone: LdsTagTone.warning,
      foreground: LdsColors.warningText,
    ),
    _Status.bad => LdsTag(
      status,
      tone: LdsTagTone.error,
      foreground: LdsColors.errorText,
    ),
  };
  if (isCompactLayout(context)) {
    return LdsKeyValueRow(
      label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [descriptionText, const SizedBox(height: 8), statusTag],
      ),
    );
  }
  return LdsKeyValueRow(label, child: descriptionText, trailing: statusTag);
}

LdsKeyValueRow _mailboxSyncRow(BuildContext context, WidgetRef ref) {
  final sync = ref.watch(mailboxSyncViewModelProvider);
  if (sync.isLoading && !sync.hasValue) {
    return _statusRow(
      context,
      '메일 수신',
      '수신 상태를 확인하고 있습니다.',
      '확인 중',
      _Status.off,
    );
  }
  final (label, description, ok) = _describeSync(sync.asData?.value);
  return _statusRow(
    context,
    '메일 수신',
    description,
    label,
    ok ? _Status.ok : _Status.bad,
  );
}

(String, String, bool) _describeSync(MailboxSyncStatus? status) {
  if (status == null) {
    return ('확인하지 못함', '서버에서 수신 상태를 받아 오지 못했습니다.', false);
  }
  if (!status.connected) {
    return ('연결 전', '연결된 메일함이 없어 메일을 받지 않고 있습니다.', false);
  }
  final synced = status.lastSyncedAt;
  final last = synced == null
      ? '마지막 수신 시각을 알 수 없습니다.'
      : '마지막 수신 ${formatSeoulDateTime(synced.toUtc().toIso8601String())}.';
  if (status.failed) {
    final code = status.lastError == null ? '' : ' (오류 ${status.lastError})';
    return (
      '멈춤',
      '$last 서버가 메일함을 읽지 못하고 있어 그 뒤에 온 메일은 아직 업무 큐에 없습니다.$code',
      false,
    );
  }
  if (status.isStale(DateTime.now())) {
    return ('늦어짐', '$last 그 뒤에 온 메일은 아직 업무 큐에 없을 수 있습니다.', false);
  }
  return ('받는 중', last, true);
}

LdsKeyValueRow? _serverLimitsRow(BuildContext context, WidgetRef ref) {
  final server = ref.watch(serverStatusViewModelProvider).asData?.value;
  if (server == null) return null;
  final String description;
  if (server.notReady) {
    description = '서버 일부가 준비되지 않아 검토와 메일 발송이 멈출 수 있습니다.';
  } else {
    final limited = [
      for (final feature in ServerFeature.values)
        if (server.degraded?.contains(feature) ?? false) feature.label,
    ];
    if (limited.isEmpty) return null;
    description = '지금 쓸 수 없어요: ${limited.join(', ')}';
  }
  return _statusRow(context, '서버 기능', description, '일부 기능 멈춤', _Status.bad);
}

class _SendSettingsPage extends StatelessWidget {
  const _SendSettingsPage({
    required this.inDialog,
    this.onDirtyChanged,
    this.onSavingChanged,
  });

  final bool inDialog;
  final ValueChanged<bool>? onDirtyChanged;
  final ValueChanged<bool>? onSavingChanged;

  @override
  Widget build(BuildContext context) {
    if (inDialog) {
      return SendSettingsDialog(
        embedded: true,
        embeddedPadding: EdgeInsets.zero,
        embeddedDivider: false,
        onDirtyChanged: onDirtyChanged,
        onSavingChanged: onSavingChanged,
      );
    }
    return LdsPanel(
      padding: const EdgeInsets.only(top: 24),
      child: SendSettingsDialog(
        embedded: true,
        onDirtyChanged: onDirtyChanged,
        onSavingChanged: onSavingChanged,
      ),
    );
  }
}
