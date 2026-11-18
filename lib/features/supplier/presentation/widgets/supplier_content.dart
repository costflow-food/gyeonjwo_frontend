import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/list_detail_layout.dart";
import "../../../../shared/widgets/note_line.dart";
import "../../domain/supplier_list_state.dart";
import "../supplier_view_model.dart";
import "supplier_detail_panel.dart";
import "supplier_list_panel.dart";
import "supplier_list_status.dart";
import "supplier_search_field.dart";

/// Suppliers 목록 칸 + 상세 칸 (Tasks와 같은 배치, [ListDetailLayout]).
///
/// 목록 칸: 검색칸 → '총 N곳 · 이름순' → 거래처 줄 묶음. 상세 칸: 고른
/// 거래처. 1100px 이하에서는 한 화면씩(목록 → 고르면 상세 → '목록으로').
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
  final _selectedRow = GlobalKey(debugLabel: "고른 거래처 줄");

  /// 한 화면씩 볼 때 상세를 연 상태인지. 넓은 화면은 늘 첫 거래처를 고른
  /// 채로 시작하므로 이 값과 상관없이 상세를 보여 줍니다.
  bool _detailOpen = false;

  void _open(String id) {
    widget.viewModel.select(id);
    setState(() => _detailOpen = true);
  }

  void _step(int step) {
    final suppliers = widget.data.suppliers;
    final at = suppliers.indexWhere((s) => s.id == widget.data.selectedId);
    final next = at == -1 ? 0 : at + step;
    if (next < 0 || next >= suppliers.length) return;
    widget.viewModel.select(suppliers[next].id);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final viewModel = widget.viewModel;
    final selectedId = data.selectedId;
    return ListDetailLayout(
      detailAlone: _detailOpen && selectedId != null,
      onBack: () => setState(() => _detailOpen = false),
      list: (padding, wide) => ListPaneColumn(
        padding: padding,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SupplierSearchField(
              controller: widget.search,
              onChanged: viewModel.search,
            ),
            const SizedBox(height: 12),
            SupplierListStatus(data: data, onRetry: viewModel.refresh),
          ],
        ),
        body: ListArrowKeys(
          onStep: _step,
          selectedKey: _selectedRow,
          child: SupplierListPanel(
            data: data,
            selectedKey: _selectedRow,
            onSelect: _open,
            onLoadMore: viewModel.loadMore,
          ),
        ),
      ),
      detail: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedId == null)
            const Text(
              "거래처를 선택하면 상세 정보를 볼 수 있습니다.",
              style: TextStyle(fontSize: 15, color: LdsColors.mutedStrong),
            )
          else
            SupplierDetailPanel(
              key: ValueKey(selectedId),
              supplierId: selectedId,
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 20, 4, 0),
            child: NoteLine("견적과 실거래 가격의 적용일·조건을 함께 확인하십시오."),
          ),
        ],
      ),
    );
  }
}
