// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_queue_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
    r'576464d53fe8ce70db671244f55feb758ac62d7d';

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
