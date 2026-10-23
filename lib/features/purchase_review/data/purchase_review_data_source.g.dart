// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_review_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(purchaseReviewDataSource)
final purchaseReviewDataSourceProvider = PurchaseReviewDataSourceProvider._();

final class PurchaseReviewDataSourceProvider
    extends
        $FunctionalProvider<
          PurchaseReviewDataSource,
          PurchaseReviewDataSource,
          PurchaseReviewDataSource
        >
    with $Provider<PurchaseReviewDataSource> {
  PurchaseReviewDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchaseReviewDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchaseReviewDataSourceHash();

  @$internal
  @override
  $ProviderElement<PurchaseReviewDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PurchaseReviewDataSource create(Ref ref) {
    return purchaseReviewDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurchaseReviewDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurchaseReviewDataSource>(value),
    );
  }
}

String _$purchaseReviewDataSourceHash() =>
    r'6b53544f80004437a13a631b88942f9049687798';
