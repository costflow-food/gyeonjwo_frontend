import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

class QueueSummary extends StatelessWidget {
  const QueueSummary({super.key, required this.waitingCount});

  final int waitingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.palette.accentText, context.palette.deep],
        ),
        boxShadow: [
          BoxShadow(
            color: context.palette.ink.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final introduction = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '흩어진 요청을, 한눈에 검토하십시오.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 10),
                Text(
                  '왼쪽 업무 큐에서 요청을 고르면 원문을 보고 수용하거나 다른 대안을 찾을 수 있습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.palette.onDeepMuted,
                  ),
                ),
              ],
            );
            final count = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  '검토를 기다리는 요청',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.palette.onDeepMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: waitingCount.toString().padLeft(2, "0"),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const TextSpan(
                        text: ' 건',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [introduction, const SizedBox(height: 20), count],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: introduction),
                const SizedBox(width: 24),
                count,
              ],
            );
          },
        ),
      ),
    );
  }
}
