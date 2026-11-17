import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/supplier_list_state.dart";
import "../supplier_view_model.dart";
import "supplier_detail_panel.dart";
import "supplier_list_panel.dart";
import "supplier_list_status.dart";
import "supplier_search_field.dart";

class SupplierContent extends StatefulWidget {
  const SupplierContent({
    super.key,
    required this.data,
    required this.search,
    required this.viewModel,
  });

  final SupplierListState data;
  final TextEditingController search;
  final SupplierListViewModel viewModel;

  @override
  State<SupplierContent> createState() => _SupplierContentState();
}

class _SupplierContentState extends State<SupplierContent> {
  final _listKey = GlobalKey();
  final _detailKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = key.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
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
        final list = LdsPanel(
          key: _listKey,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SupplierSearchField(
                controller: widget.search,
                onChanged: viewModel.search,
              ),
              const SizedBox(height: 12),
              SupplierListStatus(data: data, onRetry: viewModel.refresh),
              const SizedBox(height: 12),
              SupplierListPanel(
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
        final selectedId = data.selectedId;
        final detail = selectedId == null
            ? const LdsPanel(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "거래처를 선택하면 상세 정보를 볼 수 있습니다.",
                      style: TextStyle(
                        fontSize: 15,
                        color: LdsColors.mutedStrong,
                      ),
                    ),
                  ),
                ),
              )
            : SupplierDetailPanel(
                key: ValueKey(selectedId),
                supplierId: selectedId,
              );
        if (!narrow) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: list),
              const SizedBox(width: 20),
              Expanded(flex: 7, child: detail),
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
                if (selectedId != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _scrollTo(_listKey),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text("목록으로"),
                      style: TextButton.styleFrom(
                        foregroundColor: LdsColors.title,
                      ),
                    ),
                  ),
                detail,
              ],
            ),
          ],
        );
      },
    );
  }
}
