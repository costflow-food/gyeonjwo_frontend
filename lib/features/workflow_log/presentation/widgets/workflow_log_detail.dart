import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/widgets/outline_panel.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../mail_draft/presentation/mail_draft_dialog.dart";
import "../../../source_document/presentation/source_document_dialog.dart";
import "../../domain/workflow_log.dart";
import "log_outcome_badge.dart";

/// References behind one entry and links to the related case, mail, or draft.
class WorkflowLogDetail extends StatelessWidget {
  const WorkflowLogDetail({super.key, required this.entry});
  final WorkflowLogEntry? entry;

  @override
  Widget build(BuildContext context) {
    final value = entry;
    if (value == null) {
      return const OutlinePanel(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              "로그를 선택하면 근거와 참조를 볼 수 있어요.",
              style: TextStyle(fontSize: AppFontSizes.body, color: muted),
            ),
          ),
        ),
      );
    }
    final caseId = value.caseId;
    final mailId = value.mailId;
    final draftId = value.draftId;
    return OutlinePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                value.eventType.label,
                style: const TextStyle(
                  fontSize: AppFontSizes.cardTitle,
                  fontWeight: FontWeight.w800,
                ),
              ),
              LogOutcomeBadge(value.outcome),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            value.summary,
            style: const TextStyle(
              fontSize: AppFontSizes.bodyLarge,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _Field("시각", formatSeoulDateTime(value.createdAt)),
          _Field("업무", value.caseTitle ?? "업무 생성 전"),
          _Field("주체", "${value.actor.label} (${value.component.label})"),
          if (value.runStatus != null)
            // Agent run status, shown apart from the case's Complete status.
            _Field("역할 실행 상태", value.runStatus!),
          if (value.durationMs != null)
            _Field("소요 시간", formatDuration(value.durationMs!)),
          if (value.sendPolicy != null)
            _Field("발송 방식", value.sendPolicy!.label),
          if (value.quoteVersion != null)
            _Field("견적 버전", "v${value.quoteVersion}"),
          if (value.settingsVersion != null)
            _Field("발송 설정 버전", "v${value.settingsVersion}"),
          if (value.toolName != null) _Field("도구", value.toolName!),
          if (value.toolResultRef != null)
            _Field("도구 결과 참조", value.toolResultRef!),
          if (value.errorCode != null) _Field("오류 코드", value.errorCode!),
          _Field(
            "사용한 근거",
            value.evidenceRefs.isEmpty ? "없음" : value.evidenceRefs.join(", "),
          ),
          _Field("request_id", value.requestId),
          if (caseId != null || mailId != null || draftId != null) ...[
            const SizedBox(height: 14),
            const Divider(color: line),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (caseId != null)
                  OutlinedButton.icon(
                    style: WorkspaceButtonStyles.outlined,
                    onPressed: () => context.go("/review?requestId=$caseId"),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text("업무 보기"),
                  ),
                if (mailId != null)
                  OutlinedButton.icon(
                    style: WorkspaceButtonStyles.outlined,
                    onPressed: () =>
                        showSourceDocument(context, requestId: mailId),
                    icon: const Icon(Icons.mail_outline, size: 16),
                    label: const Text("원문 보기"),
                  ),
                if (draftId != null && caseId != null)
                  OutlinedButton.icon(
                    style: WorkspaceButtonStyles.outlined,
                    onPressed: () => showMailDraftDialog(
                      context,
                      caseId: caseId,
                      draftId: draftId,
                    ),
                    icon: const Icon(Icons.drafts_outlined, size: 16),
                    label: const Text("초안 보기"),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSizes.secondary,
                color: muted,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: AppFontSizes.body),
            ),
          ),
        ],
      ),
    );
  }
}
