// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_review_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(purchaseReviewRepository)
final purchaseReviewRepositoryProvider = PurchaseReviewRepositoryProvider._();

final class PurchaseReviewRepositoryProvider
    extends
        $FunctionalProvider<
          PurchaseReviewRepository,
          PurchaseReviewRepository,
          PurchaseReviewRepository
        >
    with $Provider<PurchaseReviewRepository> {
  PurchaseReviewRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchaseReviewRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchaseReviewRepositoryHash();

  @$internal
  @override
  $ProviderElement<PurchaseReviewRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PurchaseReviewRepository create(Ref ref) {
    return purchaseReviewRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurchaseReviewRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurchaseReviewRepository>(value),
    );
  }
}

String _$purchaseReviewRepositoryHash() =>
    r'841e2a6e1d1262feca04f0472e42c10331f206a5';
