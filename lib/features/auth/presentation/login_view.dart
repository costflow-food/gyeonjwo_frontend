import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_font_sizes.dart';
import '../../../shared/workspace_colors.dart';
import 'auth_layout.dart';
import 'auth_session_view_model.dart';
import 'widgets/auth_failure_message.dart';
import 'widgets/google_sign_in_button.dart';

class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConfigured =
        ref.watch(authSessionViewModelProvider).asData?.value.isConfigured ??
        false;
    final redirectFailure = ref.watch(authRedirectFailureProvider);
    return AuthLayout(
    child: LayoutBuilder(
      builder: (context, constraints) {
        const introduction = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PURCHASING WORKSPACE',
              style: TextStyle(
                fontSize: AppFontSizes.secondary,
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
            SizedBox(height: 24),
            Text(
              '흩어진 구매 요청,\n검토의 시작을 한곳에서.',
              style: TextStyle(
                fontSize: AppFontSizes.brand,
                height: 1.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '메일로 받은 요청부터 구매 판단에 필요한 근거까지.\n견줘와 함께 차근차근 확인하세요.',
              style: TextStyle(
                fontSize: AppFontSizes.bodyLarge,
                color: muted,
                height: 1.9,
              ),
            ),
            SizedBox(height: 28),
            AuthInfoTile(
              icon: Icons.inbox_outlined,
              title: '메일에서 업무 큐로',
              description: 'Gmail로 들어온 요청을 모아 확인해요.',
            ),
            AuthInfoTile(
              icon: Icons.fact_check_outlined,
              title: '구매 판단을 위한 근거 정리',
              description: '요청 내용과 거래처 정보를 함께 검토해요.',
            ),
          ],
        );

        final login = AuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeading(
                step: '01 / 시작하기',
                title: '견줘에 오신 것을 환영해요',
                description:
                    'Google 계정 하나로 가입하고 로그인하세요.\n처음 오셨다면 계정이 함께 만들어집니다.',
              ),
              if (redirectFailure != null) ...[
                AuthNotice(text: redirectFailure.message),
                const SizedBox(height: 16),
              ],
              // Consent guidance comes first; Google opens from that screen.
              GoogleSignInButton(
                onPressed: () => context.go('/login/permissions'),
              ),
              const SizedBox(height: 24),
              const AuthNotice(
                text: '다음 화면에서 Gmail 읽기·발송 권한과 데이터 처리 목적을 먼저 안내해 드려요. 권한 선택은 Google 동의 화면에서 직접 진행합니다.',
              ),
              if (!isConfigured) ...[
                const SizedBox(height: 20),
                const Text(
                  'Supabase 설정 없이 실행한 화면 미리보기입니다. 버튼을 눌러도 Google 로그인이나 메일 접근은 실행되지 않습니다.',
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: muted,
                    height: 1.8,
                  ),
                ),
              ],
            ],
          ),
        );

        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(child: introduction),
              const SizedBox(width: 64),
              Expanded(child: login),
            ],
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [introduction, const SizedBox(height: 32), login],
            ),
          ),
        );
      },
    ),
  );
  }
}
