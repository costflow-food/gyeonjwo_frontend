import "dart:math" as math;

import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/case_stage.dart";

/// Segmented ring for a queue row: one arc per stage, "2/5" in the middle and
/// a short label underneath. The current arc blinks while the AI works; a
/// resting case is drawn in grey and does not move.
///
/// Widget tests: a working ring schedules frames forever, so `pumpAndSettle`
/// times out while one is on screen. Use `pump(duration)` or wrap the test in
/// `MediaQuery(disableAnimations: true)`.
class StepRing extends StatefulWidget {
  const StepRing(this.stage, {super.key});

  final CaseStage stage;

  /// Column width: the common labels ("견적 요청 준비 중") fit on one line.
  static const width = 88.0;
  static const diameter = 46.0;
  static const strokeWidth = 4.0;
  static const maxLabelScale = 1.15;

  @override
  State<StepRing> createState() => _StepRingState();
}

class _StepRingState extends State<StepRing>
    with SingleTickerProviderStateMixin {
  // Half of the 1 → 0.3 → 1 blink; it runs back and forth.
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final _blink = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(StepRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final blink =
        widget.stage.working && !MediaQuery.disableAnimationsOf(context);
    if (blink == _controller.isAnimating) return;
    if (blink) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final stage = widget.stage;
    // accentText, not accent: light accents wash out on a white card.
    final color = stage.working ? palette.accentText : palette.muted;
    return Semantics(
      label: stage.semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: StepRing.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: StepRing.diameter,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Only the arcs repaint on a blink tick, not the number.
                    RepaintBoundary(
                      child: CustomPaint(
                        size: const Size.square(StepRing.diameter),
                        painter: StepRingPainter(
                          total: CaseStage.total,
                          done: stage.doneCount,
                          current: stage.working ? stage.index : null,
                          doneColor: color,
                          // palette.line disappears on the sidebar's tinted
                          // frame.
                          restColor: palette.ink.withValues(alpha: 0.14),
                          blink: _blink,
                          still: MediaQuery.disableAnimationsOf(context),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(StepRing.strokeWidth + 4),
                      // Large system text must not spill over the arcs.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "${stage.index}/${CaseStage.total}",
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: AppFontSizes.caption,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                // Word joiners keep each word whole: Korean would otherwise
                // break mid-word ("확인 필 / 요").
                stage.label
                    .split(" ")
                    .map((word) => word.split("").join("\u2060"))
                    .join(" "),
                semanticsLabel: stage.label,
                // The column is narrow: larger system text would only cut
                // the label short, so it grows a little and may take a third
                // line instead.
                textScaler: MediaQuery.textScalerOf(context)
                    .clamp(maxScaleFactor: StepRing.maxLabelScale),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSizes.captionSmall,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class StepRingPainter extends CustomPainter {
  StepRingPainter({
    required this.total,
    required this.done,
    required this.current,
    required this.doneColor,
    required this.restColor,
    required this.blink,
    this.still = false,
  }) : super(repaint: blink);

  final int total;
  final int done;

  /// 1-based arc that blinks, or null when nothing is running.
  final int? current;
  final Color doneColor;
  final Color restColor;
  final Animation<double> blink;

  /// Reduce motion: the current arc does not blink, so a fixed lighter tone
  /// sets it apart from the finished ones.
  final bool still;

  static const stillOpacity = 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = StepRing.strokeWidth;
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    // Round caps reach half a stroke past each end, so the visible gap is
    // this arc length minus one stroke width.
    final gap = (stroke + 4) / radius;
    final slot = 2 * math.pi / total;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < total; i++) {
      final number = i + 1;
      paint.color = number == current
          ? doneColor.withValues(
              alpha: still ? stillOpacity : 1 - 0.7 * blink.value,
            )
          : number <= done
          ? doneColor
          : restColor;
      canvas.drawArc(
        rect,
        -math.pi / 2 + slot * i + gap / 2,
        slot - gap,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StepRingPainter old) =>
      old.total != total ||
      old.done != done ||
      old.current != current ||
      old.doneColor != doneColor ||
      old.restColor != restColor ||
      old.blink != blink ||
      old.still != still;
}
