import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/outline_panel.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/workflow_log_state.dart";
import "../workflow_log_view_model.dart";
import "workflow_log_detail.dart";
import "workflow_log_filters.dart";
import "workflow_log_list.dart";

/// Filters on top, then the timeline and the selected entry's details.
class WorkflowLogContent extends StatefulWidget {
  const WorkflowLogContent({
    super.key,
    required this.data,
    required this.search,
    required this.viewModel,
    required this.onReset,
  });

  final WorkflowLogState data;
  final TextEditingController search;
  final WorkflowLogViewModel viewModel;
  final VoidCallback onReset;

  @override
  State<WorkflowLogContent> createState() => _WorkflowLogContentState();
}

class _WorkflowLogContentState extends State<WorkflowLogContent> {
  final _listKey = GlobalKey();
  final _detailKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || key.currentContext == null) return;
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final viewModel = widget.viewModel;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 920;
        final list = OutlinePanel(
          key: _listKey,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "총 ${data.total}건 · 최신순",
                      style: const TextStyle(
                        fontSize: AppFontSizes.secondary,
                        color: muted,
                      ),
                    ),
                  ),
                  if (data.isSearching)
                    const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (data.loadFailed)
                    TextButton.icon(
                      onPressed: viewModel.refresh,
                      icon: const Icon(
                        Icons.error_outline,
                        size: 15,
                        color: accent,
                      ),
                      label: const Text(
                        "조회 실패 · 다시 시도",
                        style: TextStyle(fontSize: AppFontSizes.secondary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFF64666B)),
              WorkflowLogList(
                data: data,
                onSelect: (id) {
                  viewModel.select(id);
                  if (narrow) _scrollTo(_detailKey);
                },
                onLoadMore: viewModel.loadMore,
              ),
            ],
          ),
        );
        final detail = WorkflowLogDetail(entry: data.selected);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkflowLogFilters(
              filter: data.filter,
              search: widget.search,
              onSearch: viewModel.searchCase,
              onChanged: viewModel.applyFilter,
              onReset: widget.onReset,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (!narrow) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: list),
                      const SizedBox(width: 20),
                      Expanded(flex: 5, child: detail),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    list,
                    const SizedBox(height: 20),
                    Column(
                      key: _detailKey,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (data.selected != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _scrollTo(_listKey),
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('목록으로'),
                              style: TextButton.styleFrom(foregroundColor: ink),
                            ),
                          ),
                        detail,
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
