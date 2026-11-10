import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";

/// configured=false: the server has no stored value for some purposes yet.
/// The dialog shows them as the default (auto-send off) until saved.
class SettingsMissingBanner extends StatelessWidget {
  const SettingsMissingBanner({
    super.key,
    required this.missingItems,
    required this.caseScope,
  });

  final List<String> missingItems;
  final bool caseScope;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF8A6516);
    final items = missingItems.join(", ");
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EEDC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              caseScope
                  ? "메일함 기본값이 아직 저장되지 않았습니다 · $items. 메일함 발송 설정을 저장하면 기본값(자동 발송 꺼짐)이 적용됩니다."
                  : "아직 저장되지 않은 항목이 있습니다 · $items. 기본값(자동 발송 꺼짐)으로 표시했으며, 저장하면 적용됩니다.",
              style: const TextStyle(fontSize: AppFontSizes.body, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
