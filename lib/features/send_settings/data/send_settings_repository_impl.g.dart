// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_settings_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sendSettingsRepository)
final sendSettingsRepositoryProvider = SendSettingsRepositoryProvider._();

final class SendSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SendSettingsRepository,
          SendSettingsRepository,
          SendSettingsRepository
        >
    with $Provider<SendSettingsRepository> {
  SendSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SendSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SendSettingsRepository create(Ref ref) {
    return sendSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendSettingsRepository>(value),
    );
  }
}

String _$sendSettingsRepositoryHash() =>
    r'4bc6e5b69043de06e23b5934a1de9cdbe50f6a41';
