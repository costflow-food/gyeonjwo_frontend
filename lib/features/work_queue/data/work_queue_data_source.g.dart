// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_queue_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

@ProviderFor(workQueueDataSource)
final workQueueDataSourceProvider = WorkQueueDataSourceProvider._();

/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

final class WorkQueueDataSourceProvider
    extends
        $FunctionalProvider<
          WorkQueueDataSource,
          WorkQueueDataSource,
          WorkQueueDataSource
        >
    with $Provider<WorkQueueDataSource> {
  /// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
  WorkQueueDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workQueueDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workQueueDataSourceHash();

  @$internal
  @override
  $ProviderElement<WorkQueueDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkQueueDataSource create(Ref ref) {
    return workQueueDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkQueueDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkQueueDataSource>(value),
    );
  }
}

String _$workQueueDataSourceHash() =>
    r'9fb9defedf0396d0132401420bee731b9f8ab6f6';
