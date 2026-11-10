// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_status_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 작업 화면 상단 배너용 서버 준비 상태.
///
/// [pollInterval]마다 다시 읽어, 서버가 복구되면 배너가 저절로 사라집니다.
/// 작업 화면이 모두 닫히면(자동 해제) 묻지 않습니다.

@ProviderFor(ServerStatusViewModel)
final serverStatusViewModelProvider = ServerStatusViewModelProvider._();

/// 작업 화면 상단 배너용 서버 준비 상태.
///
/// [pollInterval]마다 다시 읽어, 서버가 복구되면 배너가 저절로 사라집니다.
/// 작업 화면이 모두 닫히면(자동 해제) 묻지 않습니다.
final class ServerStatusViewModelProvider
    extends $AsyncNotifierProvider<ServerStatusViewModel, ServerStatus> {
  /// 작업 화면 상단 배너용 서버 준비 상태.
  ///
  /// [pollInterval]마다 다시 읽어, 서버가 복구되면 배너가 저절로 사라집니다.
  /// 작업 화면이 모두 닫히면(자동 해제) 묻지 않습니다.
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

/// 작업 화면 상단 배너용 서버 준비 상태.
///
/// [pollInterval]마다 다시 읽어, 서버가 복구되면 배너가 저절로 사라집니다.
/// 작업 화면이 모두 닫히면(자동 해제) 묻지 않습니다.

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
