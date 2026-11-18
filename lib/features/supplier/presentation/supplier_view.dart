import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/lds_colors.dart";
import "../../../shared/widgets/async_content.dart";
import "../../../shared/widgets/lds/lds.dart";
import "../../../shared/widgets/mobile_scaffold.dart";
import "../../../shared/widgets/note_line.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../domain/supplier_list_state.dart";
import "supplier_register_dialog.dart";
import "supplier_view_model.dart";
import "widgets/supplier_content.dart";
import "widgets/supplier_detail_panel.dart";
import "widgets/supplier_header.dart";
import "widgets/supplier_list_panel.dart";
import "widgets/supplier_list_status.dart";
import "widgets/supplier_search_field.dart";

/// 맨 아래 안내 문구(목록·상세 칸 바깥).
const supplierPriceNote = "견적과 실거래 가격의 적용일·조건을 함께 확인하세요.";

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
    if (isCompactLayout(context)) return _phone(context, value, viewModel);
    // 상단 바: 날짜 확인 달력(검색 왼쪽). 그 아래 설명 줄 + 단추 →
    // 목록·상세 두 칸 → 맨 아래 안내 문구.
    return WorkspaceShell(
      scrollable: false,
      topAction: const LdsDateViewButton(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WorkspaceShell.gutter,
              vertical: 14,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: LdsColors.line)),
            ),
            child: SupplierHeader(
              onRefresh: viewModel.refresh,
              onRegister: () => showSupplierRegisterDialog(context),
            ),
          ),
          Expanded(
            child: AsyncContent<SupplierListState>(
              value: value,
              onRetry: viewModel.refresh,
              builder: (data) => SupplierContent(
                data: data,
                search: _search,
                viewModel: viewModel,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WorkspaceShell.gutter,
              vertical: 10,
            ),
            decoration: const BoxDecoration(
              color: LdsColors.canvas,
              border: Border(top: BorderSide(color: LdsColors.line)),
            ),
            child: const NoteLine(supplierPriceNote),
          ),
        ],
      ),
    );
  }

  /// Phone: the list here; a supplier opens on its own screen.
  Widget _phone(
    BuildContext context,
    AsyncValue<SupplierListState> value,
    SupplierListViewModel viewModel,
  ) => MobileTabScaffold(
    title: "Suppliers",
    actions: [
      IconButton(
        tooltip: "거래처 등록",
        onPressed: () => showSupplierRegisterDialog(context),
        icon: const Icon(Icons.add_business_outlined),
      ),
      IconButton(
        tooltip: "새로고침",
        onPressed: viewModel.refresh,
        icon: const Icon(Icons.refresh),
      ),
    ],
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        SupplierSearchField(controller: _search, onChanged: viewModel.search),
        const SizedBox(height: 10),
        AsyncContent<SupplierListState>(
          value: value,
          onRetry: viewModel.refresh,
          builder: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SupplierListStatus(
                data: data,
                onRetry: viewModel.refresh,
                onSort: viewModel.sortBy,
              ),
              const SizedBox(height: 8),
              SupplierListPanel(
                data: data,
                showSelection: false,
                onSelect: (id) {
                  viewModel.select(id);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _SupplierDetailPage(supplierId: id),
                    ),
                  );
                },
                onLoadMore: viewModel.loadMore,
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 16, 4, 0),
          child: NoteLine(supplierPriceNote),
        ),
      ],
    ),
  );
}

class _SupplierDetailPage extends ConsumerWidget {
  const _SupplierDetailPage({required this.supplierId});

  final String supplierId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref
        .watch(supplierDetailViewModelProvider(supplierId))
        .value
        ?.name;
    return MobilePageScaffold(
      title: name ?? "거래처",
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: SupplierDetailPanel(supplierId: supplierId),
      ),
    );
  }
}
