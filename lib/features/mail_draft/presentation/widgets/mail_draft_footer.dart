import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/mail_draft.dart";

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
    // 닫기·보내지 않음 = 글자 버튼, 수정 = 테두리, 승인 후 발송 = 채움.
    return Column(
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
                  color: error != null
                      ? LdsColors.errorText
                      : LdsColors.mutedStrong,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error ?? blocked!,
                    style: TextStyle(
                      fontSize: 14,
                      color: error != null
                          ? LdsColors.errorText
                          : LdsColors.mutedStrong,
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
                onPressed: busy ? null : onCancelEdit,
                child: const Text("편집 취소"),
              ),
              LdsButton(
                onPressed: busy ? null : onSaveRevision,
                label: current?.approvalRequired == false
                    ? "수정 저장·자동발송 적용"
                    : "수정 저장",
              ),
            ] else ...[
              TextButton(
                onPressed: busy ? null : onClose,
                child: const Text("닫기"),
              ),
              if (current != null && current.can(DraftAction.withdraw))
                TextButton(
                  onPressed: busy ? null : onWithdraw,
                  child: const Text("보내지 않음"),
                ),
              // A stale or pending draft keeps the button, disabled.
              if (current != null && editable)
                LdsButton(
                  variant: LdsButtonVariant.outlinedNeutral,
                  onPressed: current.can(DraftAction.edit) && !busy
                      ? onEdit
                      : null,
                  label: current.status == DraftStatus.failed
                      ? "수정본 만들기"
                      : "수정",
                ),
              if (current != null && current.can(DraftAction.reconcile))
                LdsButton(
                  onPressed: busy ? null : onReconcile,
                  label: busy ? "확인 중" : "발신함 대조",
                ),
              if (current != null && current.can(DraftAction.approveSend))
                LdsButton(
                  onPressed: busy ? null : onApprove,
                  label: busy ? "요청 중" : "승인 후 발송",
                ),
            ],
          ],
        ),
      ],
    );
  }
}
