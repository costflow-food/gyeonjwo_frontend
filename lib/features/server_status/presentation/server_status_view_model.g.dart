// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_status_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ServerStatusViewModel)
final serverStatusViewModelProvider = ServerStatusViewModelProvider._();

final class ServerStatusViewModelProvider
    extends $AsyncNotifierProvider<ServerStatusViewModel, ServerStatus> {
  ServerStatusViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'serverStatusViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverStatusViewModelHash();

  @$internal
  @override
  ServerStatusViewModel create() => ServerStatusViewModel();
}

String _$serverStatusViewModelHash() =>
    r'f40852ec0c25f11084054accdadbdf67f9559d20';

abstract class _$ServerStatusViewModel extends $AsyncNotifier<ServerStatus> {
  FutureOr<ServerStatus> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ServerStatus>, ServerStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ServerStatus>, ServerStatus>,
              AsyncValue<ServerStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
