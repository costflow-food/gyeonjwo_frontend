// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authSessionDataSource)
final authSessionDataSourceProvider = AuthSessionDataSourceProvider._();

final class AuthSessionDataSourceProvider
    extends
        $FunctionalProvider<
          AuthSessionDataSource,
          AuthSessionDataSource,
          AuthSessionDataSource
        >
    with $Provider<AuthSessionDataSource> {
  AuthSessionDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authSessionDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSessionDataSourceHash();

  @$internal
  @override
  $ProviderElement<AuthSessionDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthSessionDataSource create(Ref ref) {
    return authSessionDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthSessionDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthSessionDataSource>(value),
    );
  }
}

String _$authSessionDataSourceHash() =>
    r'5376534a9823f99f0aa2ab3bd0f4fd2eba818f3c';
