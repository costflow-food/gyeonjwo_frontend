import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../app/app_paths.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../../mail_draft/presentation/mail_draft_dialog.dart";
import "../../../source_document/presentation/source_document_dialog.dart";
import "../../domain/workflow_log.dart";
import "log_outcome_badge.dart";

/// 고른 로그: 이벤트 이름 + 결과 라벨 · 요약 → 이름표-값 표 → 이동 단추.
class WorkflowLogDetail extends StatelessWidget {
  const WorkflowLogDetail({
    super.key,
    required this.entry,
    required this.caseFiltered,
    required this.onFilterCase,
  });

  final WorkflowLogEntry? entry;

  /// The list already shows only one case's logs.
  final bool caseFiltered;
  final void Function(String caseId, {String? caseTitle}) onFilterCase;

  @override
  Widget build(BuildContext context) {
    final value = entry;
    if (value == null) {
      return const LdsPanel(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              "이력을 선택하면 근거와 참조를 볼 수 있습니다.",
              style: TextStyle(fontSize: 15, color: LdsColors.mutedStrong),
            ),
          ),
        ),
      );
    }
    final caseId = value.caseId;
    final mailId = value.mailId;
    final draftId = value.draftId;
    LdsKeyValueRow row(String label, String text) => LdsKeyValueRow(
      label,
      child: SelectableText(
        text,
        style: const TextStyle(fontSize: 15, height: 1.6, color: LdsColors.ink),
      ),
    );
    return LdsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                value.eventLabel,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: LdsColors.ink,
                ),
              ),
              if (value.outcome != null) LogOutcomeBadge(value.outcome!),
            ],
          ),
          if (value.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              value.summary,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: LdsColors.title,
              ),
            ),
          ],
          const SizedBox(height: 16),
          LdsKeyValueTable(
            labelWidth: 136,
            rows: [
              row("시각", formatSeoulDateTime(value.createdAt)),
              row("업무", value.caseLabel),
              row("주체", value.actorLabel),
              if (value.runStatus != null)
                // Agent run status, shown apart from the case's Complete status.
                row("역할 실행 상태", value.runStatus!),
              if (value.durationMs != null)
                row("소요 시간", formatDuration(value.durationMs!)),
              if (value.sendPolicy != null)
                row("발송 방식", value.sendPolicy!.label),
              if (value.quoteVersion != null)
                row("견적 버전", "v${value.quoteVersion}"),
              if (value.settingsVersion != null)
                row("발송 설정 버전", "v${value.settingsVersion}"),
              if (value.toolName != null) row("도구", value.toolName!),
              if (value.toolResultRef != null)
                row("도구 결과 참조", value.toolResultRef!),
              if (value.errorCode != null) row("오류 코드", value.errorCode!),
              row(
                "사용한 근거",
                value.evidenceRefs.isEmpty
                    ? "없음"
                    : value.evidenceRefs.join(", "),
              ),
              if (value.requestId != null) row("request_id", value.requestId!),
            ],
          ),
          if (caseId != null || mailId != null || draftId != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (caseId != null && !caseFiltered)
                  LdsButton(
                    label: "이 업무 이력만",
                    icon: Icons.filter_list,
                    variant: LdsButtonVariant.outlinedNeutral,
                    onPressed: () =>
                        onFilterCase(caseId, caseTitle: value.caseLabel),
                  ),
                if (caseId != null)
                  LdsButton(
                    label: "업무 보기",
                    icon: Icons.open_in_new,
                    variant: LdsButtonVariant.outlinedNeutral,
                    onPressed: () => context.go(AppPaths.task(caseId)),
                  ),
                if (mailId != null)
                  LdsButton(
                    label: "원문 보기",
                    icon: Icons.mail_outline,
                    variant: LdsButtonVariant.outlinedNeutral,
                    onPressed: () =>
                        showSourceDocument(context, requestId: mailId),
                  ),
                if (draftId != null && caseId != null)
                  LdsButton(
                    label: "초안 보기",
                    icon: Icons.drafts_outlined,
                    variant: LdsButtonVariant.outlinedNeutral,
                    onPressed: () => showMailDraftDialog(
                      context,
                      caseId: caseId,
                      draftId: draftId,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
