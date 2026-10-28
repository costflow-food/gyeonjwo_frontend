import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_font_sizes.dart';
import '../../../shared/widgets/workspace_shell.dart';
import '../../../shared/workspace_colors.dart';
import '../domain/gmail_connection.dart';
import 'auth_connection_view.dart';
import 'auth_layout.dart';
import 'auth_session_view_model.dart';
import 'gmail_connection_view_model.dart';
import 'widgets/auth_failure_message.dart';
import 'widgets/sign_out_action.dart';

class AccountView extends ConsumerWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionViewModelProvider).asData?.value;
    final isConfigured = session?.isConfigured ?? false;
    final connection = ref.watch(gmailConnectionViewModelProvider);
    final phase = connection.connectionPhase;
    final hasConnection = isConfigured && phase.hasConnection;
    final connectionStatus = !isConfigured ? '연결 전' : phase.label;
    final connectionDescription = !isConfigured
        ? '아직 실제 계정이 연결되지 않은 UI 미리보기입니다.'
        : connection.authFailure?.message ?? phase.description;
    return WorkspaceShell(
    child: Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '계정 설정',
              style: TextStyle(
                fontSize: AppFontSizes.pageTitle,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '내 계정과 Gmail 연결을 확인하세요.',
              style: TextStyle(fontSize: AppFontSizes.bodyLarge, color: muted),
            ),
            const SizedBox(height: 28),
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthInfoTile(
                    icon: Icons.person_outline,
                    title: '구매담당자',
                    description:
                        session?.email ??
                        'Google 계정 정보는 로그인 기능 연결 후 표시됩니다.',
                  ),
                  const Divider(color: line),
                  AuthInfoTile(
                    icon: Icons.link_outlined,
                    title: 'Google 계정 연결',
                    description: connectionDescription,
                    enabled: hasConnection,
                    status: connectionStatus,
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
                  const SizedBox(height: 20),
                  AuthButton(
                    label: !isConfigured
                        ? 'Google 연결 안내'
                        : phase == GmailConnectionPhase.connected
                        ? '권한 다시 선택하기'
                        : '다시 연결하기',
                    onPressed: () => context.go('/login/permissions'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '로그아웃',
                    style: TextStyle(
                      fontSize: AppFontSizes.cardTitle,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isConfigured
                        ? '이 브라우저의 로그인 세션을 종료해요. 서버의 Gmail 연결은 해제되지 않아요.'
                        : '현재는 로그인 화면으로 돌아갑니다. 실제 세션 종료는 Supabase 설정 후 적용됩니다.',
                    style: const TextStyle(
                      fontSize: AppFontSizes.body,
                      color: muted,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => signOutAndLeave(context, ref),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('로그아웃'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: const BorderSide(color: line),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
