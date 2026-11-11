// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_visibility.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the app can be seen. On the web a hidden browser tab reports
/// [AppLifecycleState.hidden]; a blurred but visible window stays visible.
/// Polls wait while this is false and catch up when it turns true.

@ProviderFor(AppVisible)
final appVisibleProvider = AppVisibleProvider._();

/// Whether the app can be seen. On the web a hidden browser tab reports
/// [AppLifecycleState.hidden]; a blurred but visible window stays visible.
/// Polls wait while this is false and catch up when it turns true.
final class AppVisibleProvider extends $NotifierProvider<AppVisible, bool> {
  /// Whether the app can be seen. On the web a hidden browser tab reports
  /// [AppLifecycleState.hidden]; a blurred but visible window stays visible.
  /// Polls wait while this is false and catch up when it turns true.
  AppVisibleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVisibleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVisibleHash();

  @$internal
  @override
  AppVisible create() => AppVisible();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appVisibleHash() => r'1a44180b31c01f89fa522856dd4fad47a634d1c4';

/// Whether the app can be seen. On the web a hidden browser tab reports
/// [AppLifecycleState.hidden]; a blurred but visible window stays visible.
/// Polls wait while this is false and catch up when it turns true.

abstract class _$AppVisible extends $Notifier<bool> {
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
