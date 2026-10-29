// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_intake_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mailIntakeRepository)
final mailIntakeRepositoryProvider = MailIntakeRepositoryProvider._();

final class MailIntakeRepositoryProvider
    extends
        $FunctionalProvider<
          MailIntakeRepository,
          MailIntakeRepository,
          MailIntakeRepository
        >
    with $Provider<MailIntakeRepository> {
  MailIntakeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mailIntakeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mailIntakeRepositoryHash();

  @$internal
  @override
  $ProviderElement<MailIntakeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MailIntakeRepository create(Ref ref) {
    return mailIntakeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MailIntakeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MailIntakeRepository>(value),
    );
  }
}

String _$mailIntakeRepositoryHash() =>
    r'49c038af6d47980212daaf0bc1ec85878cdb99db';
