// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_log_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SCR-010 filters, selection, and cursor paging (API-28).

@ProviderFor(WorkflowLogViewModel)
final workflowLogViewModelProvider = WorkflowLogViewModelProvider._();

/// SCR-010 filters, selection, and cursor paging (API-28).
final class WorkflowLogViewModelProvider
    extends $AsyncNotifierProvider<WorkflowLogViewModel, WorkflowLogState> {
  /// SCR-010 filters, selection, and cursor paging (API-28).
  WorkflowLogViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'workflowLogViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workflowLogViewModelHash();

  @$internal
  @override
  WorkflowLogViewModel create() => WorkflowLogViewModel();
}

String _$workflowLogViewModelHash() =>
    r'd9bc2002f7335629a8c3eb47b899c97d4fb76bd2';

/// SCR-010 filters, selection, and cursor paging (API-28).

abstract class _$WorkflowLogViewModel extends $AsyncNotifier<WorkflowLogState> {
  FutureOr<WorkflowLogState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<WorkflowLogState>, WorkflowLogState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WorkflowLogState>, WorkflowLogState>,
              AsyncValue<WorkflowLogState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
