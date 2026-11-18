import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
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
import "shared/app_font_sizes.dart";
import "shared/lds_colors.dart";
import "shared/preferences.dart";
import "shared/widgets/app_scroll_behavior.dart";
import "shared/widgets/mobile_scaffold.dart";
import "shared/workspace_colors.dart";

/// 앱 전체 기본 모양 (`docs/design-ssot.md` 1·2장, 6.1 탭, 7.4 버튼, 8.1 모달).
/// 글꼴은 나눔고딕(400·700·800)이라 여기서는 w400/w700만 씁니다.
ThemeData buildAppTheme(WorkspacePalette p) {
  const buttonSize = Size(0, 36);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 12);
  const buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );
  const buttonLabel = TextStyle(
    fontSize: AppFontSizes.button,
    fontWeight: FontWeight.w700,
  );
  OutlineInputBorder field(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: BorderSide(color: color),
  );

  final base = ThemeData(
    extensions: [p],
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: Brightness.light,
      primary: p.accent,
      onPrimary: p.onAccent,
      error: danger,
      surface: p.surface,
      onSurface: p.ink,
    ),
    scaffoldBackgroundColor: p.canvas,
    useMaterial3: true,
    fontFamily: GoogleFonts.nanumGothic().fontFamily,
  );
  return base.copyWith(
    textTheme: GoogleFonts.nanumGothicTextTheme(
      base.textTheme,
    ).apply(bodyColor: p.ink, displayColor: p.ink),
    dividerColor: p.line,
    dividerTheme: DividerThemeData(color: p.line, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: TextStyle(
        fontSize: AppFontSizes.dialogTitle,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: p.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: field(LdsColors.borderStrong),
      enabledBorder: field(LdsColors.borderStrong),
      focusedBorder: field(LdsColors.title),
      errorBorder: field(danger),
      focusedErrorBorder: field(danger),
      labelStyle: const TextStyle(color: LdsColors.outline),
      hintStyle: const TextStyle(color: LdsColors.outline),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: p.ink,
      unselectedLabelColor: LdsColors.label,
      labelStyle: const TextStyle(
        fontSize: AppFontSizes.body,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: AppFontSizes.body,
        fontWeight: FontWeight.w700,
      ),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: p.ink, width: 2),
      ),
      dividerColor: p.line,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: p.line),
      selectedColor: p.blush,
      backgroundColor: p.surface,
      labelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected) ? p.accent : p.ink,
        ),
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: p.deep,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 13),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.deep,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: p.onAccent,
        disabledForegroundColor: LdsColors.disabled,
        elevation: 0,
        // 데스크톱 기본 밀도(compact)는 높이를 8 줄이므로 36을 고정합니다.
        visualDensity: VisualDensity.standard,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonLabel,
      ).copyWith(
        // hover는 겹침 색 대신 바탕을 #CC4D00으로 바꿉니다.
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? LdsColors.lineSoft
              : states.contains(WidgetState.hovered)
              ? LdsColors.primaryHover
              : p.accent,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.accentText,
        disabledForegroundColor: LdsColors.disabled,
        elevation: 0,
        // 데스크톱 기본 밀도(compact)는 높이를 8 줄이므로 36을 고정합니다.
        visualDensity: VisualDensity.standard,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonLabel,
      ).copyWith(
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled)
                ? LdsColors.line
                : LdsColors.borderStrong,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.hovered) &&
                  !states.contains(WidgetState.disabled)
              ? LdsColors.canvas
              : null,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LdsColors.title,
        disabledForegroundColor: LdsColors.disabled,
        elevation: 0,
        // 데스크톱 기본 밀도(compact)는 높이를 8 줄이므로 36을 고정합니다.
        visualDensity: VisualDensity.standard,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonLabel,
      ),
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
    ref.listen(authSessionViewModelProvider, (_, _) => appRouter.refresh());
    ref.listen(
      gmailConnectionViewModelProvider.select((value) => value.connectionPhase),
      (_, _) => appRouter.refresh(),
    );
    // Phones stay upright; the size is empty until the first frame is laid out.
    final screen = MediaQuery.maybeSizeOf(context);
    if (!kIsWeb && screen != null && !screen.isEmpty) {
      SystemChrome.setPreferredOrientations(allowedOrientations(screen));
    }
    return MaterialApp.router(
      title: 'Thoner',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(WorkspacePalette.lds),
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: appRouter,
    );
  }
}

class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key, required this.missingKeys});

  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Thoner',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(WorkspacePalette.lds),
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
                  '실행 설정이 필요합니다',
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
