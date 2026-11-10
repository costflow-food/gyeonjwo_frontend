// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_review_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

@ProviderFor(purchaseReviewDataSource)
final purchaseReviewDataSourceProvider = PurchaseReviewDataSourceProvider._();

/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

final class PurchaseReviewDataSourceProvider
    extends
        $FunctionalProvider<
          PurchaseReviewDataSource,
          PurchaseReviewDataSource,
          PurchaseReviewDataSource
        >
    with $Provider<PurchaseReviewDataSource> {
  /// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
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
    r'a877de7e7f46da07fa8bd20cf653cd3eb2c9a1f6';
