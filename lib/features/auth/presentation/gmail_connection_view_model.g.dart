// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gmail_connection_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Server-confirmed Gmail connection for the signed-in user.
///
/// Right after the OAuth redirect it sends the Google tokens once and waits
/// for the server result. Otherwise it reads the connection the server keeps.

@ProviderFor(GmailConnectionViewModel)
final gmailConnectionViewModelProvider = GmailConnectionViewModelProvider._();

/// Server-confirmed Gmail connection for the signed-in user.
///
/// Right after the OAuth redirect it sends the Google tokens once and waits
/// for the server result. Otherwise it reads the connection the server keeps.
final class GmailConnectionViewModelProvider
    extends $AsyncNotifierProvider<GmailConnectionViewModel, GmailConnection> {
  /// Server-confirmed Gmail connection for the signed-in user.
  ///
  /// Right after the OAuth redirect it sends the Google tokens once and waits
  /// for the server result. Otherwise it reads the connection the server keeps.
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
    r'ef96882e1dd452c38134034b1fc6c168749159be';

/// Server-confirmed Gmail connection for the signed-in user.
///
/// Right after the OAuth redirect it sends the Google tokens once and waits
/// for the server result. Otherwise it reads the connection the server keeps.

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

/// Mail features the UI may enable. Disabling here is a convenience only;
/// the server rejects requests without the matching Google permission.

@ProviderFor(gmailCapabilities)
final gmailCapabilitiesProvider = GmailCapabilitiesProvider._();

/// Mail features the UI may enable. Disabling here is a convenience only;
/// the server rejects requests without the matching Google permission.

final class GmailCapabilitiesProvider
    extends
        $FunctionalProvider<
          GmailCapabilities,
          GmailCapabilities,
          GmailCapabilities
        >
    with $Provider<GmailCapabilities> {
  /// Mail features the UI may enable. Disabling here is a convenience only;
  /// the server rejects requests without the matching Google permission.
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

String _$gmailCapabilitiesHash() => r'c7bb62c982e181844b0349a23c85473ed58b171d';
