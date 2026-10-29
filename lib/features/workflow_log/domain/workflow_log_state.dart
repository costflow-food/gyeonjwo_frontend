import "workflow_log.dart";
import "workflow_log_filter.dart";

/// SCR-010 list state. Filtering runs on the server (API-28).
class WorkflowLogState {
  const WorkflowLogState({
    required this.filter,
    required this.entries,
    required this.total,
    this.nextCursor,
    this.selectedId,
    this.isSearching = false,
    this.isLoadingMore = false,
    this.loadFailed = false,
  });

  final WorkflowLogFilter filter;
  final List<WorkflowLogEntry> entries;
  final int total;
  final String? nextCursor;
  final String? selectedId;
  final bool isSearching;
  final bool isLoadingMore;
  final bool loadFailed;

  bool get hasMore => nextCursor != null;

  WorkflowLogEntry? get selected =>
      entries.where((entry) => entry.id == selectedId).firstOrNull;

  WorkflowLogState copyWith({
    WorkflowLogFilter? filter,
    List<WorkflowLogEntry>? entries,
    int? total,
    String? Function()? nextCursor,
    String? Function()? selectedId,
    bool? isSearching,
    bool? isLoadingMore,
    bool? loadFailed,
  }) {
    return WorkflowLogState(
      filter: filter ?? this.filter,
      entries: entries ?? this.entries,
      total: total ?? this.total,
      nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
      selectedId: selectedId == null ? this.selectedId : selectedId(),
      isSearching: isSearching ?? this.isSearching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadFailed: loadFailed ?? this.loadFailed,
    );
  }
}
