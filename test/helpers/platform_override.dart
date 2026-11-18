import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart" as flutter_test;

/// `testWidgets` that clears [debugDefaultTargetPlatformOverride] when the
/// test body ends.
///
/// Tests here set the override (usually to Windows) inside the body. Flutter
/// 3.47 (the CI version) checks foundation debug variables right after the
/// body and before `addTearDown` callbacks run, so a reset in `addTearDown`
/// fails the test there. A variant's tearDown runs inside the body, in time on
/// every Flutter version.
void testWidgets(
  String description,
  flutter_test.WidgetTesterCallback callback, {
  bool? skip,
  flutter_test.Timeout? timeout,
  bool semanticsEnabled = true,
  dynamic tags,
}) => flutter_test.testWidgets(
  description,
  callback,
  skip: skip,
  timeout: timeout,
  semanticsEnabled: semanticsEnabled,
  tags: tags,
  variant: const _ResetPlatformOverride(),
);

class _ResetPlatformOverride extends flutter_test.TestVariant<Object?> {
  const _ResetPlatformOverride();

  @override
  Iterable<Object?> get values => const [null];

  @override
  String describeValue(Object? value) => "platform reset";

  @override
  Future<Object?> setUp(Object? value) async => null;

  @override
  Future<void> tearDown(Object? value, Object? memento) async {
    debugDefaultTargetPlatformOverride = null;
  }
}
