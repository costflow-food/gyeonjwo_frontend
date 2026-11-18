import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/widgets/async_content.dart";
import "../../../shared/widgets/lds/lds.dart";
import "../../../shared/widgets/mobile_scaffold.dart";
import "../domain/workflow_log_state.dart";
import "widgets/workflow_log_content.dart";
import "widgets/workflow_log_header.dart";
import "workflow_log_view_model.dart";

/// 계정 메뉴의 '처리 이력'을 팝업으로 엽니다(계정 설정·접수 확인 팝업과 같은 틀).
/// 휴대폰은 계정 설정 화면의 버튼으로 지금처럼 화면(`/logs`)을 엽니다.
Future<void> showWorkflowLogDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    // Full screen on a phone: the dialog paints behind the system bars and
    // LdsDialog's own SafeArea keeps the content clear of them.
    useSafeArea: !isCompactLayout(context),
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: const WorkflowLogDialog(),
    ),
  );
}

class WorkflowLogDialog extends ConsumerWidget {
  const WorkflowLogDialog({super.key});

  /// 목록과 상세가 나란히 보이는 폭(내용 920 이상).
  static const maxWidth = 1200.0;

  /// 이력을 고르거나 더 불러와도 팝업 높이가 덜 바뀌도록 본문 최소 높이
  /// (화면이 낮으면 스크롤).
  static const minBodyHeight = 600.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(workflowLogViewModelProvider);
    final viewModel = ref.read(workflowLogViewModelProvider.notifier);
    return LdsDialog(
      title: "처리 이력",
      subtitle: WorkflowLogHeader.description,
      maxWidth: maxWidth,
      headerAction: LdsIconButton(
        icon: Icons.refresh,
        tooltip: "새로고침",
        onPressed: viewModel.refresh,
      ),
      footerNote: "관련 업무와 원문에서 근거를 확인하십시오.",
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minBodyHeight),
        child: AsyncContent<WorkflowLogState>(
          value: value,
          onRetry: viewModel.refresh,
          builder: (data) => WorkflowLogContent(
            data: data,
            viewModel: viewModel,
            // '업무 보기': close the popup, then go to the case.
            onLeave: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
