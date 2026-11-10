import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "app/app_config.dart";
import "app/app_router.dart";
import "features/auth/data/auth_session_data_source.dart";
import "features/auth/data/provider_token_free_local_storage.dart";
import "features/auth/presentation/auth_session_view_model.dart";
import "features/auth/presentation/gmail_connection_view_model.dart";
import "shared/theme/workspace_theme.dart";
import "shared/workspace_colors.dart";

ThemeData buildAppTheme(WorkspacePalette p) {
  final base = ThemeData(
    extensions: [p],
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      error: danger,
      surface: p.surface,
      onSurface: p.ink,
    ),
    scaffoldBackgroundColor: p.canvas,
    useMaterial3: true,
    // IBM Plex Sans KR for Hangul, Latin and numbers alike.
    fontFamily: GoogleFonts.ibmPlexSansKr().fontFamily,
  );
  return base.copyWith(
    textTheme: GoogleFonts.ibmPlexSansKrTextTheme(base.textTheme)
        .apply(bodyColor: p.ink, displayColor: p.ink),
    dividerColor: p.line,
    dividerTheme: DividerThemeData(color: p.line, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: p.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
      labelStyle: TextStyle(color: p.muted),
      hintStyle: TextStyle(color: p.muted),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: p.ink,
      unselectedLabelColor: p.muted,
      indicatorColor: p.accent,
      dividerColor: p.line,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: p.line),
      selectedColor: p.accent,
      backgroundColor: p.surface,
      labelStyle: TextStyle(color: p.ink),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.accent : p.line,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: p.deep,
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 13),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.deep,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 40),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.accentText,
        side: BorderSide(color: p.accentText),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 40),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.accentText),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.isConfigured) {
    runApp(MissingConfigApp(missingKeys: AppConfig.missingKeys));
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
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const MyApp(),
    ),
  );
}

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
    return MaterialApp.router(
      title: '견줘',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(ref.watch(activePaletteProvider)),
      routerConfig: appRouter,
    );
  }
}

/// Shown when the run settings are missing.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key, required this.missingKeys});

  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '견줘',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(WorkspacePalette.houseGreen),
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  '다음 값이 비어 있어요: ${missingKeys.join(", ")}',
                  style: const TextStyle(fontSize: 15, height: 1.7),
                ),
                const SizedBox(height: 16),
                const SelectableText(
                  'flutter run -d chrome --web-port 3000 '
                  '--dart-define-from-file=config/dart_defines.local.json',
                  style: TextStyle(fontSize: 14, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
