// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_case_change_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workCaseChangeSource)
final workCaseChangeSourceProvider = WorkCaseChangeSourceProvider._();

final class WorkCaseChangeSourceProvider
    extends
        $FunctionalProvider<
          WorkCaseChangeSource,
          WorkCaseChangeSource,
          WorkCaseChangeSource
        >
    with $Provider<WorkCaseChangeSource> {
  WorkCaseChangeSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workCaseChangeSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workCaseChangeSourceHash();

  @$internal
  @override
  $ProviderElement<WorkCaseChangeSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkCaseChangeSource create(Ref ref) {
    return workCaseChangeSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkCaseChangeSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkCaseChangeSource>(value),
    );
  }
}

String _$workCaseChangeSourceHash() =>
    r'6ade906adf8d301c8cfdd7158b0b4ece782e3539';
