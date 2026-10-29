import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (status) {
      '검토 대기' => (
        const Color(0xFF347BC8),
        const Color(0xFFDCF2FD),
        Icons.schedule,
      ),
      '완료' => (const Color(0xFF4B9138), const Color(0xFFE7F5E1), Icons.check),
      '검토 중' => (ink, const Color(0xFFF0F1F4), Icons.hourglass_top),
      '검토 필요' => (
        const Color(0xFFBC793C),
        const Color(0xFFFFF2E2),
        Icons.warning_amber_rounded,
      ),
      '제외' => (muted, const Color(0xFFF0F1F4), Icons.remove),
      _ => (muted, Colors.transparent, Icons.remove),
    };
    final textStyle = TextStyle(fontSize: 11, color: color);
    // 네 글자 상태 문구의 실제 폭을 글자 배율까지 반영해 공통 기준으로 씁니다.
    final labelPainter = TextPainter(
      text: TextSpan(
        text: '검토 대기',
        style: DefaultTextStyle.of(context).style.merge(textStyle),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    )..layout();
    final labelWidth = labelPainter.width;
    labelPainter.dispose();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: background == Colors.transparent ? 0 : labelWidth,
            ),
            child: Text(status, textAlign: TextAlign.center, style: textStyle),
          ),
        ],
      ),
    );
  }
}
