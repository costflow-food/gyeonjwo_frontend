// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mailbox_sync_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mailboxSyncDataSource)
final mailboxSyncDataSourceProvider = MailboxSyncDataSourceProvider._();

final class MailboxSyncDataSourceProvider
    extends
        $FunctionalProvider<
          MailboxSyncDataSource,
          MailboxSyncDataSource,
          MailboxSyncDataSource
        >
    with $Provider<MailboxSyncDataSource> {
  MailboxSyncDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mailboxSyncDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mailboxSyncDataSourceHash();

  @$internal
  @override
  $ProviderElement<MailboxSyncDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MailboxSyncDataSource create(Ref ref) {
    return mailboxSyncDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MailboxSyncDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MailboxSyncDataSource>(value),
    );
  }
}

String _$mailboxSyncDataSourceHash() =>
    r'259d0ce8305bdaaa2b9b77748c9e933391d62171';
