// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_progress_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reviewProgressRepository)
final reviewProgressRepositoryProvider = ReviewProgressRepositoryProvider._();

final class ReviewProgressRepositoryProvider
    extends
        $FunctionalProvider<
          ReviewProgressRepository,
          ReviewProgressRepository,
          ReviewProgressRepository
        >
    with $Provider<ReviewProgressRepository> {
  ReviewProgressRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewProgressRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewProgressRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReviewProgressRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReviewProgressRepository create(Ref ref) {
    return reviewProgressRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReviewProgressRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReviewProgressRepository>(value),
    );
  }
}

String _$reviewProgressRepositoryHash() =>
    r'ce2c5c0cc9712dce2d85704308bb6b1af9b82278';
