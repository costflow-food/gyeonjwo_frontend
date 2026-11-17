import 'package:flutter/material.dart';

import '../../lds_colors.dart';

/// 가로 진행 단계의 한 단계. [caption]은 이름 아래 보조 한 줄(시각·진행 내용).
class LdsStep {
  const LdsStep(this.label, {this.caption});

  final String label;
  final String? caption;
}

enum LdsStepState { done, current, upcoming }

/// 가로 진행 단계 (`docs/design-ssot.md` 8.2): Tasks 진행 상황과 검토 진행 창.
///
/// 원 28. 완료 = 주황 채움 + 체크, 지금 = 주황 채움 + 연한 주황 테두리 4,
/// 남은 단계 = 흰 원 + 연한 주황 테두리. 잇는 선은 지난 구간 주황 실선 2,
/// 남은 구간 `#FFBF99` 점선. 첫 단계는 왼쪽, 마지막 단계는 오른쪽 끝에 맞춥니다.
class LdsStepBar extends StatelessWidget {
  const LdsStepBar({super.key, required this.steps, required this.current})
    : assert(steps.length >= 2);

  final List<LdsStep> steps;

  /// 지금 단계(0부터). [steps] 길이면 모두 완료, null이면 지금 단계를
  /// 모릅니다(모두 남은 단계로 그립니다).
  final int? current;

  static const circle = 28.0;

  LdsStepState stateOf(int index) {
    final now = current;
    if (now == null) return LdsStepState.upcoming;
    if (index < now) return LdsStepState.done;
    return index == now ? LdsStepState.current : LdsStepState.upcoming;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final gap = (width - circle) / (steps.length - 1);
      // 이름 칸 폭: 가운데 단계는 원을 가운데 두고 한 칸, 끝 단계는 안쪽으로.
      final labelWidth = gap < circle ? circle : gap;
      final scaler = MediaQuery.textScalerOf(context);
      final hasCaption = steps.any((step) => step.caption != null);
      final labelHeight =
          scaler.scale(15) * 1.4 +
          (hasCaption ? 2 + scaler.scale(13) * 1.4 : 0) +
          2;
      return SizedBox(
        height: circle + 10 + labelHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: circle / 2,
              right: circle / 2,
              top: circle / 2 - 1,
              height: 2,
              child: CustomPaint(
                painter: _LinePainter(
                  segments: steps.length - 1,
                  // 지난 구간: 지금 단계까지(모두 완료면 끝까지).
                  doneSegments: switch (current) {
                    null => 0,
                    final now => now.clamp(0, steps.length - 1),
                  },
                ),
              ),
            ),
            for (final (index, step) in steps.indexed) ...[
              Positioned(
                left: gap * index,
                top: 0,
                child: _Circle(number: index + 1, state: stateOf(index)),
              ),
              _label(index, step, gap, labelWidth, width),
            ],
          ],
        ),
      );
    },
  );

  Widget _label(
    int index,
    LdsStep step,
    double gap,
    double labelWidth,
    double width,
  ) {
    final first = index == 0;
    final last = index == steps.length - 1;
    final center = gap * index + circle / 2;
    final left = first
        ? 0.0
        : last
        ? width - labelWidth
        : center - labelWidth / 2;
    final (align, textAlign) = first
        ? (CrossAxisAlignment.start, TextAlign.start)
        : last
        ? (CrossAxisAlignment.end, TextAlign.end)
        : (CrossAxisAlignment.center, TextAlign.center);
    final state = stateOf(index);
    final stateText = switch (state) {
      LdsStepState.done => "완료",
      LdsStepState.current => "지금 단계",
      LdsStepState.upcoming => "남은 단계",
    };
    return Positioned(
      left: left,
      width: labelWidth,
      top: circle + 10,
      child: Semantics(
        label: [
          "${steps.length}단계 중 ${index + 1}단계 ${step.label}",
          stateText,
          ?step.caption,
        ].join(", "),
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: align,
          children: [
            Text(
              step.label,
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: state == LdsStepState.upcoming
                    ? LdsColors.muted
                    : LdsColors.ink,
              ),
            ),
            if (step.caption != null) ...[
              const SizedBox(height: 2),
              Text(
                step.caption!,
                textAlign: textAlign,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: LdsColors.mutedStrong,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.number, required this.state});

  final int number;
  final LdsStepState state;

  @override
  Widget build(BuildContext context) {
    const size = LdsStepBar.circle;
    return switch (state) {
      LdsStepState.done => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: LdsColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      ),
      // 연한 주황 테두리 4는 원 바깥에 그려 원 크기 28을 지킵니다.
      LdsStepState.current => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: LdsColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: LdsColors.primaryLight, spreadRadius: 4),
          ],
        ),
        child: _number(Colors.white),
      ),
      LdsStepState.upcoming => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: LdsColors.primaryLight, width: 2),
        ),
        child: _number(LdsColors.primary),
      ),
    };
  }

  Widget _number(Color color) => Text(
    "$number",
    textScaler: TextScaler.noScaling,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      height: 1,
      color: color,
    ),
  );
}

/// 지난 구간 주황 실선, 남은 구간 `#FFBF99` 점선(두께 2).
class _LinePainter extends CustomPainter {
  const _LinePainter({required this.segments, required this.doneSegments});

  final int segments;
  final int doneSegments;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final split = size.width / segments * doneSegments;
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    if (split > 0) {
      paint.color = LdsColors.primary;
      canvas.drawLine(Offset(0, y), Offset(split, y), paint);
    }
    paint.color = LdsColors.primaryLight;
    const dash = 6.0, gap = 4.0;
    for (var x = split; x < size.width; x += dash + gap) {
      final end = x + dash > size.width ? size.width : x + dash;
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) =>
      oldDelegate.segments != segments ||
      oldDelegate.doneSegments != doneSegments;
}
