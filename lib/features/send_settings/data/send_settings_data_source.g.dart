// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_settings_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sendSettingsDataSource)
final sendSettingsDataSourceProvider = SendSettingsDataSourceProvider._();

final class SendSettingsDataSourceProvider
    extends
        $FunctionalProvider<
          SendSettingsDataSource,
          SendSettingsDataSource,
          SendSettingsDataSource
        >
    with $Provider<SendSettingsDataSource> {
  SendSettingsDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendSettingsDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendSettingsDataSourceHash();

  @$internal
  @override
  $ProviderElement<SendSettingsDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SendSettingsDataSource create(Ref ref) {
    return sendSettingsDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendSettingsDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendSettingsDataSource>(value),
    );
  }
}

String _$sendSettingsDataSourceHash() =>
    r'8a2ed3d067afce435ec92a953896b104c88b4325';
