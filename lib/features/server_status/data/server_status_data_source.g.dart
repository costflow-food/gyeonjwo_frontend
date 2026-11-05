// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_status_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(serverStatusDataSource)
final serverStatusDataSourceProvider = ServerStatusDataSourceProvider._();

final class ServerStatusDataSourceProvider
    extends
        $FunctionalProvider<
          ServerStatusDataSource,
          ServerStatusDataSource,
          ServerStatusDataSource
        >
    with $Provider<ServerStatusDataSource> {
  ServerStatusDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverStatusDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverStatusDataSourceHash();

  @$internal
  @override
  $ProviderElement<ServerStatusDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ServerStatusDataSource create(Ref ref) {
    return serverStatusDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerStatusDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerStatusDataSource>(value),
    );
  }
}

String _$serverStatusDataSourceHash() =>
    r'6621f16c57ad2a9a509f37a422472cd1eec99107';
