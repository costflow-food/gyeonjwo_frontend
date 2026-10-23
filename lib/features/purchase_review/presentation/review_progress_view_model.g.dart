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
    extends $NotifierProvider<ReviewProgressViewModel, ReviewProgressState> {
  ReviewProgressViewModelProvider._({
    required ReviewProgressViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReviewProgressState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReviewProgressState>(value),
    );
  }

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
    r'9dc1be191d4b567b3befdd43e95cb956ed7a0417';

final class ReviewProgressViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          ReviewProgressViewModel,
          ReviewProgressState,
          ReviewProgressState,
          ReviewProgressState,
          String
        > {
  ReviewProgressViewModelFamily._()
    : super(
        retry: null,
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

abstract class _$ReviewProgressViewModel
    extends $Notifier<ReviewProgressState> {
  late final _$args = ref.$arg as String;
  String get requestId => _$args;

  ReviewProgressState build(String requestId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReviewProgressState, ReviewProgressState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReviewProgressState, ReviewProgressState>,
              ReviewProgressState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
