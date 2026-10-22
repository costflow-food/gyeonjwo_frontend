import 'package:flutter/material.dart';

import '../../../shared/workspace_colors.dart';

class QueueSummary extends StatelessWidget {
  const QueueSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDADCE2)),
        borderRadius: BorderRadius.circular(10),
      ),
      foregroundDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: accent, width: 3)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          const introduction = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '흩어진 요청을, 한눈에 검토하세요.',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '요청을 실행하면 계약·구매 근거와 거래처 대안을 함께 확인할 수 있어요.',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          );
          const count = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('검토를 기다리는 요청', style: TextStyle(fontSize: 11, color: muted)),
              SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '02',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: -1,
                      ),
                    ),
                    TextSpan(
                      text: ' 건',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          );
          if (compact) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.inbox_outlined, color: accent, size: 28),
                SizedBox(height: 16),
                introduction,
                SizedBox(height: 20),
                Divider(color: line),
                SizedBox(height: 12),
                count,
              ],
            );
          }
          return Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: blush,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(flex: 4, child: introduction),
              const SizedBox(width: 24),
              const Expanded(child: count),
            ],
          );
        },
      ),
    );
  }
}
