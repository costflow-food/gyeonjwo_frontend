// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_progress_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReviewProgressViewModel)
final reviewProgressViewModelProvider = ReviewProgressViewModelFamily._();

final class ReviewProgressViewModelProvider
    extends $AsyncNotifierProvider<ReviewProgressViewModel, ReviewPhase> {
  ReviewProgressViewModelProvider._({
    required ReviewProgressViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'reviewProgressViewModelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reviewProgressViewModelHash();

  @override
  String toString() {
    return r'reviewProgressViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ReviewProgressViewModel create() => ReviewProgressViewModel();

  @override
  bool operator ==(Object other) {
    return other is ReviewProgressViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reviewProgressViewModelHash() =>
    r'f59b3a30c1c960911725633a0e595b66cd80b643';

final class ReviewProgressViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          ReviewProgressViewModel,
          AsyncValue<ReviewPhase>,
          ReviewPhase,
          FutureOr<ReviewPhase>,
          String
        > {
  ReviewProgressViewModelFamily._()
    : super(
        retry: _noRetry,
        name: r'reviewProgressViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ReviewProgressViewModelProvider call(String requestId) =>
      ReviewProgressViewModelProvider._(argument: requestId, from: this);

  @override
  String toString() => r'reviewProgressViewModelProvider';
}

abstract class _$ReviewProgressViewModel extends $AsyncNotifier<ReviewPhase> {
  late final _$args = ref.$arg as String;
  String get requestId => _$args;

  FutureOr<ReviewPhase> build(String requestId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ReviewPhase>, ReviewPhase>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ReviewPhase>, ReviewPhase>,
              AsyncValue<ReviewPhase>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
