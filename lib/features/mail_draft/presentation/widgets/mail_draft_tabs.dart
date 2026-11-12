import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/mobile_scaffold.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/mail_draft.dart";
import "draft_status_badge.dart";

class MailDraftTabs extends StatefulWidget {
  const MailDraftTabs({
    super.key,
    required this.drafts,
    required this.selectedId,
    required this.onSelect,
    this.dispatchStates = const {},
  });

  final List<MailDraft> drafts;

  final Map<String, DraftDispatchState> dispatchStates;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  State<MailDraftTabs> createState() => _MailDraftTabsState();
}

class _MailDraftTabsState extends State<MailDraftTabs> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _showSelected();
  }

  @override
  void didUpdateWidget(MailDraftTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) _showSelected();
  }

  /// Phone: the tabs are one sliding row, so bring the selected one into it.
  /// Only the row moves; the dialog's own scroll stays where it is.
  void _showSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = _selectedKey.currentContext;
      if (!mounted || selected == null || !isCompactLayout(context)) return;
      final box = selected.findRenderObject();
      if (box == null) return;
      Scrollable.maybeOf(selected)?.position.ensureVisible(
        box,
        alignment: .5,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final drafts = widget.drafts;
    final dispatchStates = widget.dispatchStates;
    final selectedId = widget.selectedId;
    final onSelect = widget.onSelect;
    final tabs = [
      for (final draft in drafts)
        Semantics(
          key: draft.id == selectedId ? _selectedKey : null,
          selected: draft.id == selectedId,
          button: true,
          child: InkWell(
            onTap: () => onSelect(draft.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
              decoration: BoxDecoration(
                color: draft.id == selectedId
                    ? context.palette.blush
                    : context.palette.surface,
                border: Border.all(
                  color: draft.id == selectedId
                      ? context.palette.accentText
                      : context.palette.line,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${draft.displayName} · ${draft.purpose.label}",
                    style: const TextStyle(
                      fontSize: AppFontSizes.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DraftStatusBadge(draft.status),
                  if (dispatchStates[draft.id] case final dispatch?
                      when draft.status == DraftStatus.draft) ...[
                    const SizedBox(width: 6),
                    Text(
                      dispatch.label,
                      style: TextStyle(
                        fontSize: AppFontSizes.caption,
                        color: context.palette.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
    ];
    // Phone: one sliding row instead of a stack of tabs above the draft.
    if (isCompactLayout(context)) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (index, tab) in tabs.indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              tab,
            ],
          ],
        ),
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: tabs);
  }
}
