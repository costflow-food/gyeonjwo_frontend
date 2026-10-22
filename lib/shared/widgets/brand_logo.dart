import 'package:flutter/material.dart';

import '../workspace_colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CustomPaint(size: Size(34, 38), painter: _BrandMark()),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            '견줘',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends CustomPainter {
  const _BrandMark();

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
    canvas.drawCircle(const Offset(29, 4), 3, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_BrandMark oldDelegate) => false;
}
