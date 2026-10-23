import 'package:flutter/material.dart';

import '../../../../shared/widgets/outline_panel.dart';
import '../../../../shared/workspace_colors.dart';
import '../../domain/analysis_stop_reason.dart';

class StopReasonCard extends StatelessWidget {
  const StopReasonCard({super.key, required this.reason});

  final AnalysisStopReason reason;

  @override
  Widget build(BuildContext context) {
    return OutlinePanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reason.itemLabel,
            style: const TextStyle(fontSize: 9, color: muted),
          ),
          const SizedBox(height: 6),
          Text(
            reason.itemTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reason.itemDescription,
            style: const TextStyle(fontSize: 10, color: muted),
          ),
        ],
      ),
    );
  }
}
