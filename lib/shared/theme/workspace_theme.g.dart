// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_theme.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱 시작 때 읽어 둔 브라우저 저장소. `main`에서 값을 넣습니다.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// 앱 시작 때 읽어 둔 브라우저 저장소. `main`에서 값을 넣습니다.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  /// 앱 시작 때 읽어 둔 브라우저 저장소. `main`에서 값을 넣습니다.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'f1eabb3e511eb112f152dcf158c505517af186ac';

/// 고른 화면 테마. 이 브라우저에 저장해 새로고침해도 유지됩니다.

@ProviderFor(WorkspaceTheme)
final workspaceThemeProvider = WorkspaceThemeProvider._();

/// 고른 화면 테마. 이 브라우저에 저장해 새로고침해도 유지됩니다.
final class WorkspaceThemeProvider
    extends $NotifierProvider<WorkspaceTheme, WorkspacePalette> {
  /// 고른 화면 테마. 이 브라우저에 저장해 새로고침해도 유지됩니다.
  WorkspaceThemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceThemeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceThemeHash();

  @$internal
  @override
  WorkspaceTheme create() => WorkspaceTheme();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspacePalette value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspacePalette>(value),
    );
  }
}

String _$workspaceThemeHash() => r'd47655d6fb721e70d16e21dc650b31784fb92507';

/// 고른 화면 테마. 이 브라우저에 저장해 새로고침해도 유지됩니다.

abstract class _$WorkspaceTheme extends $Notifier<WorkspacePalette> {
  WorkspacePalette build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WorkspacePalette, WorkspacePalette>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkspacePalette, WorkspacePalette>,
              WorkspacePalette,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 라이트/다크 모드. 테마와 따로 이 브라우저에 저장합니다.

@ProviderFor(WorkspaceDarkMode)
final workspaceDarkModeProvider = WorkspaceDarkModeProvider._();

/// 라이트/다크 모드. 테마와 따로 이 브라우저에 저장합니다.
final class WorkspaceDarkModeProvider
    extends $NotifierProvider<WorkspaceDarkMode, bool> {
  /// 라이트/다크 모드. 테마와 따로 이 브라우저에 저장합니다.
  WorkspaceDarkModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceDarkModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceDarkModeHash();

  @$internal
  @override
  WorkspaceDarkMode create() => WorkspaceDarkMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$workspaceDarkModeHash() => r'3faf6f5a3f717bc251875405c5a0cef88bd94ea4';

/// 라이트/다크 모드. 테마와 따로 이 브라우저에 저장합니다.

abstract class _$WorkspaceDarkMode extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 화면에 실제로 쓰는 팔레트: 고른 테마에 라이트/다크를 적용합니다.

@ProviderFor(activePalette)
final activePaletteProvider = ActivePaletteProvider._();

/// 화면에 실제로 쓰는 팔레트: 고른 테마에 라이트/다크를 적용합니다.

final class ActivePaletteProvider
    extends
        $FunctionalProvider<
          WorkspacePalette,
          WorkspacePalette,
          WorkspacePalette
        >
    with $Provider<WorkspacePalette> {
  /// 화면에 실제로 쓰는 팔레트: 고른 테마에 라이트/다크를 적용합니다.
  ActivePaletteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activePaletteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activePaletteHash();

  @$internal
  @override
  $ProviderElement<WorkspacePalette> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WorkspacePalette create(Ref ref) {
    return activePalette(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspacePalette value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspacePalette>(value),
    );
  }
}

String _$activePaletteHash() => r'f14adfcf2645db484c2c2cc5865f944d3f8db47c';
