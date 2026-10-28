import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_font_sizes.dart';
import '../../../shared/widgets/workspace_shell.dart';
import '../../../shared/workspace_colors.dart';
import 'auth_layout.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) => WorkspaceShell(
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
                  const AuthInfoTile(
                    icon: Icons.person_outline,
                    title: '구매담당자',
                    description: 'Google 계정 정보는 로그인 기능 연결 후 표시됩니다.',
                  ),
                  const Divider(color: line),
                  const AuthInfoTile(
                    icon: Icons.link_outlined,
                    title: 'Google 계정 연결',
                    description: '아직 실제 계정이 연결되지 않은 UI 미리보기입니다.',
                    enabled: false,
                    status: '연결 전',
                  ),
                  const AuthInfoTile(
                    icon: Icons.inbox_outlined,
                    title: 'Gmail 읽기',
                    description: '수신 메일을 업무 큐로 가져오는 데 사용해요.',
                    enabled: false,
                    status: '연결 전',
                  ),
                  const AuthInfoTile(
                    icon: Icons.send_outlined,
                    title: 'Gmail 발송',
                    description: '메일 발송 권한과 실제 발송 승인 설정은 별개예요.',
                    enabled: false,
                    status: '연결 전',
                  ),
                  const SizedBox(height: 20),
                  AuthButton(
                    label: 'Google 연결 안내',
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
                  const Text(
                    '현재는 로그인 화면으로 돌아갑니다. 실제 세션 종료는 인증 기능을 연결할 때 적용합니다.',
                    style: TextStyle(
                      fontSize: AppFontSizes.body,
                      color: muted,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/login'),
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
