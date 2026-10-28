import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_font_sizes.dart';
import '../../../shared/workspace_colors.dart';
import 'auth_layout.dart';

class AuthPermissionsView extends StatelessWidget {
  const AuthPermissionsView({super.key});

  @override
  Widget build(BuildContext context) => AuthLayout(
    backPath: '/login',
    maxWidth: 1280,
    compact: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(
          step: '02 / 연결 안내',
          title: '연결 전에 확인해 주세요',
          description: '견줘를 시작할 때 Google 로그인과 Gmail 권한을 함께 요청할 예정이에요. 어떤 용도로 쓰이는지 먼저 확인하세요.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth >= 1000 &&
                MediaQuery.textScalerOf(context).scale(AppFontSizes.body) <=
                    AppFontSizes.body * 1.5;
            if (columns) {
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _RequestedPermissions()),
                  SizedBox(width: 24),
                  Expanded(child: _DataProcessing()),
                ],
              );
            }
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RequestedPermissions(),
                SizedBox(height: 20),
                _DataProcessing(),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            const notice = Text(
              '지금은 실제 동의를 받거나 권한을 요청하지 않습니다.\nGoogle 계정 선택·동의 화면은 인증 기능을 연결한 뒤 열립니다.',
              style: TextStyle(
                fontSize: AppFontSizes.secondary,
                color: muted,
                height: 1.8,
              ),
            );
            final next = AuthButton(
              label: '연결 상태 미리보기',
              onPressed: () => context.go('/login/connection'),
            );
            if (constraints.maxWidth >= 800) {
              return Row(
                children: [
                  const Expanded(child: notice),
                  const SizedBox(width: 24),
                  SizedBox(width: 280, child: next),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [notice, const SizedBox(height: 16), next],
            );
          },
        ),
      ],
    ),
  );
}

class _RequestedPermissions extends StatelessWidget {
  const _RequestedPermissions();

  @override
  Widget build(BuildContext context) => const AuthCard(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '요청하는 권한',
          style: TextStyle(
            fontSize: AppFontSizes.cardTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8),
        AuthInfoTile(
          icon: Icons.person_outline,
          title: 'Google 계정으로 가입·로그인',
          description: 'Google 계정의 기본 프로필과 이메일 주소로 사용자를 식별하고 견줘 계정을 만들어요. 인증은 Supabase Auth를 통해 처리할 예정이에요.',
        ),
        Divider(height: 1, color: line),
        AuthInfoTile(
          icon: Icons.mark_email_read_outlined,
          title: 'Gmail 읽기',
          description: '수신 메일을 읽어 구매 요청을 업무 큐로 가져오고 검토에 활용해요. 읽기 권한을 허용하지 않으면 자동 수신을 사용할 수 없어요.',
        ),
        Divider(height: 1, color: line),
        AuthInfoTile(
          icon: Icons.send_outlined,
          title: 'Gmail 발송',
          description: '연결한 Gmail 계정으로 메일을 보내는 데 사용해요. 발송 권한을 허용하지 않으면 메일 발송만 사용할 수 없어요.',
        ),
        SizedBox(height: 12),
        AuthNotice(
          text: '발송 권한과 실제 발송 승인 설정은 별개예요. Google에서 권한을 허용하는 것만으로 자동 발송 승인이 설정되지는 않아요.',
        ),
      ],
    ),
  );
}

class _DataProcessing extends StatelessWidget {
  const _DataProcessing();

  @override
  Widget build(BuildContext context) => const AuthCard(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '데이터는 어디에서 처리하나요?',
          style: TextStyle(
            fontSize: AppFontSizes.cardTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Google은 계정 인증과 Gmail 접근을, Supabase는 로그인 세션을 처리해요. 견줘 서버는 계정 연결과 메일 수신·발송을 처리할 예정이에요.',
          style: TextStyle(
            fontSize: AppFontSizes.bodyLarge,
            color: muted,
            height: 1.8,
          ),
        ),
        SizedBox(height: 16),
        Text(
          '요청 분석에 필요한 메일 내용은 외부 LLM 제공업체에 전달될 수 있어요. 제공업체와 전달 데이터 범위는 아직 확정 전이며, 실제 연결을 시작하기 전에 구체적으로 안내할 예정이에요.',
          style: TextStyle(
            fontSize: AppFontSizes.bodyLarge,
            color: muted,
            height: 1.8,
          ),
        ),
        SizedBox(height: 20),
        AuthNotice(
          text: '계속 메일을 수신할 수 있도록 오프라인 접근도 요청할 예정이에요. Google 계정 선택과 권한 동의는 Google 화면에서 직접 진행하며, 읽기·발송 권한은 각각 선택할 수 있어요.',
        ),
      ],
    ),
  );
}
