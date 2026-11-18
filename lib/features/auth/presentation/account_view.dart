import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../shared/formatters.dart';
import '../../../shared/lds_colors.dart';
import '../../../shared/widgets/lds/lds.dart';
import '../../../shared/widgets/mobile_scaffold.dart';
import '../../../shared/widgets/workspace_shell.dart';
import '../../mailbox_sync/domain/mailbox_sync_status.dart';
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

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView>
    with SingleTickerProviderStateMixin {
  static const _pages = ['권한', '메일 발송 설정'];

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
    if (velocity < -300 && _index < _pages.length - 1) {
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
    return WorkspaceShell(
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 화면 제목 '설정'은 상단 바(웹)·앱 바(휴대폰)에 있습니다.
              // Tab text(6.1): 누르면 아래 내용이 바뀝니다.
              LdsTabBar<int>(
                tabs: [
                  for (final (index, page) in _pages.indexed)
                    LdsTabItem(value: index, label: page),
                ],
                selected: _index,
                onSelected: _tabs.animateTo,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: _swipe,
                child: ClipRect(
                  child: Stack(
                    children: [
                      // Both pages keep their state (e.g. unsaved settings)
                      // while the other one is shown.
                      for (final (index, page) in const [
                        _PermissionsPage(),
                        _SendSettingsPage(),
                      ].indexed)
                        Visibility(
                          visible: index == _index,
                          maintainState: true,
                          child: AnimatedSlide(
                            offset: Offset(
                              index == _index
                                  ? 0
                                  : (index < _index ? -1.0 : 1.0),
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
              // 휴대폰 아래 탭에는 실행 로그가 없어 여기서 들어갑니다.
              if (isCompactLayout(context)) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: LdsButton(
                    label: '처리 이력',
                    icon: Icons.history,
                    variant: LdsButtonVariant.outlinedNeutral,
                    onPressed: () => context.go(AppPaths.logs),
                  ),
                ),
              ],
              if (AppConfig.buildRevision.isNotEmpty) ...[
                const SizedBox(height: 16),
                SelectableText(
                  '빌드 ${AppConfig.buildRevision}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 13,
                    color: LdsColors.mutedStrong,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 권한 탭: 사용자 → 연결·권한 상태 이름표-값 표(값 = 설명, 오른쪽 상태 라벨)
/// → 큰 버튼.
class _PermissionsPage extends ConsumerWidget {
  const _PermissionsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionViewModelProvider).asData?.value;
    final connection = ref.watch(gmailConnectionViewModelProvider);
    final phase = connection.connectionPhase;
    final hasConnection = phase.hasConnection;
    return LdsPanel(
      child: Column(
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
            // extra: where phone back returns from the permissions screen.
            onPressed: () =>
                context.go('/login/permissions', extra: '/account'),
          ),
          // On a phone there is no account menu; sign out lives here.
          if (isCompactLayout(context)) ...[
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
      ),
    );
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
  const _SendSettingsPage();

  @override
  Widget build(BuildContext context) => const LdsPanel(
    padding: EdgeInsets.only(top: 24),
    child: SendSettingsDialog(embedded: true),
  );
}
