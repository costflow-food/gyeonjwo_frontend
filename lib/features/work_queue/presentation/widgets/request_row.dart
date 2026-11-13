import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/case_stage.dart";
import "../../domain/work_case.dart";
import "status_badge.dart";
import "step_ring.dart";

class RequestRow extends StatelessWidget {
  const RequestRow(
    this.data, {
    super.key,
    required this.selected,
    required this.onTap,
    this.card = false,
  });

  final WorkCase data;
  final bool selected;
  final VoidCallback onTap;

  /// Phone list: every row on its own white card.
  final bool card;

  @override
  Widget build(BuildContext context) {
    final received = formatSeoulDateTime(data.receivedAt);
    // "2026.10.19 10:24" → "10.19 10:24"; the year is noise in a short list.
    final shortTime = received.length > 5 ? received.substring(5) : received;
    final stage = ringStageOf(data);
    final content = _content(context, shortTime);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected || card ? context.palette.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: selected
              ? BorderSide(color: context.palette.accentText, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
            child: stage == null
                ? content
                : Row(
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: 12),
                      StepRing(stage),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, String shortTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppFontSizes.body,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: context.palette.ink,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.senderName ?? data.sender,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppFontSizes.secondary,
            color: context.palette.muted,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusBadge(data.status, rawCode: data.statusCode),
            Text(
              shortTime,
              style: TextStyle(
                fontSize: AppFontSizes.caption,
                color: context.palette.muted,
              ),
            ),
            if (data.replySummary case final replies? when replies.visible)
              Text(
                replies.shortLabel,
                semanticsLabel: replies.label,
                style: TextStyle(
                  fontSize: AppFontSizes.caption,
                  color: context.palette.muted,
                ),
              ),
            if (data.attachmentCount > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 11,
                    color: context.palette.muted,
                  ),
                  Text(
                    "${data.attachmentCount}",
                    semanticsLabel: "첨부 ${data.attachmentCount}개",
                    style: TextStyle(
                      fontSize: AppFontSizes.caption,
                      color: context.palette.muted,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
