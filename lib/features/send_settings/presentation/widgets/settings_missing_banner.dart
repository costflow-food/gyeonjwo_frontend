import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";

/// configured=false. Sending stays blocked until every listed item is set.
class SettingsMissingBanner extends StatelessWidget {
  const SettingsMissingBanner({super.key, required this.missingItems});
  final List<String> missingItems;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFBC793C);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "설정 필요 · ${missingItems.join(", ")}. 설정을 마치기 전에는 해당 목적의 메일을 발송하지 않습니다.",
              style: const TextStyle(fontSize: AppFontSizes.body, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
