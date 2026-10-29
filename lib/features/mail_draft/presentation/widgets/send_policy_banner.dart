import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/mail_draft.dart";

/// What will happen to this draft under the current send setting and status.
class SendPolicyBanner extends StatelessWidget {
  const SendPolicyBanner({
    super.key,
    required this.draft,
    required this.editing,
  });

  final MailDraft draft;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final policy = draft.approvalRequired
        ? "승인 ON · 승인한 초안만 발송됩니다"
        : "승인 OFF · 설정 범위 안에서 검증 후 자동 발송됩니다";
    final (icon, color, message) = switch (draft.status) {
      DraftStatus.draft when !draft.settingsConfigured => (
        Icons.warning_amber_rounded,
        const Color(0xFFBC793C),
        '발송 설정을 완료해야 발송할 수 있습니다.',
      ),
      DraftStatus.draft
          when !draft.approvalRequired && !draft.autoSendAllowed =>
        (
          Icons.warning_amber_rounded,
          const Color(0xFFBC793C),
          '자동 발송 허용 업체·수신자 범위 밖입니다. 발송 설정을 확인해 주세요.',
        ),
      _ when editing && !draft.approvalRequired => (
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
        draft.approvalRequired
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
        draft.failureMessage ?? "발송하지 못했습니다.",
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
