import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

class DetailLine extends StatelessWidget {
  const DetailLine(
    this.label,
    this.value, {
    super.key,
    this.caption,
    this.mutedValue = false,
  });
  final String label, value;
  final String? caption;
  final bool mutedValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: mutedValue ? muted : ink,
                    height: 1.6,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    caption!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 9, color: muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
