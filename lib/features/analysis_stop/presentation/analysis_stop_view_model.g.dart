// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_stop_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnalysisStopViewModel)
final analysisStopViewModelProvider = AnalysisStopViewModelFamily._();

final class AnalysisStopViewModelProvider
    extends $AsyncNotifierProvider<AnalysisStopViewModel, AnalysisStop> {
  AnalysisStopViewModelProvider._({
    required AnalysisStopViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'analysisStopViewModelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$analysisStopViewModelHash();

  @override
  String toString() {
    return r'analysisStopViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AnalysisStopViewModel create() => AnalysisStopViewModel();

  @override
  bool operator ==(Object other) {
    return other is AnalysisStopViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$analysisStopViewModelHash() =>
    r'c80caa95bd2bf55850d2f21686ecacfe05f16bc8';

final class AnalysisStopViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          AnalysisStopViewModel,
          AsyncValue<AnalysisStop>,
          AnalysisStop,
          FutureOr<AnalysisStop>,
          String
        > {
  AnalysisStopViewModelFamily._()
    : super(
        retry: _noRetry,
        name: r'analysisStopViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  AnalysisStopViewModelProvider call(String requestId) =>
      AnalysisStopViewModelProvider._(argument: requestId, from: this);

  @override
  String toString() => r'analysisStopViewModelProvider';
}

abstract class _$AnalysisStopViewModel extends $AsyncNotifier<AnalysisStop> {
  late final _$args = ref.$arg as String;
  String get requestId => _$args;

  FutureOr<AnalysisStop> build(String requestId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AnalysisStop>, AnalysisStop>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AnalysisStop>, AnalysisStop>,
              AsyncValue<AnalysisStop>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
