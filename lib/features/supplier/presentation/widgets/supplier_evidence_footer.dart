import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";

/// Read-only notice and close. Closing never changes supplier data.
class SupplierEvidenceFooter extends StatelessWidget {
  const SupplierEvidenceFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "가격별 적용일·조건·출처를 확인하세요.",
              style: TextStyle(fontSize: AppFontSizes.secondary, color: muted),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("닫기"),
          ),
        ],
      ),
    );
  }
}
