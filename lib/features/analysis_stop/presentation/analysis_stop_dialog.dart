import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/workspace_colors.dart";
import "../../../shared/widgets/async_content.dart";
import "../domain/analysis_stop.dart";
import "analysis_stop_view_model.dart";

/// SCR-006 분석 중단 사유 대화상자를 엽니다.
///
/// [onOpenSource]는 SCR-004(원문·근거 보기)로 이어지는 동작입니다. 아직
/// SCR-004가 없으면 null로 두고, 그동안 '원문 확인' 버튼은 비활성으로 보입니다.
Future<void> showAnalysisStopDialog(
  BuildContext context, {
  required String requestId,
  VoidCallback? onOpenSource,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        AnalysisStopDialog(requestId: requestId, onOpenSource: onOpenSource),
  );
}

class AnalysisStopDialog extends ConsumerWidget {
  const AnalysisStopDialog({
    super.key,
    required this.requestId,
    this.onOpenSource,
  });

  final String requestId;
  final VoidCallback? onOpenSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(analysisStopViewModelProvider(requestId));
    final viewModel = ref.read(
      analysisStopViewModelProvider(requestId).notifier,
    );
    final stageLabel = value.asData?.value.stageLabel;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // 배경색이 있는 하단 영역이 아래쪽 모서리를 덮지 않도록 둥근 모양으로 자른다.
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              subtitle: stageLabel == null ? "검토 필요" : "검토 필요 · $stageLabel",
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                child: AsyncContent<AnalysisStop>(
                  value: value,
                  onRetry: viewModel.refresh,
                  builder: (data) => _Body(data: data),
                ),
              ),
            ),
            _Footer(onOpenSource: onOpenSource),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.subtitle});
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "분석을 중단했습니다",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "닫기",
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});
  final AnalysisStop data;

  @override
  Widget build(BuildContext context) {
    const paragraph = TextStyle(fontSize: 12, height: 1.8, color: ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final issue in data.issues) ...[
          _IssueBox(issue: issue),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        Text("${data.summary} ${data.guidance}", style: paragraph),
        const SizedBox(height: 14),
        const Text(
          "필수 정보가 없는 값을 임의로 채우거나 일부 금액만 계산한 카드를 제공하지 않습니다.",
          style: TextStyle(fontSize: 11, height: 1.7, color: muted),
        ),
      ],
    );
  }
}

class _IssueBox extends StatelessWidget {
  const _IssueBox({required this.issue});
  final StopIssue issue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: canvas,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "확인이 필요한 항목",
            style: TextStyle(fontSize: 11, color: muted),
          ),
          const SizedBox(height: 6),
          Text(
            issue.label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            issue.message,
            style: const TextStyle(fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onOpenSource});
  final VoidCallback? onOpenSource;

  @override
  Widget build(BuildContext context) {
    final sourceButton = OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: Color(0xFFAFB3BA)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        minimumSize: const Size(0, 38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      onPressed: onOpenSource == null
          ? null
          : () {
              Navigator.of(context).pop();
              onOpenSource!();
            },
      child: const Text("원문 확인"),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: const BoxDecoration(
        color: canvas,
        border: Border(top: BorderSide(color: line)),
      ),
      // 업무 큐로 버튼은 X 닫기와 동작이 같아 두지 않습니다.
      child: Align(
        alignment: Alignment.centerLeft,
        child: onOpenSource == null
            ? Tooltip(
                message: "원문 보기(SCR-004)가 연결되면 사용할 수 있습니다",
                child: sourceButton,
              )
            : sourceButton,
      ),
    );
  }
}
