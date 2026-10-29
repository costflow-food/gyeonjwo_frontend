import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "app/app_config.dart";
import "app/app_router.dart";
import 'app/ui_preview.dart';
import "features/auth/data/provider_token_free_local_storage.dart";
import "features/auth/presentation/auth_session_view_model.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isAuthConfigured) {
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
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-run route guards whenever sign-in state changes.
    ref.listen(authSessionViewModelProvider, (_, _) => appRouter.refresh());
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFED2635)),
      scaffoldBackgroundColor: const Color(0xFFFCFCFD),
      useMaterial3: true,
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF191A1B),
        displayColor: const Color(0xFF191A1B),
      ),
    );
    return ListenableBuilder(
      listenable: appRouter.routeInformationProvider,
      builder: (context, _) {
        final uri = appRouter.routeInformationProvider.value.uri;
        // Preview owns the root Navigator so dialogs use its isolated scope.
        if (kDebugMode && uri.path == '/ui-preview') {
          return UiPreviewApp(parameters: uri.queryParameters, theme: theme);
        }
        return MaterialApp.router(
          title: '견줘',
          debugShowCheckedModeBanner: false,
          theme: theme,
          routerConfig: appRouter,
        );
      },
    );
  }
}
