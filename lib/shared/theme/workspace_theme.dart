import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../workspace_colors.dart";

part "workspace_theme.g.dart";

/// 앱 시작 때 읽어 둔 브라우저 저장소. `main`에서 값을 넣습니다.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError("main에서 SharedPreferences를 넣어 주세요.");

/// 고른 화면 테마. 이 브라우저에 저장해 새로고침해도 유지됩니다.
@Riverpod(keepAlive: true)
class WorkspaceTheme extends _$WorkspaceTheme {
  static const _key = "workspace_theme";

  @override
  WorkspacePalette build() => WorkspacePalette.byId(
    ref.watch(sharedPreferencesProvider).getString(_key),
  );

  void select(WorkspacePalette palette) {
    state = palette;
    ref.read(sharedPreferencesProvider).setString(_key, palette.id);
  }
}

/// 라이트/다크 모드. 테마와 따로 이 브라우저에 저장합니다.
@Riverpod(keepAlive: true)
class WorkspaceDarkMode extends _$WorkspaceDarkMode {
  static const _key = "workspace_dark_mode";

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  void set(bool dark) {
    state = dark;
    ref.read(sharedPreferencesProvider).setBool(_key, dark);
  }
}

@Riverpod(keepAlive: true)
WorkspacePalette activePalette(Ref ref) {
  final palette = ref.watch(workspaceThemeProvider);
  return ref.watch(workspaceDarkModeProvider) ? palette.toDark() : palette;
}
