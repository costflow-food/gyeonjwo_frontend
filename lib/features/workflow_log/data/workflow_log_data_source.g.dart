// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_log_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workflowLogDataSource)
final workflowLogDataSourceProvider = WorkflowLogDataSourceProvider._();

final class WorkflowLogDataSourceProvider
    extends
        $FunctionalProvider<
          WorkflowLogDataSource,
          WorkflowLogDataSource,
          WorkflowLogDataSource
        >
    with $Provider<WorkflowLogDataSource> {
  WorkflowLogDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workflowLogDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workflowLogDataSourceHash();

  @$internal
  @override
  $ProviderElement<WorkflowLogDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkflowLogDataSource create(Ref ref) {
    return workflowLogDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkflowLogDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkflowLogDataSource>(value),
    );
  }
}

String _$workflowLogDataSourceHash() =>
    r'cd1f8deced91062142764247782a8056d7fd8d40';
