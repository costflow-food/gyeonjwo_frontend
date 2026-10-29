// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_log_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workflowLogRepository)
final workflowLogRepositoryProvider = WorkflowLogRepositoryProvider._();

final class WorkflowLogRepositoryProvider
    extends
        $FunctionalProvider<
          WorkflowLogRepository,
          WorkflowLogRepository,
          WorkflowLogRepository
        >
    with $Provider<WorkflowLogRepository> {
  WorkflowLogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workflowLogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workflowLogRepositoryHash();

  @$internal
  @override
  $ProviderElement<WorkflowLogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkflowLogRepository create(Ref ref) {
    return workflowLogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkflowLogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkflowLogRepository>(value),
    );
  }
}

String _$workflowLogRepositoryHash() =>
    r'80cb83eac6dadbb3a391fb7f237313fa680ba799';
