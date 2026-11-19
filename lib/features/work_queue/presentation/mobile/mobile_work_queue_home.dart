import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../app/app_paths.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/mobile_scaffold.dart";
import "../../../auth/presentation/gmail_connection_view_model.dart";
import "../../domain/task_group.dart";
import "../completed_tasks_view_model.dart";
import "../widgets/gmail_read_notice.dart";
import "../widgets/task_list.dart";
import "../work_queue_view_model.dart";

/// 휴대폰 Tasks 목록. 웹과 같은 [TaskList]이고, 업무를 누르면 상세가 한 화면을
/// 차지합니다. 접수·연결 확인은 Dashboard '미분류' 카드에서 엽니다.
class MobileWorkQueueHome extends ConsumerWidget {
  const MobileWorkQueueHome({super.key, this.tab});

  final TaskGroup? tab;

  void _refresh(WidgetRef ref) {
    ref.read(workQueueViewModelProvider.notifier).refresh();
    final query = ref.read(workQueueViewModelProvider).value?.query ?? "";
    ref.invalidate(completedTasksViewModelProvider(query));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readDenied = ref.watch(gmailCapabilitiesProvider).readDenied;
    return MobileTabScaffold(
      title: "Tasks",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (readDenied)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: GmailReadNotice(),
            ),
          Expanded(
            child: RefreshIndicator(
              color: LdsColors.primary,
              onRefresh: () async {
                _refresh(ref);
                // Keep the spinner until the list has reloaded.
                try {
                  await ref.read(workQueueViewModelProvider.future);
                } catch (_) {
                  // The list shows the error.
                }
              },
              child: TaskList(
                status: tab,
                selectedId: null,
                onOpen: (workCase) => context.go(
                  AppPaths.tasksAt(caseId: workCase.id, tab: tab?.code),
                ),
                onTab: (next) => context.go(AppPaths.tasksAt(tab: next?.code)),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
