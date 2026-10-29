import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/intake_mail.dart";
import "case_candidate_tile.dart";
import "intake_reason_badge.dart";

/// Original text, the classifier's reason, and possible case groups.
class IntakeMailDetail extends StatelessWidget {
  const IntakeMailDetail({
    super.key,
    required this.mail,
    required this.selectedCaseId,
    required this.onSelectCase,
    required this.reason,
  });

  final IntakeMail mail;
  final String? selectedCaseId;
  final ValueChanged<String> onSelectCase;
  final TextEditingController reason;

  @override
  Widget build(BuildContext context) {
    const caption = TextStyle(fontSize: AppFontSizes.caption, color: muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mail.subject,
          style: const TextStyle(
            fontSize: AppFontSizes.cardTitle,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "${mail.sender} · ${formatSeoulDateTime(mail.receivedAt)}",
          style: caption,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: canvas,
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntakeReasonBadge(mail.reason),
              const SizedBox(height: 6),
              Text(
                mail.reasonDetail,
                style: const TextStyle(fontSize: AppFontSizes.body),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text("원문", style: caption),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            mail.bodyText,
            style: const TextStyle(fontSize: AppFontSizes.body, height: 1.6),
          ),
        ),
        if (mail.attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text("첨부 · ${mail.attachments.join(", ")}", style: caption),
        ],
        const SizedBox(height: 18),
        Text(
          mail.candidates.isEmpty
              ? "연결 후보 업무 없음"
              : "연결 후보 업무 ${mail.candidates.length}",
          style: const TextStyle(
            fontSize: AppFontSizes.bodyLarge,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final candidate in mail.candidates)
          CaseCandidateTile(
            candidate: candidate,
            selected: candidate.caseId == selectedCaseId,
            onTap: () => onSelectCase(candidate.caseId),
          ),
        const SizedBox(height: 10),
        TextField(
          controller: reason,
          style: const TextStyle(fontSize: AppFontSizes.body),
          decoration: const InputDecoration(
            labelText: "확인 사유 (선택)",
            hintText: "예: 회신 규격이 달라 새 업무로 접수",
            labelStyle: TextStyle(fontSize: AppFontSizes.body),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
      ],
    );
  }
}
