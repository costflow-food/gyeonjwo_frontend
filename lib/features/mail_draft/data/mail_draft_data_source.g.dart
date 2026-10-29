// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_draft_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mailDraftDataSource)
final mailDraftDataSourceProvider = MailDraftDataSourceProvider._();

final class MailDraftDataSourceProvider
    extends
        $FunctionalProvider<
          MailDraftDataSource,
          MailDraftDataSource,
          MailDraftDataSource
        >
    with $Provider<MailDraftDataSource> {
  MailDraftDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mailDraftDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mailDraftDataSourceHash();

  @$internal
  @override
  $ProviderElement<MailDraftDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MailDraftDataSource create(Ref ref) {
    return mailDraftDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MailDraftDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MailDraftDataSource>(value),
    );
  }
}

String _$mailDraftDataSourceHash() =>
    r'8ec6c9545dfd8f8f094e6273d8bbfd1e7b85c669';
