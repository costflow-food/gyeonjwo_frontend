// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared HTTP client for the 견줘 API.
///
/// No logging interceptor is attached: request bodies can carry OAuth tokens.

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// Shared HTTP client for the 견줘 API.
///
/// No logging interceptor is attached: request bodies can carry OAuth tokens.

final class ApiClientProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Shared HTTP client for the 견줘 API.
  ///
  /// No logging interceptor is attached: request bodies can carry OAuth tokens.
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$apiClientHash() => r'd0384f1bdf53e67a0c8bc705c5619fa1e2ec85d9';
