import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../app/app_paths.dart";
import "../../../shared/app_font_sizes.dart";
import "../../../shared/lds_colors.dart";
import "../../../shared/widgets/list_detail_layout.dart";
import "../../../shared/widgets/mobile_scaffold.dart";
import "../../../shared/widgets/outline_panel.dart";
import "../../../shared/widgets/workspace_shell.dart";
import "../../../shared/workspace_colors.dart";
import "../../auth/presentation/gmail_connection_view_model.dart";
import "../domain/task_group.dart";
import "../domain/work_case.dart";
import "completed_tasks_view_model.dart";
import "mobile/mobile_work_queue_home.dart";
import "recent_tasks.dart";
import "widgets/gmail_read_notice.dart";
import "widgets/task_list.dart";
import "widgets/work_case_panel.dart";
import "work_queue_view_model.dart";

/// Tasks (`docs/design-ssot.md` 7.13, 7.18): 목록 + 상세.
///
/// [caseId]는 `/tasks/{id}` 주소의 업무, [tab]은 `?tab=` 상태 탭입니다.
/// 주소가 선택의 기준이라 새로고침·링크로 같은 업무·탭을 다시 엽니다.
class WorkQueueView extends ConsumerStatefulWidget {
  const WorkQueueView({super.key, this.caseId, this.tab});

  final String? caseId;
  final TaskGroup? tab;

  /// 이 폭 이하에서는 목록과 상세를 한 화면씩 보여 줍니다(7.18).
  static const singlePaneWidth = ListDetailLayout.singlePaneWidth;

  /// 상세 내용 최대 폭(7.18).
  static const detailMaxWidth = ListDetailLayout.detailMaxWidth;

  /// 목록 칸 = 화면 폭의 30%, 최소 400 · 최대 480 (7.18).
  static double listWidth(double screenWidth) =>
      ListDetailLayout.listWidth(screenWidth);

  @override
  ConsumerState<WorkQueueView> createState() => _WorkQueueViewState();
}

class _WorkQueueViewState extends ConsumerState<WorkQueueView> {
  static const _gutter = WorkspaceShell.gutter;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(WorkQueueView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caseId != widget.caseId || oldWidget.tab != widget.tab) {
      _sync();
    }
  }

  /// The selection and the tab follow the address. Not during build.
  void _sync() => Future.microtask(() {
    if (!mounted) return;
    ref.read(workQueueViewModelProvider.notifier)
      ..select(widget.caseId)
      ..setStatus(widget.tab);
    ref.read(recentTasksProvider.notifier).visit(widget.caseId);
  });

  void _open(WorkCase workCase) =>
      context.go(AppPaths.tasksAt(caseId: workCase.id, tab: widget.tab?.code));

  /// 넓은 화면에서 고른 업무가 없으면 보이는 첫 행을 엽니다. 주소도 그 업무로
  /// 바꾸되 뒤로 가기에 빈 목록을 남기지 않습니다.
  void _autoOpen(WorkCase workCase) {
    if (!mounted || widget.caseId != null) return;
    context.replace(
      AppPaths.tasksAt(caseId: workCase.id, tab: widget.tab?.code),
    );
  }

  /// '나중에'·'검토 보류': 목록에서 지금 업무 다음 행을 엽니다.
  VoidCallback? _nextOf(String caseId) {
    final order = taskListOrder(ref, widget.tab);
    final at = order.indexWhere((workCase) => workCase.id == caseId);
    if (at == -1 || at + 1 >= order.length) return null;
    return () => _open(order[at + 1]);
  }

  void _changeTab(TaskGroup? tab) =>
      context.go(AppPaths.tasksAt(caseId: widget.caseId, tab: tab?.code));

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(workQueueViewModelProvider);
    final viewModel = ref.read(workQueueViewModelProvider.notifier);
    final data = value.hasValue ? value.requireValue : null;
    final caseId = widget.caseId;
    // 열린 업무가 받아 둔 목록(보관 전·완료)에 있으면 그대로 씁니다.
    final completed = ref
        .watch(completedTasksViewModelProvider(data?.query ?? ""))
        .value;
    final listed = caseId == null
        ? null
        : [
            ...?data?.items,
            ...?completed?.items,
          ].where((workCase) => workCase.id == caseId).firstOrNull;
    // While the other pages are on their way the case may be in those:
    // wait for them instead of reading it alone and swapping panels later.
    final listRead = (data != null && !viewModel.loadingRest) || value.hasError;
    if (isCompactLayout(context)) {
      if (caseId == null) return MobileWorkQueueHome(tab: widget.tab);
      if (listed != null) {
        return WorkCasePanel(key: ValueKey(listed.id), workCase: listed);
      }
      if (listRead) return _CaseDetail(caseId: caseId);
      return MobilePageScaffold(
        onBack: () => context.go(AppPaths.tasksAt(tab: widget.tab?.code)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final readDenied = ref.watch(gmailCapabilitiesProvider).readDenied;
    Widget detail() {
      if (listed != null) {
        return WorkCasePanel(
          key: ValueKey(listed.id),
          workCase: listed,
          onNext: _nextOf(listed.id),
        );
      }
      // Not in this search or page: read the case itself.
      if (caseId != null && listRead) return _CaseDetail(caseId: caseId);
      if (caseId != null) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return const _EmptyDetail();
    }

    Widget list({required EdgeInsets padding, bool autoSelect = false}) =>
        TaskList(
          status: widget.tab,
          selectedId: caseId,
          onOpen: _open,
          onTab: _changeTab,
          padding: padding,
          onAutoSelect: autoSelect ? _autoOpen : null,
        );

    return WorkspaceShell(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Outside the list state so it shows even when loading fails.
          if (readDenied)
            const Padding(
              padding: EdgeInsets.fromLTRB(_gutter, _gutter, _gutter, 0),
              child: GmailReadNotice(),
            ),
          Expanded(
            child: ListDetailLayout(
              detailAlone: caseId != null,
              onBack: () => context.go(AppPaths.tasksAt(tab: widget.tab?.code)),
              list: (padding, wide) => list(padding: padding, autoSelect: wide),
              detail: (_) => detail(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 업무를 고르지 않았을 때 상세 칸.
class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 12),
    child: Text(
      "왼쪽 목록에서 업무를 고르면 내용이 여기에 보입니다.",
      style: TextStyle(fontSize: 15, color: LdsColors.muted),
    ),
  );
}

class _CaseDetail extends ConsumerWidget {
  const _CaseDetail({required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A queue reload (realtime change, a finished step) means this case may
    // have changed too.
    ref.listen(workQueueViewModelProvider, (previous, next) {
      // A selection change keeps the same items; only a reload replaces them.
      final items = next.asData?.value.items;
      if (items != null && items != previous?.asData?.value.items) {
        ref.invalidate(caseDetailProvider(caseId));
      }
    });
    final value = ref.watch(caseDetailProvider(caseId));
    final compact = isCompactLayout(context);
    // On a phone the loaded case is a screen of its own; the other states
    // get the same back button.
    Widget page(Widget body) => compact
        ? MobilePageScaffold(
            onBack: () => context.go(AppPaths.tasks),
            body: SingleChildScrollView(
              // No bottom bar here, so keep clear of the system navigation.
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: body,
            ),
          )
        : body;
    return value.when(
      loading: () => page(
        const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => page(
        OutlinePanel(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 32,
                  color: context.palette.muted,
                ),
                const SizedBox(height: 12),
                Text(
                  error is WorkQueueFailure ? error.message : "업무를 불러오지 못했습니다.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppFontSizes.bodyLarge,
                    color: context.palette.muted,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(caseDetailProvider(caseId)),
                      child: const Text("다시 시도"),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppPaths.tasks),
                      child: const Text("목록으로"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      data: (workCase) =>
          WorkCasePanel(key: ValueKey(workCase.id), workCase: workCase),
    );
  }
}
