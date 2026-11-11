import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/widgets/async_content.dart";
import "../../../shared/widgets/mobile_scaffold.dart";
import "../../../shared/widgets/note_line.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../domain/supplier_list_state.dart";
import "supplier_view_model.dart";
import "../../../shared/widgets/outline_panel.dart";
import "widgets/supplier_content.dart";
import "widgets/supplier_detail_panel.dart";
import "widgets/supplier_header.dart";
import "widgets/supplier_list_panel.dart";
import "widgets/supplier_list_status.dart";
import "widgets/supplier_search_field.dart";

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
            child: NoteLine("견적과 실거래 가격의 적용일·조건을 함께 확인하십시오."),
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
    title: "거래처",
    actions: [
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
              SupplierListStatus(data: data, onRetry: viewModel.refresh),
              const SizedBox(height: 8),
              OutlinePanel(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: SupplierListPanel(
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
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 16, 4, 0),
          child: NoteLine("견적과 실거래 가격의 적용일·조건을 함께 확인하십시오."),
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
