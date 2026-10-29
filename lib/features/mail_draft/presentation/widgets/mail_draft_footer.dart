import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../domain/mail_draft.dart";

/// Buttons follow the server's allowed_actions. Labels match the real effect.
class MailDraftFooter extends StatelessWidget {
  const MailDraftFooter({
    super.key,
    required this.draft,
    required this.editing,
    required this.busy,
    required this.error,
    required this.onEdit,
    required this.onCancelEdit,
    required this.onSaveRevision,
    required this.onApprove,
    required this.onReconcile,
    required this.onClose,
  });

  final MailDraft? draft;
  final bool editing;
  final bool busy;
  final String? error;
  final VoidCallback onEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveRevision;
  final VoidCallback onApprove;
  final VoidCallback onReconcile;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final current = draft;
    final blocked = current == null
        ? null
        : current.disabledReason(DraftAction.edit) ??
              current.disabledReason(DraftAction.approveSend);
    final filled = WorkspaceButtonStyles.filled;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '시연 데이터 · 실제 메일은 발송되지 않습니다.',
            style: TextStyle(fontSize: AppFontSizes.caption, color: muted),
          ),
          const SizedBox(height: 8),
          if (error != null || (blocked != null && !editing)) ...[
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  Icon(
                    error != null ? Icons.error_outline : Icons.block,
                    size: 16,
                    color: error != null ? accent : muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error ?? blocked!,
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        color: error != null ? accent : muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (editing) ...[
                TextButton(
                  style: WorkspaceButtonStyles.text,
                  onPressed: busy ? null : onCancelEdit,
                  child: const Text("편집 취소"),
                ),
                FilledButton(
                  onPressed: busy ? null : onSaveRevision,
                  style: filled,
                  child: Text(
                    current?.approvalRequired == false
                        ? "수정 저장·자동발송 적용"
                        : "수정 저장",
                  ),
                ),
              ] else ...[
                TextButton(
                  style: WorkspaceButtonStyles.text,
                  onPressed: busy ? null : onClose,
                  child: const Text("닫기"),
                ),
                if (current != null && current.can(DraftAction.edit))
                  OutlinedButton(
                    style: WorkspaceButtonStyles.outlined,
                    onPressed: busy ? null : onEdit,
                    child: Text(
                      current.status == DraftStatus.failed ? "수정본 만들기" : "수정",
                    ),
                  ),
                if (current != null && current.can(DraftAction.reconcile))
                  FilledButton(
                    onPressed: busy ? null : onReconcile,
                    style: filled,
                    child: Text(busy ? "확인 중" : "발신함 대조"),
                  ),
                if (current != null && current.can(DraftAction.approveSend))
                  FilledButton(
                    onPressed: busy ? null : onApprove,
                    style: filled,
                    child: Text(busy ? "요청 중" : "승인 후 발송"),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
