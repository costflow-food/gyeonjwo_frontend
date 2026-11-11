import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";

/// 업무 상세(폰)의 "통화 녹음" 칸. 붙은 녹음 목록은 업로드 API가 생기면
/// 이 칸에 함께 보여 줍니다.
class CallRecordingSection extends StatelessWidget {
  const CallRecordingSection({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        "통화 녹음",
        style: TextStyle(
          fontSize: AppFontSizes.body,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Semantics(
        button: true,
        child: CustomPaint(
          foregroundPainter: _DashedBorder(
            color: context.palette.muted.withValues(alpha: .5),
          ),
          child: Material(
            color: context.palette.surface.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.palette.blush,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic,
                        size: 20,
                        color: context.palette.accentText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "통화 녹음 추가",
                            style: TextStyle(
                              fontSize: AppFontSizes.body,
                              fontWeight: FontWeight.w700,
                              color: context.palette.accentText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "이 업무와 관련된 통화·음성 녹음 파일을 붙입니다.",
                            style: TextStyle(
                              fontSize: AppFontSizes.caption,
                              color: context.palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.75),
          const Radius.circular(14),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 9) {
        canvas.drawPath(metric.extractPath(start, start + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => oldDelegate.color != color;
}
