import 'package:flutter/material.dart';

import '../workspace_colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        CustomPaint(
          size: const Size(34, 38),
          painter: _BrandMark(palette.ink, palette.accent),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            '견줘',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends CustomPainter {
  const _BrandMark(this.ink, this.dot);

  final Color ink, dot;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(3, 8)
        ..lineTo(17, 5)
        ..lineTo(17, 32)
        ..lineTo(3, 35)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(17, 7)
        ..lineTo(31, 4)
        ..lineTo(31, 31)
        ..lineTo(17, 33),
      paint,
    );
    canvas.drawCircle(const Offset(29, 4), 3, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_BrandMark oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.dot != dot;
}
