// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_queue_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workQueueRequests)
final workQueueRequestsProvider = WorkQueueRequestsProvider._();

final class WorkQueueRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RequestItem>>,
          List<RequestItem>,
          FutureOr<List<RequestItem>>
        >
    with
        $FutureModifier<List<RequestItem>>,
        $FutureProvider<List<RequestItem>> {
  WorkQueueRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'workQueueRequestsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workQueueRequestsHash();

  @$internal
  @override
  $FutureProviderElement<List<RequestItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RequestItem>> create(Ref ref) {
    return workQueueRequests(ref);
  }
}

String _$workQueueRequestsHash() => r'b764982f4d5f1e7872c575e5f59abbbc6ae9872d';

@ProviderFor(WorkQueueViewModel)
final workQueueViewModelProvider = WorkQueueViewModelProvider._();

final class WorkQueueViewModelProvider
    extends $AsyncNotifierProvider<WorkQueueViewModel, WorkQueueState> {
  WorkQueueViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'workQueueViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workQueueViewModelHash();

  @$internal
  @override
  WorkQueueViewModel create() => WorkQueueViewModel();
}

String _$workQueueViewModelHash() =>
    r'783024f8fbda6c09fa5f4b01acc19c675c42187e';

abstract class _$WorkQueueViewModel extends $AsyncNotifier<WorkQueueState> {
  FutureOr<WorkQueueState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WorkQueueState>, WorkQueueState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WorkQueueState>, WorkQueueState>,
              AsyncValue<WorkQueueState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
