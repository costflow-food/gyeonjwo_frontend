// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mailbox_sync_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 작업 화면 상단 수신 상태. [pollInterval]마다 다시 읽어, 수신이 되살아나면
/// 안내가 저절로 사라집니다. 확인하지 못하면 null로 두고 안내하지 않습니다.

@ProviderFor(MailboxSyncViewModel)
final mailboxSyncViewModelProvider = MailboxSyncViewModelProvider._();

/// 작업 화면 상단 수신 상태. [pollInterval]마다 다시 읽어, 수신이 되살아나면
/// 안내가 저절로 사라집니다. 확인하지 못하면 null로 두고 안내하지 않습니다.
final class MailboxSyncViewModelProvider
    extends $AsyncNotifierProvider<MailboxSyncViewModel, MailboxSyncStatus?> {
  /// 작업 화면 상단 수신 상태. [pollInterval]마다 다시 읽어, 수신이 되살아나면
  /// 안내가 저절로 사라집니다. 확인하지 못하면 null로 두고 안내하지 않습니다.
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

/// 작업 화면 상단 수신 상태. [pollInterval]마다 다시 읽어, 수신이 되살아나면
/// 안내가 저절로 사라집니다. 확인하지 못하면 null로 두고 안내하지 않습니다.

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
