import "package:flutter/widgets.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "app_visibility.g.dart";

/// Whether the app can be seen. On the web a hidden browser tab reports
/// [AppLifecycleState.hidden]; a blurred but visible window stays visible.
/// Polls wait while this is false and catch up when it turns true.
@Riverpod(keepAlive: true)
class AppVisible extends _$AppVisible {
  @override
  bool build() {
    final listener = AppLifecycleListener(
      onStateChange: (lifecycle) => state = _visible(lifecycle),
    );
    ref.onDispose(listener.dispose);
    return _visible(WidgetsBinding.instance.lifecycleState);
  }

  static bool _visible(AppLifecycleState? lifecycle) => switch (lifecycle) {
    AppLifecycleState.hidden ||
    AppLifecycleState.paused ||
    AppLifecycleState.detached => false,
    _ => true,
  };
}
