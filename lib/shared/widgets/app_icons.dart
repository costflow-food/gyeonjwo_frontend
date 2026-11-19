import 'package:flutter/material.dart';

import 'workflow_step_icon.dart';

/// 메뉴 아이콘(시안의 선 아이콘): 24 격자, 선 두께 2, 둥근 끝.
/// Material 아이콘에 같은 모양이 없어 직접 그립니다.
enum AppIcon {
  /// 둥근 사각 + 세로선 + 오른쪽 가로선.
  dashboard,

  /// 체크 두 개 + 줄 두 개.
  tasks,

  /// 줄이 있는 문서 + 오른쪽 아래 말린 끝.
  transactions,

  /// 차양이 있는 가게.
  suppliers,

  /// 사이드바 펼치기: 줄 + 오른쪽 화살촉.
  sidebarExpand,

  /// 사이드바 접기: 줄 + 왼쪽 화살촉.
  sidebarCollapse,
}

class AppIconView extends StatelessWidget {
  const AppIconView(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final AppIcon icon;
  final double size;

  /// 없으면 [IconTheme] 색.
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: Size.square(size),
      painter: _AppIconPainter(
        icon,
        color ?? IconTheme.of(context).color ?? const Color(0xFF333D4B),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: paint);
    return Semantics(label: semanticLabel, child: paint);
  }
}

class _AppIconPainter extends CustomPainter {
  const _AppIconPainter(this.icon, this.color);

  final AppIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), stroke);
    void poly(List<Offset> points) =>
        canvas.drawPath(Path()..addPolygon(points, false), stroke);
    const r1 = Radius.circular(1);
    const r2 = Radius.circular(2);
    switch (icon) {
      case AppIcon.dashboard:
        canvas.drawRRect(RRect.fromLTRBR(4, 4, 20, 20, r2), stroke);
        line(10, 4, 10, 20);
        line(10, 12, 20, 12);
      case AppIcon.tasks:
        poly(const [Offset(4, 8.5), Offset(6, 10.5), Offset(9, 7.5)]);
        line(13, 9, 20, 9);
        poly(const [Offset(4, 14.5), Offset(6, 16.5), Offset(9, 13.5)]);
        line(13, 15.5, 20, 15.5);
      case AppIcon.transactions:
        canvas.drawPath(
          Path()
            ..moveTo(17, 16)
            ..lineTo(17, 5)
            ..arcToPoint(const Offset(16, 4), radius: r1, clockwise: false)
            ..lineTo(6, 4)
            ..arcToPoint(const Offset(5, 5), radius: r1, clockwise: false)
            ..lineTo(5, 19)
            ..arcToPoint(const Offset(6, 20), radius: r1, clockwise: false)
            ..lineTo(18.5, 20)
            ..arcToPoint(
              const Offset(20, 18.5),
              radius: const Radius.circular(1.5),
              clockwise: false,
            )
            ..lineTo(20, 17)
            ..arcToPoint(const Offset(19, 16), radius: r1, clockwise: false)
            ..lineTo(17, 16)
            ..lineTo(17, 18.5)
            ..arcToPoint(
              const Offset(18.5, 20),
              radius: const Radius.circular(1.5),
              clockwise: false,
            ),
          stroke,
        );
        line(8.5, 8, 13.5, 8);
        line(8.5, 11.5, 13.5, 11.5);
        line(8.5, 15, 11, 15);
      case AppIcon.suppliers:
        canvas.drawPath(workflowStepPath(2), Paint()..color = color);
      case AppIcon.sidebarExpand:
        line(5, 7, 13, 7);
        line(5, 12, 13, 12);
        line(5, 17, 19, 17);
        poly(const [Offset(16, 7), Offset(19, 9.5), Offset(16, 12)]);
      case AppIcon.sidebarCollapse:
        line(11, 7, 19, 7);
        line(11, 12, 19, 12);
        line(5, 17, 19, 17);
        poly(const [Offset(8, 7), Offset(5, 9.5), Offset(8, 12)]);
    }
  }

  @override
  bool shouldRepaint(_AppIconPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.color != color;
}
