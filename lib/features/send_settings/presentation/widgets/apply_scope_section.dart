import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/send_settings.dart";

/// Future drafts only, or also the listed existing drafts. Drafts already
/// sending, sent, or unknown are shown but cannot be picked.
class ApplyScopeSection extends StatelessWidget {
  const ApplyScopeSection({
    super.key,
    required this.applyTo,
    required this.drafts,
    required this.selectedDraftIds,
    required this.onApplyToChanged,
    required this.onToggleDraft,
  });

  final ApplyTo applyTo;
  final List<PendingDraft> drafts;
  final Set<String> selectedDraftIds;
  final ValueChanged<ApplyTo> onApplyToChanged;
  final void Function(String draftId, bool selected) onToggleDraft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScopeOption(
          selected: applyTo == ApplyTo.futureDrafts,
          title: "앞으로 생성할 초안에 적용",
          onTap: () => onApplyToChanged(ApplyTo.futureDrafts),
        ),
        _ScopeOption(
          selected: applyTo == ApplyTo.specifiedDrafts,
          title: "선택한 기존 초안에도 적용",
          subtitle: drafts.isEmpty
              ? "업무 설정에서만 기존 초안을 고를 수 있습니다."
              : "OFF로 바꾸면 선택한 초안은 다시 검증된 뒤 자동 발송될 수 있습니다.",
          onTap: drafts.isEmpty
              ? null
              : () => onApplyToChanged(ApplyTo.specifiedDrafts),
        ),
        if (applyTo == ApplyTo.specifiedDrafts)
          for (final draft in drafts)
            CheckboxListTile(
              activeColor: accent,
              value: selectedDraftIds.contains(draft.draftId),
              onChanged: draft.selectable
                  ? (checked) => onToggleDraft(draft.draftId, checked ?? false)
                  : null,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.only(left: 32),
              title: Text(
                "${draft.supplierName} · ${draft.purpose.label} · ${draft.recipient}",
                style: const TextStyle(fontSize: AppFontSizes.body),
              ),
              subtitle: Text(
                draft.selectable
                    ? draft.status.label
                    : "${draft.status.label} · 적용 대상에서 제외",
                style: const TextStyle(
                  fontSize: AppFontSizes.caption,
                  color: muted,
                ),
              ),
            ),
      ],
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        enabled: enabled,
        onTap: onTap,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          size: 20,
          color: selected ? accent : muted,
        ),
        title: Text(title, style: const TextStyle(fontSize: AppFontSizes.body)),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: AppFontSizes.caption,
                  color: muted,
                ),
              ),
      ),
    );
  }
}
