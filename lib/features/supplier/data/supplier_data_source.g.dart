// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supplierDataSource)
final supplierDataSourceProvider = SupplierDataSourceProvider._();

final class SupplierDataSourceProvider
    extends
        $FunctionalProvider<
          SupplierDataSource,
          SupplierDataSource,
          SupplierDataSource
        >
    with $Provider<SupplierDataSource> {
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
    r'4273a57f6040c4a3127b399e8cd1047fe9eb7ceb';
