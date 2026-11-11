// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mailbox_sync_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 설정 > 권한 화면의 메일 수신 상태. 화면이 열려 있는 동안 [pollInterval]마다
/// 다시 읽습니다. 확인하지 못하면 null입니다.

@ProviderFor(MailboxSyncViewModel)
final mailboxSyncViewModelProvider = MailboxSyncViewModelProvider._();

/// 설정 > 권한 화면의 메일 수신 상태. 화면이 열려 있는 동안 [pollInterval]마다
/// 다시 읽습니다. 확인하지 못하면 null입니다.
final class MailboxSyncViewModelProvider
    extends $AsyncNotifierProvider<MailboxSyncViewModel, MailboxSyncStatus?> {
  /// 설정 > 권한 화면의 메일 수신 상태. 화면이 열려 있는 동안 [pollInterval]마다
  /// 다시 읽습니다. 확인하지 못하면 null입니다.
  MailboxSyncViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'mailboxSyncViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mailboxSyncViewModelHash();

  @$internal
  @override
  MailboxSyncViewModel create() => MailboxSyncViewModel();
}

String _$mailboxSyncViewModelHash() =>
    r'4ed0ffbfa6142afb4117f51e2d44706fee7b0919';

/// 설정 > 권한 화면의 메일 수신 상태. 화면이 열려 있는 동안 [pollInterval]마다
/// 다시 읽습니다. 확인하지 못하면 null입니다.

abstract class _$MailboxSyncViewModel
    extends $AsyncNotifier<MailboxSyncStatus?> {
  FutureOr<MailboxSyncStatus?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<MailboxSyncStatus?>, MailboxSyncStatus?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MailboxSyncStatus?>, MailboxSyncStatus?>,
              AsyncValue<MailboxSyncStatus?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
