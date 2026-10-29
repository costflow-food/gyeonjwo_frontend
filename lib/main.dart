import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "app/app_config.dart";
import "app/app_router.dart";
import "features/auth/data/auth_session_data_source.dart";
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
    await OAuthRedirectGrant.captureFrom(Supabase.instance.client.auth);
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-run route guards whenever sign-in state changes.
    ref.listen(authSessionViewModelProvider, (_, _) => appRouter.refresh());
    return MaterialApp.router(
      title: '견줘',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFED2635)),
        scaffoldBackgroundColor: const Color(0xFFFCFCFD),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF191A1B),
          displayColor: const Color(0xFF191A1B),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
