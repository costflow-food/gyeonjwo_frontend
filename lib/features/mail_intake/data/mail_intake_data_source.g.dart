// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_intake_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱은 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

@ProviderFor(mailIntakeDataSource)
final mailIntakeDataSourceProvider = MailIntakeDataSourceProvider._();

/// 앱은 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

final class MailIntakeDataSourceProvider
    extends
        $FunctionalProvider<
          MailIntakeDataSource,
          MailIntakeDataSource,
          MailIntakeDataSource
        >
    with $Provider<MailIntakeDataSource> {
  /// 앱은 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
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
    r'66857bdbcf821ac16da357da5aab2f3493a689ce';
