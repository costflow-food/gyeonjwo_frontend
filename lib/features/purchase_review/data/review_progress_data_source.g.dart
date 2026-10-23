// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_progress_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reviewProgressDataSource)
final reviewProgressDataSourceProvider = ReviewProgressDataSourceProvider._();

final class ReviewProgressDataSourceProvider
    extends
        $FunctionalProvider<
          ReviewProgressDataSource,
          ReviewProgressDataSource,
          ReviewProgressDataSource
        >
    with $Provider<ReviewProgressDataSource> {
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
    r'cdd5d511fa6027f52400eeb3fca4e15a9d0ae771';
