// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gmail_connection_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GmailConnectionViewModel)
final gmailConnectionViewModelProvider = GmailConnectionViewModelProvider._();

final class GmailConnectionViewModelProvider
    extends $AsyncNotifierProvider<GmailConnectionViewModel, GmailConnection> {
  GmailConnectionViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'gmailConnectionViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gmailConnectionViewModelHash();

  @$internal
  @override
  GmailConnectionViewModel create() => GmailConnectionViewModel();
}

String _$gmailConnectionViewModelHash() =>
    r'c737f1de843805b2fc0d1d5676e6016f1211e571';

abstract class _$GmailConnectionViewModel
    extends $AsyncNotifier<GmailConnection> {
  FutureOr<GmailConnection> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GmailConnection>, GmailConnection>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GmailConnection>, GmailConnection>,
              AsyncValue<GmailConnection>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(gmailCapabilities)
final gmailCapabilitiesProvider = GmailCapabilitiesProvider._();

final class GmailCapabilitiesProvider
    extends
        $FunctionalProvider<
          GmailCapabilities,
          GmailCapabilities,
          GmailCapabilities
        >
    with $Provider<GmailCapabilities> {
  GmailCapabilitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gmailCapabilitiesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gmailCapabilitiesHash();

  @$internal
  @override
  $ProviderElement<GmailCapabilities> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GmailCapabilities create(Ref ref) {
    return gmailCapabilities(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GmailCapabilities value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GmailCapabilities>(value),
    );
  }
}

String _$gmailCapabilitiesHash() => r'57ade2e63b5ad8177292d939d58f48e566f1558d';
