// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_queue_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workQueueRepository)
final workQueueRepositoryProvider = WorkQueueRepositoryProvider._();

final class WorkQueueRepositoryProvider
    extends
        $FunctionalProvider<
          WorkQueueRepository,
          WorkQueueRepository,
          WorkQueueRepository
        >
    with $Provider<WorkQueueRepository> {
  WorkQueueRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workQueueRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workQueueRepositoryHash();

  @$internal
  @override
  $ProviderElement<WorkQueueRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkQueueRepository create(Ref ref) {
    return workQueueRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkQueueRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkQueueRepository>(value),
    );
  }
}

String _$workQueueRepositoryHash() =>
    r'09f1dedd176928e6fd31e4391148f7c75c396422';
