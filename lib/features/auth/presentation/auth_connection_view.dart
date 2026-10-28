import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_font_sizes.dart';
import '../../../shared/workspace_colors.dart';
import '../domain/auth_failure.dart';
import '../domain/gmail_connection.dart';
import 'auth_layout.dart';
import 'auth_session_view_model.dart';
import 'gmail_connection_view_model.dart';
import 'widgets/auth_failure_message.dart';

extension GmailConnectionPhaseCopy on GmailConnectionPhase {
  String get label => switch (this) {
    GmailConnectionPhase.connecting => '연결 중',
    GmailConnectionPhase.connected => '연결 성공',
    GmailConnectionPhase.readDenied => '읽기 거부',
    GmailConnectionPhase.sendDenied => '발송 거부',
    GmailConnectionPhase.bothDenied => '읽기·발송 거부',
    GmailConnectionPhase.failed => '연결 실패',
    GmailConnectionPhase.reconnect => '재연결 필요',
  };

  IconData get icon => switch (this) {
    GmailConnectionPhase.connecting => Icons.sync,
    GmailConnectionPhase.connected => Icons.check_circle_outline,
    GmailConnectionPhase.readDenied => Icons.mark_email_unread_outlined,
    GmailConnectionPhase.sendDenied => Icons.send_outlined,
    GmailConnectionPhase.bothDenied => Icons.mail_lock_outlined,
    GmailConnectionPhase.failed => Icons.error_outline,
    GmailConnectionPhase.reconnect => Icons.link_off,
  };

  String get title => switch (this) {
    GmailConnectionPhase.connecting => '계정 연결을 확인하고 있어요',
    GmailConnectionPhase.connected => 'Gmail 연결이 준비됐어요',
    GmailConnectionPhase.readDenied => '메일 읽기 권한이 필요해요',
    GmailConnectionPhase.sendDenied => '메일 수신부터 시작할 수 있어요',
    GmailConnectionPhase.bothDenied => 'Gmail 권한을 확인해 주세요',
    GmailConnectionPhase.failed => '계정을 연결하지 못했어요',
    GmailConnectionPhase.reconnect => 'Google 계정을 다시 연결해 주세요',
  };

  String get description => switch (this) {
    GmailConnectionPhase.connecting => 'Google 인증 후 견줘 서버의 연결 결과를 기다리고 있어요.',
    GmailConnectionPhase.connected => '연결이 완료되면 수신 메일을 업무 큐에서 확인할 수 있어요.',
    GmailConnectionPhase.readDenied =>
      '로그인은 완료됐지만 Gmail 읽기 권한이 없어 자동 수신을 시작할 수 없어요.',
    GmailConnectionPhase.sendDenied =>
      'Gmail 읽기는 허용됐어요. 발송 권한이 없어 메일 발송만 사용할 수 없어요.',
    GmailConnectionPhase.bothDenied =>
      '로그인은 완료됐지만 읽기와 발송 권한이 없어 메일 기능을 사용할 수 없어요.',
    GmailConnectionPhase.failed => '견줘 서버의 연결을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.',
    GmailConnectionPhase.reconnect =>
      '계정 연결이 만료되었거나 권한이 변경되었어요. 다시 연결하면 메일 기능을 사용할 수 있어요.',
  };

  bool get hasConnection => switch (this) {
    GmailConnectionPhase.connected ||
    GmailConnectionPhase.readDenied ||
    GmailConnectionPhase.sendDenied ||
    GmailConnectionPhase.bothDenied => true,
    _ => false,
  };
  bool get canRead =>
      this == GmailConnectionPhase.connected ||
      this == GmailConnectionPhase.sendDenied;
  bool get canSend =>
      this == GmailConnectionPhase.connected ||
      this == GmailConnectionPhase.readDenied;
}

class AuthConnectionView extends ConsumerWidget {
  const AuthConnectionView({super.key, this.previewPhase});

  /// `?state=` preview, used only when Supabase settings are absent.
  final GmailConnectionPhase? previewPhase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionViewModelProvider).asData?.value;
    final isPreview = session == null || !session.isConfigured;
    final Widget content;
    if (isPreview) {
      content = _PreviewConnection(
        phase: previewPhase ?? GmailConnectionPhase.connecting,
      );
    } else {
      final connection = ref.watch(gmailConnectionViewModelProvider);
      // A retry keeps the previous error while loading; show it only after.
      final failure = connection.isLoading ? null : connection.authFailure;
      content = _ConnectionCard(
        phase: connection.connectionPhase,
        email: connection.asData?.value.email ?? session.email,
        failure: failure,
        // Sign-in succeeds before the server connection; show it separately.
        signedIn: session.isSignedIn,
        // Only an unknown outcome is retried; other failures need re-consent.
        onRetry: failure == null || failure.retryable
            ? ref.read(gmailConnectionViewModelProvider.notifier).retry
            : null,
      );
    }
    return AuthLayout(
      backPath: '/login/permissions',
      compact: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: content,
        ),
      ),
    );
  }
}

class _PreviewConnection extends StatelessWidget {
  const _PreviewConnection({required this.phase});
  final GmailConnectionPhase phase;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ConnectionCard(phase: phase, isPreview: true),
      const SizedBox(height: 16),
      const Text(
        '화면 상태 미리보기',
        style: TextStyle(fontSize: AppFontSizes.secondary, color: muted),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in GmailConnectionPhase.values)
            ChoiceChip(
              label: Text(value.label),
              selected: value == phase,
              selectedColor: blush,
              onSelected: (_) =>
                  context.go('/login/connection?state=${value.name}'),
            ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'Supabase 설정 없이 실행한 미리보기입니다. 실제 로그인·메일 수신·발송은 실행되지 않습니다.',
        style: TextStyle(fontSize: AppFontSizes.secondary, color: muted),
      ),
    ],
  );
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.phase,
    this.email,
    this.failure,
    this.onRetry,
    this.isPreview = false,
    this.signedIn = false,
  });

  final GmailConnectionPhase phase;
  final String? email;
  final AuthFailure? failure;

  /// Re-sends a pending grant or reloads the server state. Null means the
  /// user has to go through Google consent again.
  final VoidCallback? onRetry;
  final bool isPreview;

  /// Supabase session exists, even if the Gmail connection failed.
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final preview = phase;
    final connected = phase == GmailConnectionPhase.connected;
    final description = failure?.message ?? phase.description;
    final loggedIn = preview.hasConnection || signedIn;
    // Re-consent cannot fix missing build settings; let the user continue.
    final serverNotReady = failure?.code == AuthFailureCode.notConfigured;
    return AuthCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: connected ? const Color(0xFFECF6F0) : blush,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  preview.icon,
                  size: 24,
                  color: connected ? const Color(0xFF287451) : accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '03 / 계정 연결',
                      style: TextStyle(
                        color: accent,
                        fontSize: AppFontSizes.secondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      preview.title,
                      style: const TextStyle(
                        fontSize: AppFontSizes.pageTitle,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: AppFontSizes.bodyLarge,
              color: muted,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 16),
          if (phase == GmailConnectionPhase.connecting) ...[
            // Indeterminate: the server does not report progress steps.
            const LinearProgressIndicator(
              color: accent,
              backgroundColor: blush,
              minHeight: 4,
            ),
            const SizedBox(height: 16),
            AuthNotice(
              text: isPreview
                  ? '연결 중 화면 예시입니다. 현재 서버 요청은 진행되지 않으며, 아래에서 다른 상태를 선택해 확인할 수 있어요.'
                  : '견줘 서버가 Google 권한을 확인하고 메일 자동 수신을 준비하고 있어요. 결과가 나올 때까지 이 창을 닫지 말아 주세요.',
            ),
          ] else ...[
            _ConnectionPermissionRow(
              icon: Icons.person_outline,
              title: '견줘 로그인',
              description: !loggedIn
                  ? '계정 연결 상태를 다시 확인해야 해요.'
                  : isPreview
                  ? 'Google 계정 인증 완료 상태의 예시예요.'
                  : email == null
                  ? 'Google 계정 인증을 마쳤어요.'
                  : '$email 계정으로 로그인했어요.',
              enabled: loggedIn,
              status: loggedIn ? '로그인 완료' : '확인 필요',
            ),
            const Divider(height: 1, color: line),
            _ConnectionPermissionRow(
              icon: Icons.inbox_outlined,
              title: 'Gmail 자동 수신',
              description: preview.canRead
                  ? '받은 메일을 업무 큐로 가져올 수 있어요.'
                  : '읽기 권한과 계정 연결이 필요해요.',
              enabled: preview.canRead,
              status: preview.canRead ? '사용 가능' : '사용 불가',
            ),
            const Divider(height: 1, color: line),
            _ConnectionPermissionRow(
              icon: Icons.send_outlined,
              title: 'Gmail 발송',
              description: preview.canSend
                  ? '실제 발송 승인 설정은 별도로 확인해 주세요.'
                  : '발송 권한과 계정 연결이 필요해요.',
              enabled: preview.canSend,
              status: preview.canSend ? '권한 허용 · 발송 승인은 별도' : '사용 불가',
            ),
            const SizedBox(height: 16),
            if (preview.hasConnection || serverNotReady)
              AuthButton(
                label: isPreview ? '업무 큐 미리보기' : '업무 큐로 이동',
                onPressed: () => context.go('/'),
              )
            else if (phase == GmailConnectionPhase.failed && onRetry != null)
              AuthButton(
                label: '다시 시도하기',
                onPressed: onRetry!,
                icon: Icons.refresh,
              )
            else
              AuthButton(
                label: phase == GmailConnectionPhase.failed && isPreview
                    ? '다시 시도하기'
                    : '다시 연결하기',
                onPressed: () => context.go('/login/permissions'),
                icon: Icons.refresh,
              ),
            if (preview.hasConnection && !connected) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => context.go('/login/permissions'),
                child: const Text('권한 다시 선택하기'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ConnectionPermissionRow extends StatelessWidget {
  const _ConnectionPermissionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final String status;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final inline =
            constraints.maxWidth >= 480 &&
            MediaQuery.textScalerOf(context).scale(AppFontSizes.body) <=
                AppFontSizes.body * 1.5;
        final statusText = Text(
          status,
          textAlign: inline ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: AppFontSizes.secondary,
            fontWeight: FontWeight.w600,
            color: enabled ? const Color(0xFF287451) : muted,
            height: 1.5,
          ),
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: enabled ? blush : canvas,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: enabled ? accent : muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppFontSizes.bodyLarge,
                      fontWeight: FontWeight.w700,
                      color: enabled ? ink : muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: AppFontSizes.body,
                      color: muted,
                      height: 1.5,
                    ),
                  ),
                  if (!inline) ...[const SizedBox(height: 4), statusText],
                ],
              ),
            ),
            if (inline) ...[
              const SizedBox(width: 12),
              SizedBox(width: 155, child: statusText),
            ],
          ],
        );
      },
    ),
  );
}
