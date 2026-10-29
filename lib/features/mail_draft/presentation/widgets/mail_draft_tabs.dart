import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/mail_draft.dart";
import "draft_status_badge.dart";

/// One tab per supplier draft, each with its own status. No combined result.
class MailDraftTabs extends StatelessWidget {
  const MailDraftTabs({
    super.key,
    required this.drafts,
    required this.selectedId,
    required this.onSelect,
  });

  final List<MailDraft> drafts;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final draft in drafts)
          Semantics(
            selected: draft.id == selectedId,
            button: true,
            child: InkWell(
              onTap: () => onSelect(draft.id),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
                decoration: BoxDecoration(
                  color: draft.id == selectedId ? blush : Colors.white,
                  border: Border.all(
                    color: draft.id == selectedId ? accent : line,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${draft.supplierName} · ${draft.purpose.label}",
                      style: const TextStyle(
                        fontSize: AppFontSizes.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DraftStatusBadge(draft.status),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
