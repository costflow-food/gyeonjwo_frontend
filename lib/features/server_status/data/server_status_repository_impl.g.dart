// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_status_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(serverStatusRepository)
final serverStatusRepositoryProvider = ServerStatusRepositoryProvider._();

final class ServerStatusRepositoryProvider
    extends
        $FunctionalProvider<
          ServerStatusRepository,
          ServerStatusRepository,
          ServerStatusRepository
        >
    with $Provider<ServerStatusRepository> {
  ServerStatusRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverStatusRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverStatusRepositoryHash();

  @$internal
  @override
  $ProviderElement<ServerStatusRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ServerStatusRepository create(Ref ref) {
    return serverStatusRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerStatusRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerStatusRepository>(value),
    );
  }
}

String _$serverStatusRepositoryHash() =>
    r'dc0a941cf42676ffca4cdf186fa012026410a578';
