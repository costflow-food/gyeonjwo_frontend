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
        const Color(0xFF00754A),
        const Color(0xFFE2F4EA),
        Icons.check,
      ),
      CertificationStatus.unconfirmed => (
        muted,
        const Color(0xFFEEF2F0),
        Icons.help_outline,
      ),
      CertificationStatus.notMet => (
        const Color(0xFF8A6516),
        const Color(0xFFF6EEDC),
        Icons.warning_amber_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
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
