// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_log_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

@ProviderFor(workflowLogDataSource)
final workflowLogDataSourceProvider = WorkflowLogDataSourceProvider._();

/// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.

final class WorkflowLogDataSourceProvider
    extends
        $FunctionalProvider<
          WorkflowLogDataSource,
          WorkflowLogDataSource,
          WorkflowLogDataSource
        >
    with $Provider<WorkflowLogDataSource> {
  /// 앱은 항상 실제 API를 씁니다. 합성 응답은 UI 미리보기 페이지와 테스트에서만 덮어씁니다.
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
    r'3135d53c0511ec5dd077feb03c47541169431671';
