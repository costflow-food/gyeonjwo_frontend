// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_evidence_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SupplierEvidenceViewModel)
final supplierEvidenceViewModelProvider = SupplierEvidenceViewModelFamily._();

final class SupplierEvidenceViewModelProvider
    extends
        $AsyncNotifierProvider<SupplierEvidenceViewModel, SupplierEvidence> {
  SupplierEvidenceViewModelProvider._({
    required SupplierEvidenceViewModelFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: _noRetry,
         name: r'supplierEvidenceViewModelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$supplierEvidenceViewModelHash();

  @override
  String toString() {
    return r'supplierEvidenceViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SupplierEvidenceViewModel create() => SupplierEvidenceViewModel();

  @override
  bool operator ==(Object other) {
    return other is SupplierEvidenceViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$supplierEvidenceViewModelHash() =>
    r'2adbfda9980c76562d566834d64d407dd9a8e44a';

final class SupplierEvidenceViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          SupplierEvidenceViewModel,
          AsyncValue<SupplierEvidence>,
          SupplierEvidence,
          FutureOr<SupplierEvidence>,
          (String, String)
        > {
  SupplierEvidenceViewModelFamily._()
    : super(
        retry: _noRetry,
        name: r'supplierEvidenceViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  SupplierEvidenceViewModelProvider call(
    String requestId,
    String supplierLetter,
  ) => SupplierEvidenceViewModelProvider._(
    argument: (requestId, supplierLetter),
    from: this,
  );

  @override
  String toString() => r'supplierEvidenceViewModelProvider';
}

abstract class _$SupplierEvidenceViewModel
    extends $AsyncNotifier<SupplierEvidence> {
  late final _$args = ref.$arg as (String, String);
  String get requestId => _$args.$1;
  String get supplierLetter => _$args.$2;

  FutureOr<SupplierEvidence> build(String requestId, String supplierLetter);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SupplierEvidence>, SupplierEvidence>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SupplierEvidence>, SupplierEvidence>,
              AsyncValue<SupplierEvidence>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
