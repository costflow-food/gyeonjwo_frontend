// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

@ProviderFor(supplierDataSource)
final supplierDataSourceProvider = SupplierDataSourceProvider._();

/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

final class SupplierDataSourceProvider
    extends
        $FunctionalProvider<
          SupplierDataSource,
          SupplierDataSource,
          SupplierDataSource
        >
    with $Provider<SupplierDataSource> {
  /// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
  SupplierDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supplierDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supplierDataSourceHash();

  @$internal
  @override
  $ProviderElement<SupplierDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupplierDataSource create(Ref ref) {
    return supplierDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupplierDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupplierDataSource>(value),
    );
  }
}

String _$supplierDataSourceHash() =>
    r'3cfa3c541a9e76d0785944c92304c06f0050d1c9';
