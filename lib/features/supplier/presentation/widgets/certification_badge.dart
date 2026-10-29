import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/supplier.dart";

/// Unconfirmed and not-met use different text and icons, not color alone.
class CertificationBadge extends StatelessWidget {
  const CertificationBadge(this.certification, {super.key});
  final Certification certification;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (certification.status) {
      CertificationStatus.confirmed => (
        const Color(0xFF4B9138),
        const Color(0xFFE7F5E1),
        Icons.check,
      ),
      CertificationStatus.unconfirmed => (
        muted,
        const Color(0xFFF0F1F4),
        Icons.help_outline,
      ),
      CertificationStatus.notMet => (
        const Color(0xFFBC793C),
        const Color(0xFFFFF2E2),
        Icons.warning_amber_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              "${certification.name} · ${certification.status.label}",
              style: TextStyle(fontSize: AppFontSizes.secondary, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
