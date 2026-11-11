import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_font_sizes.dart';
import '../../../shared/formatters.dart';
import '../../../shared/theme/theme_picker.dart';
import '../../../shared/widgets/workspace_shell.dart';
import '../../../shared/workspace_colors.dart';
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

/// 설정: 권한 | 메일 발송 설정 | 화면 테마. 탭을 누르거나 옆으로 밀어 넘깁니다.
class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView>
    with SingleTickerProviderStateMixin {
  static const _pages = ['권한', '메일 발송 설정', '화면 테마'];

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
              const Text(
                '설정',
                style: TextStyle(
                  fontSize: AppFontSizes.pageTitle,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: context.palette.accentText,
                unselectedLabelColor: context.palette.muted,
                indicatorColor: context.palette.accent,
                dividerColor: context.palette.line,
                labelStyle: const TextStyle(
                  fontSize: AppFontSizes.navigation,
                  fontWeight: FontWeight.w700,
                ),
                tabs: [for (final page in _pages) Tab(text: page)],
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
                        _ThemePage(),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// 계정과 Gmail 읽기·발송 권한.
class _PermissionsPage extends ConsumerWidget {
  const _PermissionsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionViewModelProvider).asData?.value;
    final connection = ref.watch(gmailConnectionViewModelProvider);
    final phase = connection.connectionPhase;
    final hasConnection = phase.hasConnection;
    return AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthInfoTile(
            icon: Icons.person_outline,
            title: '구매담당자',
            description: session?.email ?? 'Google 계정 정보는 로그인 후 표시됩니다.',
          ),
          Divider(color: context.palette.line),
          AuthInfoTile(
            icon: Icons.link_outlined,
            title: 'Google 계정 연결',
            description: connection.authFailure?.message ?? phase.description,
            enabled: hasConnection,
            status: phase.label,
          ),
          AuthInfoTile(
            icon: Icons.inbox_outlined,
            title: 'Gmail 읽기',
            description: '수신 메일을 업무 큐로 가져오는 데 사용해요.',
            enabled: hasConnection && phase.canRead,
            status: !hasConnection
                ? '연결 전'
                : phase.canRead
                ? '허용'
                : '거부됨',
          ),
          AuthInfoTile(
            icon: Icons.send_outlined,
            title: 'Gmail 발송',
            description: '메일 발송 권한과 실제 발송 승인 설정은 별개예요.',
            enabled: hasConnection && phase.canSend,
            status: !hasConnection
                ? '연결 전'
                : phase.canSend
                ? '허용 · 발송 승인은 별도'
                : '거부됨',
          ),
          if (hasConnection && phase.canRead) const _MailboxSyncTile(),
          const _ServerLimitsTile(),
          const SizedBox(height: 20),
          AuthButton(
            label: phase == GmailConnectionPhase.connected
                ? '권한 다시 선택하기'
                : '다시 연결하기',
            onPressed: () => context.go('/login/permissions'),
          ),
        ],
      ),
    );
  }
}

/// 메일함 수신 상태. 수신이 멈추거나 늦어지면 마지막 수신 시각과 함께 알립니다.
class _MailboxSyncTile extends ConsumerWidget {
  const _MailboxSyncTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(mailboxSyncViewModelProvider);
    if (sync.isLoading && !sync.hasValue) {
      return const AuthInfoTile(
        icon: Icons.mark_email_unread_outlined,
        title: '메일 수신',
        description: '수신 상태를 확인하고 있어요.',
      );
    }
    final status = sync.asData?.value;
    final (label, description, ok) = _describe(status);
    return AuthInfoTile(
      icon: Icons.mark_email_unread_outlined,
      title: '메일 수신',
      description: description,
      enabled: ok,
      status: label,
      statusColor: ok ? null : danger,
    );
  }

  static (String, String, bool) _describe(MailboxSyncStatus? status) {
    if (status == null) {
      return ('확인하지 못함', '서버에서 수신 상태를 받아 오지 못했어요.', false);
    }
    if (!status.connected) {
      return ('연결 전', '연결된 메일함이 없어 메일을 받지 않고 있어요.', false);
    }
    final synced = status.lastSyncedAt;
    final last = synced == null
        ? '마지막 수신 시각을 알 수 없어요.'
        : '마지막 수신 ${formatSeoulDateTime(synced.toUtc().toIso8601String())}.';
    if (status.failed) {
      final code = status.lastError == null ? '' : ' (오류 ${status.lastError})';
      return (
        '멈춤',
        '$last 서버가 메일함을 읽지 못하고 있어 그 뒤에 온 메일은 아직 업무 큐에 없어요.$code',
        false,
      );
    }
    if (status.isStale(DateTime.now())) {
      return ('늦어짐', '$last 그 뒤에 온 메일은 아직 업무 큐에 없을 수 있어요.', false);
    }
    return ('받는 중', last, true);
  }
}

/// 서버가 알려 준 멈춘 기능. 모두 정상이거나 확인하지 못하면 보이지 않습니다.
class _ServerLimitsTile extends ConsumerWidget {
  const _ServerLimitsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.watch(serverStatusViewModelProvider).asData?.value;
    if (server == null) return const SizedBox.shrink();
    final String description;
    if (server.notReady) {
      description = '서버 일부가 준비되지 않아 검토와 메일 발송이 멈출 수 있어요.';
    } else {
      final limited = [
        for (final feature in ServerFeature.values)
          if (server.degraded?.contains(feature) ?? false) feature.label,
      ];
      if (limited.isEmpty) return const SizedBox.shrink();
      description = '지금 쓸 수 없어요: ${limited.join(', ')}';
    }
    return AuthInfoTile(
      icon: Icons.report_gmailerrorred_outlined,
      title: '서버 기능',
      description: description,
      enabled: false,
      status: '일부 기능 멈춤',
      statusColor: danger,
    );
  }
}

/// SCR-008 메일함 기본 발송 설정. 발송 설정은 이 페이지에서만 엽니다.
class _SendSettingsPage extends StatelessWidget {
  const _SendSettingsPage();

  @override
  Widget build(BuildContext context) => const AuthCard(
    padding: EdgeInsets.only(top: 24),
    child: SendSettingsDialog(embedded: true),
  );
}

class _ThemePage extends StatelessWidget {
  const _ThemePage();

  @override
  Widget build(BuildContext context) => const AuthCard(child: ThemePicker());
}
