// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_stop_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(analysisStopDataSource)
final analysisStopDataSourceProvider = AnalysisStopDataSourceProvider._();

final class AnalysisStopDataSourceProvider
    extends
        $FunctionalProvider<
          AnalysisStopDataSource,
          AnalysisStopDataSource,
          AnalysisStopDataSource
        >
    with $Provider<AnalysisStopDataSource> {
  AnalysisStopDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisStopDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysisStopDataSourceHash();

  @$internal
  @override
  $ProviderElement<AnalysisStopDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnalysisStopDataSource create(Ref ref) {
    return analysisStopDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalysisStopDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalysisStopDataSource>(value),
    );
  }
}

String _$analysisStopDataSourceHash() =>
    r'd3760be6333c17d9bfc50942726311f3438cddd7';
