// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_evidence_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supplierEvidenceRepository)
final supplierEvidenceRepositoryProvider =
    SupplierEvidenceRepositoryProvider._();

final class SupplierEvidenceRepositoryProvider
    extends
        $FunctionalProvider<
          SupplierEvidenceRepository,
          SupplierEvidenceRepository,
          SupplierEvidenceRepository
        >
    with $Provider<SupplierEvidenceRepository> {
  SupplierEvidenceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supplierEvidenceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supplierEvidenceRepositoryHash();

  @$internal
  @override
  $ProviderElement<SupplierEvidenceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupplierEvidenceRepository create(Ref ref) {
    return supplierEvidenceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupplierEvidenceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupplierEvidenceRepository>(value),
    );
  }
}

String _$supplierEvidenceRepositoryHash() =>
    r'e4a2d227e2c9a694a654e766b50671ebe098d8f8';
