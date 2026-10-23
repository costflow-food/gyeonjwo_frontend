// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_review_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PurchaseReviewViewModel)
final purchaseReviewViewModelProvider = PurchaseReviewViewModelFamily._();

final class PurchaseReviewViewModelProvider
    extends $AsyncNotifierProvider<PurchaseReviewViewModel, PurchaseReview> {
  PurchaseReviewViewModelProvider._({
    required PurchaseReviewViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'purchaseReviewViewModelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$purchaseReviewViewModelHash();

  @override
  String toString() {
    return r'purchaseReviewViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PurchaseReviewViewModel create() => PurchaseReviewViewModel();

  @override
  bool operator ==(Object other) {
    return other is PurchaseReviewViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$purchaseReviewViewModelHash() =>
    r'e6a6e6b25ec20312b0586cff1d3ed07e352c96ea';

final class PurchaseReviewViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          PurchaseReviewViewModel,
          AsyncValue<PurchaseReview>,
          PurchaseReview,
          FutureOr<PurchaseReview>,
          String
        > {
  PurchaseReviewViewModelFamily._()
    : super(
        retry: _noRetry,
        name: r'purchaseReviewViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  PurchaseReviewViewModelProvider call(String requestId) =>
      PurchaseReviewViewModelProvider._(argument: requestId, from: this);

  @override
  String toString() => r'purchaseReviewViewModelProvider';
}

abstract class _$PurchaseReviewViewModel
    extends $AsyncNotifier<PurchaseReview> {
  late final _$args = ref.$arg as String;
  String get requestId => _$args;

  FutureOr<PurchaseReview> build(String requestId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PurchaseReview>, PurchaseReview>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PurchaseReview>, PurchaseReview>,
              AsyncValue<PurchaseReview>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
