// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completed_tasks_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// API-01 `archived=true`. 보관 전 목록([WorkQueueViewModel])과 따로 읽습니다:
/// 확정하면 서버가 업무를 보관해 기본 목록에서 빠지기 때문입니다.
/// [query]는 Tasks 검색어이고, Dashboard 건수는 빈 검색어로 읽습니다.

@ProviderFor(CompletedTasksViewModel)
final completedTasksViewModelProvider = CompletedTasksViewModelFamily._();

/// API-01 `archived=true`. 보관 전 목록([WorkQueueViewModel])과 따로 읽습니다:
/// 확정하면 서버가 업무를 보관해 기본 목록에서 빠지기 때문입니다.
/// [query]는 Tasks 검색어이고, Dashboard 건수는 빈 검색어로 읽습니다.
final class CompletedTasksViewModelProvider
    extends $AsyncNotifierProvider<CompletedTasksViewModel, CompletedTasks> {
  /// API-01 `archived=true`. 보관 전 목록([WorkQueueViewModel])과 따로 읽습니다:
  /// 확정하면 서버가 업무를 보관해 기본 목록에서 빠지기 때문입니다.
  /// [query]는 Tasks 검색어이고, Dashboard 건수는 빈 검색어로 읽습니다.
  CompletedTasksViewModelProvider._({
    required CompletedTasksViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'completedTasksViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$completedTasksViewModelHash();

  @override
  String toString() {
    return r'completedTasksViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CompletedTasksViewModel create() => CompletedTasksViewModel();

  @override
  bool operator ==(Object other) {
    return other is CompletedTasksViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$completedTasksViewModelHash() =>
    r'5e9da4718b80dc578e98a96a9c5e85db67d51ef5';

/// API-01 `archived=true`. 보관 전 목록([WorkQueueViewModel])과 따로 읽습니다:
/// 확정하면 서버가 업무를 보관해 기본 목록에서 빠지기 때문입니다.
/// [query]는 Tasks 검색어이고, Dashboard 건수는 빈 검색어로 읽습니다.

final class CompletedTasksViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          CompletedTasksViewModel,
          AsyncValue<CompletedTasks>,
          CompletedTasks,
          FutureOr<CompletedTasks>,
          String
        > {
  CompletedTasksViewModelFamily._()
    : super(
        retry: _noRetry,
        name: r'completedTasksViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// API-01 `archived=true`. 보관 전 목록([WorkQueueViewModel])과 따로 읽습니다:
  /// 확정하면 서버가 업무를 보관해 기본 목록에서 빠지기 때문입니다.
  /// [query]는 Tasks 검색어이고, Dashboard 건수는 빈 검색어로 읽습니다.

  CompletedTasksViewModelProvider call(String query) =>
      CompletedTasksViewModelProvider._(argument: query, from: this);

  @override
  String toString() => r'completedTasksViewModelProvider';
}

/// API-01 `archived=true`. 보관 전 목록([WorkQueueViewModel])과 따로 읽습니다:
/// 확정하면 서버가 업무를 보관해 기본 목록에서 빠지기 때문입니다.
/// [query]는 Tasks 검색어이고, Dashboard 건수는 빈 검색어로 읽습니다.

abstract class _$CompletedTasksViewModel
    extends $AsyncNotifier<CompletedTasks> {
  late final _$args = ref.$arg as String;
  String get query => _$args;

  FutureOr<CompletedTasks> build(String query);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CompletedTasks>, CompletedTasks>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CompletedTasks>, CompletedTasks>,
              AsyncValue<CompletedTasks>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
