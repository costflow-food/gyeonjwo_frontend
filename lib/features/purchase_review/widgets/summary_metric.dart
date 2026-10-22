import 'package:flutter/material.dart';

import '../../../shared/workspace_colors.dart';

class SummaryMetric extends StatelessWidget {
  const SummaryMetric(
    this.label,
    this.amount,
    this.unit,
    this.caption, {
    super.key,
    this.highlight = false,
  });
  final String label, amount, unit, caption;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: muted)),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: amount,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: highlight ? accent : ink,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 10,
                  color: highlight ? accent : muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(caption, style: const TextStyle(fontSize: 10, color: muted)),
      ],
    );
  }
}
