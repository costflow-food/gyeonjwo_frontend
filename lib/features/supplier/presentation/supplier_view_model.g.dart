// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SCR-011 list, search, selection, and registration.

@ProviderFor(SupplierListViewModel)
final supplierListViewModelProvider = SupplierListViewModelProvider._();

/// SCR-011 list, search, selection, and registration.
final class SupplierListViewModelProvider
    extends $AsyncNotifierProvider<SupplierListViewModel, SupplierListState> {
  /// SCR-011 list, search, selection, and registration.
  SupplierListViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'supplierListViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supplierListViewModelHash();

  @$internal
  @override
  SupplierListViewModel create() => SupplierListViewModel();
}

String _$supplierListViewModelHash() =>
    r'd2f277c6c0902032e39942888cc5ba8148062cc2';

/// SCR-011 list, search, selection, and registration.

abstract class _$SupplierListViewModel
    extends $AsyncNotifier<SupplierListState> {
  FutureOr<SupplierListState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SupplierListState>, SupplierListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SupplierListState>, SupplierListState>,
              AsyncValue<SupplierListState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// API-30 detail, kept per supplier.

@ProviderFor(SupplierDetailViewModel)
final supplierDetailViewModelProvider = SupplierDetailViewModelFamily._();

/// API-30 detail, kept per supplier.
final class SupplierDetailViewModelProvider
    extends $AsyncNotifierProvider<SupplierDetailViewModel, SupplierDetail> {
  /// API-30 detail, kept per supplier.
  SupplierDetailViewModelProvider._({
    required SupplierDetailViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'supplierDetailViewModelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$supplierDetailViewModelHash();

  @override
  String toString() {
    return r'supplierDetailViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SupplierDetailViewModel create() => SupplierDetailViewModel();

  @override
  bool operator ==(Object other) {
    return other is SupplierDetailViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$supplierDetailViewModelHash() =>
    r'94f2d27f8963df582e8a59d7cc35bea386c30e52';

/// API-30 detail, kept per supplier.

final class SupplierDetailViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          SupplierDetailViewModel,
          AsyncValue<SupplierDetail>,
          SupplierDetail,
          FutureOr<SupplierDetail>,
          String
        > {
  SupplierDetailViewModelFamily._()
    : super(
        retry: _noRetry,
        name: r'supplierDetailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// API-30 detail, kept per supplier.

  SupplierDetailViewModelProvider call(String supplierId) =>
      SupplierDetailViewModelProvider._(argument: supplierId, from: this);

  @override
  String toString() => r'supplierDetailViewModelProvider';
}

/// API-30 detail, kept per supplier.

abstract class _$SupplierDetailViewModel
    extends $AsyncNotifier<SupplierDetail> {
  late final _$args = ref.$arg as String;
  String get supplierId => _$args;

  FutureOr<SupplierDetail> build(String supplierId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SupplierDetail>, SupplierDetail>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SupplierDetail>, SupplierDetail>,
              AsyncValue<SupplierDetail>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// API-31 price history per supplier item, shown in SCR-005.

@ProviderFor(SupplierPriceHistoryViewModel)
final supplierPriceHistoryViewModelProvider =
    SupplierPriceHistoryViewModelFamily._();

/// API-31 price history per supplier item, shown in SCR-005.
final class SupplierPriceHistoryViewModelProvider
    extends
        $AsyncNotifierProvider<SupplierPriceHistoryViewModel, PriceHistory> {
  /// API-31 price history per supplier item, shown in SCR-005.
  SupplierPriceHistoryViewModelProvider._({
    required SupplierPriceHistoryViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'supplierPriceHistoryViewModelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$supplierPriceHistoryViewModelHash();

  @override
  String toString() {
    return r'supplierPriceHistoryViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SupplierPriceHistoryViewModel create() => SupplierPriceHistoryViewModel();

  @override
  bool operator ==(Object other) {
    return other is SupplierPriceHistoryViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$supplierPriceHistoryViewModelHash() =>
    r'e4cec4134aa53fd75bfadaf01486ef3fd9513dee';

/// API-31 price history per supplier item, shown in SCR-005.

final class SupplierPriceHistoryViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          SupplierPriceHistoryViewModel,
          AsyncValue<PriceHistory>,
          PriceHistory,
          FutureOr<PriceHistory>,
          String
        > {
  SupplierPriceHistoryViewModelFamily._()
    : super(
        retry: _noRetry,
        name: r'supplierPriceHistoryViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// API-31 price history per supplier item, shown in SCR-005.

  SupplierPriceHistoryViewModelProvider call(String supplierItemId) =>
      SupplierPriceHistoryViewModelProvider._(
        argument: supplierItemId,
        from: this,
      );

  @override
  String toString() => r'supplierPriceHistoryViewModelProvider';
}

/// API-31 price history per supplier item, shown in SCR-005.

abstract class _$SupplierPriceHistoryViewModel
    extends $AsyncNotifier<PriceHistory> {
  late final _$args = ref.$arg as String;
  String get supplierItemId => _$args;

  FutureOr<PriceHistory> build(String supplierItemId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PriceHistory>, PriceHistory>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PriceHistory>, PriceHistory>,
              AsyncValue<PriceHistory>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
