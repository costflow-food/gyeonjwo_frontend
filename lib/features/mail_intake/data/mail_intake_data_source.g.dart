// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_intake_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mailIntakeDataSource)
final mailIntakeDataSourceProvider = MailIntakeDataSourceProvider._();

final class MailIntakeDataSourceProvider
    extends
        $FunctionalProvider<
          MailIntakeDataSource,
          MailIntakeDataSource,
          MailIntakeDataSource
        >
    with $Provider<MailIntakeDataSource> {
  MailIntakeDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mailIntakeDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mailIntakeDataSourceHash();

  @$internal
  @override
  $ProviderElement<MailIntakeDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MailIntakeDataSource create(Ref ref) {
    return mailIntakeDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MailIntakeDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MailIntakeDataSource>(value),
    );
  }
}

String _$mailIntakeDataSourceHash() =>
    r'78f30e3e4fdda11cda4f43f5d9a3147b5a3a963d';
