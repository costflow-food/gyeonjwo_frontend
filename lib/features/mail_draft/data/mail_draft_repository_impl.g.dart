// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_draft_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mailDraftRepository)
final mailDraftRepositoryProvider = MailDraftRepositoryProvider._();

final class MailDraftRepositoryProvider
    extends
        $FunctionalProvider<
          MailDraftRepository,
          MailDraftRepository,
          MailDraftRepository
        >
    with $Provider<MailDraftRepository> {
  MailDraftRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mailDraftRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mailDraftRepositoryHash();

  @$internal
  @override
  $ProviderElement<MailDraftRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MailDraftRepository create(Ref ref) {
    return mailDraftRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MailDraftRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MailDraftRepository>(value),
    );
  }
}

String _$mailDraftRepositoryHash() =>
    r'6cc3dce3da052892a85640ce231dd8d6ec161cb6';
