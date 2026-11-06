import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/mail_draft.dart";

/// What will happen to this draft under the current send setting and status.
class SendPolicyBanner extends StatelessWidget {
  const SendPolicyBanner({
    super.key,
    required this.draft,
    required this.editing,
    this.dispatchState,
    this.onOpenSettings,
  });

  final MailDraft draft;
  final bool editing;

  /// API-12 result for this draft right after a candidate selection.
  final DraftDispatchState? dispatchState;

  /// Opens this case's send settings when the draft waits on them.
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final needsSettings =
        draft.status == DraftStatus.draft &&
        !draft.awaitingResult &&
        (!draft.settingsConfigured ||
            dispatchState == DraftDispatchState.blockedPolicy);
    final policy = switch (draft.approvalRequired) {
      _ when !draft.settingsConfigured => "발송 설정 필요",
      true => "자동 발송 꺼짐 · 승인한 초안만 발송됩니다",
      false => "자동 발송 켜짐 · 서버가 검증한 뒤 자동 발송됩니다",
      null => "발송 설정 확인 중",
    };
    final dispatch = dispatchState;
    final (icon, color, message) = switch (draft.status) {
      DraftStatus.draft when !draft.settingsConfigured => (
        Icons.warning_amber_rounded,
        const Color(0xFFBC793C),
        "발송 설정을 완료해야 발송할 수 있습니다. 메일함 기본값은 설정 → 메일 발송 설정에서, "
            "이 업무만의 값은 아래 '발송 설정 열기'에서 정합니다.",
      ),
      DraftStatus.draft when draft.isStale => (
        Icons.warning_amber_rounded,
        const Color(0xFFBC793C),
        "업무 내용이 바뀌어 이 초안은 발송할 수 없습니다.",
      ),
      _ when draft.awaitingResult => (
        Icons.hourglass_top,
        const Color(0xFF347BC8),
        "요청을 접수했습니다. 결과가 나오면 자동으로 표시됩니다.",
      ),
      DraftStatus.draft when dispatch != null => (
        dispatch == DraftDispatchState.blockedPolicy ||
                dispatch == DraftDispatchState.cautionRequired
            ? Icons.warning_amber_rounded
            : Icons.info_outline,
        dispatch == DraftDispatchState.blockedPolicy ||
                dispatch == DraftDispatchState.cautionRequired
            ? const Color(0xFFBC793C)
            : muted,
        "${dispatch.label} · ${dispatch.message}",
      ),
      _ when editing && draft.approvalRequired == false => (
        Icons.warning_amber_rounded,
        const Color(0xFFBC793C),
        "저장하면 새 초안으로 다시 검증한 뒤 설정에 따라 자동 발송됩니다.",
      ),
      _ when editing => (
        Icons.info_outline,
        muted,
        "저장하면 새 초안이 됩니다. 이전 승인은 이어지지 않습니다.",
      ),
      DraftStatus.draft => (
        Icons.info_outline,
        muted,
        draft.approvalRequired == true
            ? "내용을 확인한 뒤 승인 후 발송을 눌러 주세요."
            : "별도 버튼 없이 서버가 자동 발송합니다.",
      ),
      DraftStatus.sending => (
        Icons.outgoing_mail,
        const Color(0xFF347BC8),
        "발송 중입니다. 결과가 나오면 자동으로 표시됩니다.",
      ),
      DraftStatus.sent => (
        Icons.check_circle_outline,
        const Color(0xFF4B9138),
        "발송됨 · ${draft.sentAt == null ? "시각 미확인" : formatSeoulDateTime(draft.sentAt!)}",
      ),
      DraftStatus.failed => (
        Icons.error_outline,
        accent,
        "발송하지 못했습니다. 수신자와 발송 설정을 확인해 주세요.",
      ),
      DraftStatus.unknown => (
        Icons.help_outline,
        const Color(0xFFBC793C),
        "발송 여부를 확인 중이에요. 이미 전송됐을 수 있어 발신함 대조 전에는 다시 보내지 않습니다.",
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  policy,
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: AppFontSizes.body, color: color),
                ),
                if (needsSettings && onOpenSettings != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onOpenSettings,
                    style: WorkspaceButtonStyles.outlined,
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text("발송 설정 열기"),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
