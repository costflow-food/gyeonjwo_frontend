import 'package:flutter/material.dart';

import '../../../../shared/workspace_colors.dart';

class AnalysisStopHeader extends StatelessWidget {
  const AnalysisStopHeader({super.key, required this.stage});

  final String stage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '분석을 중단했습니다',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(stage, style: const TextStyle(fontSize: 9, color: muted)),
              ],
            ),
          ),
          IconButton(
            tooltip: '닫기',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 16, color: muted),
          ),
        ],
      ),
    );
  }
}
