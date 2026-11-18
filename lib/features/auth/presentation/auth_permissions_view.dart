import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_font_sizes.dart';
import '../../../shared/lds_colors.dart';
import '../domain/auth_failure.dart';
import 'auth_layout.dart';
import 'auth_session_view_model.dart';
import 'widgets/auth_failure_message.dart';

class AuthPermissionsView extends ConsumerStatefulWidget {
  const AuthPermissionsView({super.key});

  @override
  ConsumerState<AuthPermissionsView> createState() =>
      _AuthPermissionsViewState();
}

class _AuthPermissionsViewState extends ConsumerState<AuthPermissionsView> {
  bool _starting = false;

  // In the app, sign-in opens a browser; if the user backs out of it no
  // callback arrives, so re-enable the button when the app is shown again.
  late final _lifecycle = AppLifecycleListener(
    onResume: () {
      if (mounted && _starting) setState(() => _starting = false);
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _starting = true);
    try {
      await ref.read(authSessionViewModelProvider.notifier).signInWithGoogle();
      // The app returns here after consent (web reloads the page instead);
      // the connection screen shows what the server made of the new grant.
      if (!kIsWeb && mounted) context.go('/login/connection');
    } catch (error) {
      if (!mounted) return;
      setState(() => _starting = false);
      final message = error is AuthFailure
          ? error.message
          : 'Google 로그인을 시작하지 못했어요. 다시 시도해 주세요.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Signed in, '/login' only redirects forward; on a phone go back to the
    // screen that opened this one (passed as extra), else the work queue.
    final signedIn =
        ref.watch(authSessionViewModelProvider).asData?.value.isSignedIn ??
        false;
    final origin = GoRouterState.of(context).extra;
    return AuthLayout(
      backPath: '/login',
      phoneBackPath: signedIn
          ? (origin is String && origin.startsWith('/') ? origin : '/')
          : null,
      maxWidth: 1280,
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeading(
            step: '02 / 연결 안내',
            title: '연결 전에 확인해 주세요',
            description: 'Thoner를 시작할 때 Google 로그인과 Gmail 권한을 함께 요청해요. 어떤 용도로 쓰이는지 먼저 확인하세요.',
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
              final notice = Text(
                '계속하면 Google 계정 선택·권한 동의 화면으로 이동해요.\n읽기·발송 권한은 Google 화면에서 각각 선택할 수 있어요.',
                style: TextStyle(
                  fontSize: AppFontSizes.secondary,
                  color: LdsColors.muted,
                  height: 1.8,
                ),
              );
              final next = AuthButton(
                label: _starting ? 'Google로 이동 중…' : 'Google로 계속하기',
                onPressed: _starting ? () {} : _continueWithGoogle,
              );
              if (constraints.maxWidth >= 800) {
                return Row(
                  children: [
                    Expanded(child: notice),
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
}

const double _cardTitleSize = 18;

class _RequestedPermissions extends StatelessWidget {
  const _RequestedPermissions();

  @override
  Widget build(BuildContext context) => AuthCard(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '요청하는 권한',
          style: TextStyle(
            // 이 화면 시안은 카드 제목 18(앱 토큰 17과 다름).
            fontSize: _cardTitleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8),
        AuthInfoTile(
          icon: Icons.person_outline,
          title: 'Google 계정으로 가입·로그인',
          description: 'Google 계정의 기본 프로필과 이메일 주소로 사용자를 식별하고 Thoner 계정을 만들어요. 인증은 Supabase Auth가 처리해요.',
        ),
        Divider(height: 1, color: LdsColors.line),
        AuthInfoTile(
          icon: Icons.mark_email_read_outlined,
          title: 'Gmail 읽기',
          description: '수신 메일을 읽어 구매 요청을 Tasks로 가져오고 검토에 활용해요. 읽기 권한을 허용하지 않으면 자동 수신을 사용할 수 없어요.',
        ),
        Divider(height: 1, color: LdsColors.line),
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
  Widget build(BuildContext context) => AuthCard(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '데이터는 어디에서 처리하나요?',
          style: TextStyle(
            // 이 화면 시안은 카드 제목 18(앱 토큰 17과 다름).
            fontSize: _cardTitleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Google은 계정 인증과 Gmail 접근을, Supabase는 로그인 세션을 처리해요. Thoner 서버는 계정 연결과 메일 수신·발송을 처리해요. Google 연결 정보는 HTTPS로 Thoner 서버에만 전달하고 브라우저에 저장하지 않아요.',
          style: TextStyle(
            fontSize: AppFontSizes.bodyLarge,
            color: LdsColors.muted,
            height: 1.8,
          ),
        ),
        SizedBox(height: 16),
        Text(
          '요청 분석에 필요한 메일 내용은 외부 LLM 제공업체에 전달될 수 있어요. 제공업체와 전달 데이터 범위는 아직 확정 전이며, 실제 연결을 시작하기 전에 구체적으로 안내할 예정이에요.',
          style: TextStyle(
            fontSize: AppFontSizes.bodyLarge,
            color: LdsColors.muted,
            height: 1.8,
          ),
        ),
        SizedBox(height: 20),
        AuthNotice(
          text: '창을 닫아도 메일을 계속 수신할 수 있도록 오프라인 접근도 요청해요. Google 계정 선택과 권한 동의는 Google 화면에서 직접 진행하며, 읽기·발송 권한은 각각 선택할 수 있어요.',
        ),
      ],
    ),
  );
}
