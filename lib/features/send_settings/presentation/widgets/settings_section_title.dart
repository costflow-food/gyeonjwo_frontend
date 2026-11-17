import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";

class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, this.description, {super.key});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: LdsColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: LdsColors.mutedStrong,
          ),
        ),
      ],
    );
  }
}
