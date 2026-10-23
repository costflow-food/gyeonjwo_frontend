// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_queue_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workQueueDataSource)
final workQueueDataSourceProvider = WorkQueueDataSourceProvider._();

final class WorkQueueDataSourceProvider
    extends
        $FunctionalProvider<
          WorkQueueDataSource,
          WorkQueueDataSource,
          WorkQueueDataSource
        >
    with $Provider<WorkQueueDataSource> {
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
    r'88cef85f78e45683183799e60388698c53ac607e';
