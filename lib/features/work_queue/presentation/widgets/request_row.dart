import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/work_case.dart";
import "status_badge.dart";

/// 사이드바 품목 그룹 안의 업무(메일) 한 건.
class RequestRow extends StatelessWidget {
  const RequestRow(
    this.data, {
    super.key,
    required this.selected,
    required this.onTap,
  });

  final WorkCase data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final received = formatSeoulDateTime(data.receivedAt);
    // "2026.10.19 10:24" → "10.19 10:24"; the year is noise in a short list.
    final shortTime = received.length > 5 ? received.substring(5) : received;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? blush : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.w600,
                    color: selected ? accent : ink,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.senderName ?? data.sender,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: muted,
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
                      style: const TextStyle(
                        fontSize: AppFontSizes.caption,
                        color: muted,
                      ),
                    ),
                    if (data.replySummary case final replies?
                        when replies.visible)
                      Text(
                        replies.shortLabel,
                        semanticsLabel: replies.label,
                        style: const TextStyle(
                          fontSize: AppFontSizes.caption,
                          color: muted,
                        ),
                      ),
                    if (data.attachmentCount > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file, size: 11, color: muted),
                          Text(
                            "${data.attachmentCount}",
                            semanticsLabel: "첨부 ${data.attachmentCount}개",
                            style: const TextStyle(
                              fontSize: AppFontSizes.caption,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
