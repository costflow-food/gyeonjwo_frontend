// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_evidence_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supplierEvidenceDataSource)
final supplierEvidenceDataSourceProvider =
    SupplierEvidenceDataSourceProvider._();

final class SupplierEvidenceDataSourceProvider
    extends
        $FunctionalProvider<
          SupplierEvidenceDataSource,
          SupplierEvidenceDataSource,
          SupplierEvidenceDataSource
        >
    with $Provider<SupplierEvidenceDataSource> {
  SupplierEvidenceDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supplierEvidenceDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supplierEvidenceDataSourceHash();

  @$internal
  @override
  $ProviderElement<SupplierEvidenceDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupplierEvidenceDataSource create(Ref ref) {
    return supplierEvidenceDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupplierEvidenceDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupplierEvidenceDataSource>(value),
    );
  }
}

String _$supplierEvidenceDataSourceHash() =>
    r'97bd71c9c7d413c58affbabb0ad274879227c665';
