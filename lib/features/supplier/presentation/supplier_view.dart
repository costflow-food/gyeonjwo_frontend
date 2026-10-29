import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/widgets/async_content.dart";
import "../../../shared/widgets/note_line.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../domain/supplier_list_state.dart";
import "supplier_view_model.dart";
import "widgets/supplier_content.dart";
import "widgets/supplier_header.dart";

/// SCR-011 거래처 기준자료 검색과 조회.
class SupplierView extends ConsumerStatefulWidget {
  const SupplierView({super.key});

  @override
  ConsumerState<SupplierView> createState() => _SupplierViewState();
}

class _SupplierViewState extends ConsumerState<SupplierView> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    // Restore the query kept by the ViewModel when returning to this route.
    _search = TextEditingController(
      text: ref.read(supplierListViewModelProvider).asData?.value.query ?? "",
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(supplierListViewModelProvider);
    final viewModel = ref.read(supplierListViewModelProvider.notifier);
    return WorkspaceShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SupplierHeader(onRefresh: viewModel.refresh),
          const SizedBox(height: 24),
          AsyncContent<SupplierListState>(
            value: value,
            onRetry: viewModel.refresh,
            builder: (data) => SupplierContent(
              data: data,
              search: _search,
              viewModel: viewModel,
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 20, 4, 32),
            child: NoteLine("견적과 실거래 가격의 적용일·조건을 함께 확인하세요."),
          ),
        ],
      ),
    );
  }
}
