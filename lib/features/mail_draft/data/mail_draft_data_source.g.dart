// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_draft_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱은 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

@ProviderFor(mailDraftDataSource)
final mailDraftDataSourceProvider = MailDraftDataSourceProvider._();

/// 앱은 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

final class MailDraftDataSourceProvider
    extends
        $FunctionalProvider<
          MailDraftDataSource,
          MailDraftDataSource,
          MailDraftDataSource
        >
    with $Provider<MailDraftDataSource> {
  /// 앱은 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
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
    r'e10b237253f4b078dc4c8ad619c138aa875b113a';
