import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "app/app_config.dart";
import "app/app_router.dart";
import 'app/ui_preview.dart';
import "features/auth/data/auth_session_data_source.dart";
import "features/auth/data/provider_token_free_local_storage.dart";
import "features/auth/presentation/auth_session_view_model.dart";
import "features/auth/presentation/gmail_connection_view_model.dart";
import "shared/workspace_colors.dart";

final appTheme = _buildTheme();

ThemeData _buildTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      primary: accent,
      error: danger,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: canvas,
    useMaterial3: true,
    // IBM Plex Sans KR for Hangul, Latin and numbers alike.
    fontFamily: GoogleFonts.ibmPlexSansKr().fontFamily,
  );
  return base.copyWith(
    textTheme: GoogleFonts.ibmPlexSansKrTextTheme(base.textTheme)
        .apply(bodyColor: ink, displayColor: ink),
    dividerColor: line,
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.isConfigured) {
    // The design preview page needs no server, so it still opens in debug.
    final route = _hashRoute(Uri.base);
    runApp(
      kDebugMode && route.path == '/ui-preview'
          ? UiPreviewApp(parameters: route.queryParameters, theme: appTheme)
          : MissingConfigApp(missingKeys: AppConfig.missingKeys),
    );
    return;
  }
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
    // Supabase debug logs can include auth state details.
    debug: false,
    authOptions: FlutterAuthClientOptions(
      localStorage: ProviderTokenFreeLocalStorage.forSupabaseUrl(
        AppConfig.supabaseUrl,
      ),
    ),
  );
  await OAuthRedirectGrant.captureFrom(Supabase.instance.client.auth);
  runApp(const ProviderScope(child: MyApp()));
}

/// `/#/ui-preview?screen=queue` → `/ui-preview` with its query.
Uri _hashRoute(Uri base) =>
    Uri.tryParse(base.fragment.isEmpty ? base.path : base.fragment) ??
    Uri(path: '/');

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-run route guards whenever sign-in state changes.
    ref.listen(authSessionViewModelProvider, (_, _) => appRouter.refresh());
    // Leave the connection screen as soon as the server confirms Gmail.
    ref.listen(
      gmailConnectionViewModelProvider.select((value) => value.connectionPhase),
      (_, _) => appRouter.refresh(),
    );
    return ListenableBuilder(
      listenable: appRouter.routeInformationProvider,
      builder: (context, _) {
        final uri = appRouter.routeInformationProvider.value.uri;
        // Preview owns the root Navigator so dialogs use its isolated scope.
        if (kDebugMode && uri.path == '/ui-preview') {
          return UiPreviewApp(parameters: uri.queryParameters, theme: appTheme);
        }
        return MaterialApp.router(
          title: '견줘',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          routerConfig: appRouter,
        );
      },
    );
  }
}

/// Shown instead of a preview mode when the run settings are missing.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key, required this.missingKeys});

  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '견줘',
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '실행 설정이 필요해요',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  '다음 값이 비어 있어요: ${missingKeys.join(", ")}',
                  style: const TextStyle(fontSize: 13, height: 1.7),
                ),
                const SizedBox(height: 16),
                const SelectableText(
                  'flutter run -d chrome --web-port 3000 '
                  '--dart-define-from-file=config/dart_defines.local.json',
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '서버 없이 화면만 보려면 /#/ui-preview 를 여세요.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7C7F85)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
