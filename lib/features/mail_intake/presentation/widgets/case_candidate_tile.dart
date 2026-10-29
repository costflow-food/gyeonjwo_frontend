import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/intake_mail.dart";

/// A case the mail may belong to. Shows differences so a shared item name
/// alone does not decide the link.
class CaseCandidateTile extends StatelessWidget {
  const CaseCandidateTile({
    super.key,
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final CaseCandidate candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lines = [
      if (candidate.itemName != null) "품목 · ${candidate.itemName}",
      if (candidate.conditions != null) "필수 조건 · ${candidate.conditions}",
      if (candidate.difference != null) "차이 · ${candidate.difference}",
      "답장·발송 근거 · ${candidate.replyEvidence ?? "없음"}",
    ];
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? blush : Colors.white,
            border: Border.all(color: selected ? accent : line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? accent : muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${candidate.title} · ${candidate.status}",
                      style: const TextStyle(
                        fontSize: AppFontSizes.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      candidate.caseId,
                      style: const TextStyle(
                        fontSize: AppFontSizes.caption,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final line in lines)
                      Text(
                        line,
                        style: const TextStyle(
                          fontSize: AppFontSizes.secondary,
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
