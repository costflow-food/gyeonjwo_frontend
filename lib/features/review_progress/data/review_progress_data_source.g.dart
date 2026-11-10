// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_progress_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

@ProviderFor(reviewProgressDataSource)
final reviewProgressDataSourceProvider = ReviewProgressDataSourceProvider._();

/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

final class ReviewProgressDataSourceProvider
    extends
        $FunctionalProvider<
          ReviewProgressDataSource,
          ReviewProgressDataSource,
          ReviewProgressDataSource
        >
    with $Provider<ReviewProgressDataSource> {
  /// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
  ReviewProgressDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewProgressDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewProgressDataSourceHash();

  @$internal
  @override
  $ProviderElement<ReviewProgressDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReviewProgressDataSource create(Ref ref) {
    return reviewProgressDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReviewProgressDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReviewProgressDataSource>(value),
    );
  }
}

String _$reviewProgressDataSourceHash() =>
    r'9ff5779c49f382706ccda680fb6277b1673798d2';
