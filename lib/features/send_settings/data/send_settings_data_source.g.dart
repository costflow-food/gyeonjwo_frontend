// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_settings_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱은 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

@ProviderFor(sendSettingsDataSource)
final sendSettingsDataSourceProvider = SendSettingsDataSourceProvider._();

/// 앱은 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

final class SendSettingsDataSourceProvider
    extends
        $FunctionalProvider<
          SendSettingsDataSource,
          SendSettingsDataSource,
          SendSettingsDataSource
        >
    with $Provider<SendSettingsDataSource> {
  /// 앱은 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
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
    r'0c364fca51ccfa5f9e2dbc80cb8938fd1cf68323';
