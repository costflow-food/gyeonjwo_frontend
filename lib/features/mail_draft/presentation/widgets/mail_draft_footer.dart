import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../domain/mail_draft.dart";

/// Buttons follow the draft status and send policy the server returns.
/// Labels match the real effect.
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
    required this.onWithdraw,
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
  final VoidCallback onWithdraw;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final current = draft;
    final blocked = current == null
        ? null
        : current.disabledReason(DraftAction.approveSend) ??
              current.disabledReason(DraftAction.reconcile);
    final editable =
        current != null &&
        (current.status == DraftStatus.draft ||
            current.status == DraftStatus.failed);
    final filled = WorkspaceButtonStyles.filled(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null || (blocked != null && !editing)) ...[
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  Icon(
                    error != null ? Icons.error_outline : Icons.block,
                    size: 16,
                    color: error != null ? danger : context.palette.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error ?? blocked!,
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        color: error != null ? danger : context.palette.muted,
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
                  style: WorkspaceButtonStyles.text(context),
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
                  style: WorkspaceButtonStyles.text(context),
                  onPressed: busy ? null : onClose,
                  child: const Text("닫기"),
                ),
                if (current != null && current.can(DraftAction.withdraw))
                  TextButton(
                    style: WorkspaceButtonStyles.text(context),
                    onPressed: busy ? null : onWithdraw,
                    child: const Text("보내지 않음"),
                  ),
                // Shown but disabled until the server has API-18.
                if (current != null && editable)
                  Tooltip(
                    message: current.disabledReason(DraftAction.edit) ?? "",
                    child: OutlinedButton(
                      style: WorkspaceButtonStyles.outlined(context),
                      onPressed: current.can(DraftAction.edit) && !busy
                          ? onEdit
                          : null,
                      child: Text(
                        current.status == DraftStatus.failed ? "수정본 만들기" : "수정",
                      ),
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
