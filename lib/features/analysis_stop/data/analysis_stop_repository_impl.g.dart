// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_stop_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(analysisStopRepository)
final analysisStopRepositoryProvider = AnalysisStopRepositoryProvider._();

final class AnalysisStopRepositoryProvider
    extends
        $FunctionalProvider<
          AnalysisStopRepository,
          AnalysisStopRepository,
          AnalysisStopRepository
        >
    with $Provider<AnalysisStopRepository> {
  AnalysisStopRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisStopRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysisStopRepositoryHash();

  @$internal
  @override
  $ProviderElement<AnalysisStopRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnalysisStopRepository create(Ref ref) {
    return analysisStopRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalysisStopRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalysisStopRepository>(value),
    );
  }
}

String _$analysisStopRepositoryHash() =>
    r'2e6fa9b1af3e36a6e39be2e2c91e969ca76b94e4';
