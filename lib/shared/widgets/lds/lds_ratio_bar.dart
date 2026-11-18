import 'package:flutter/material.dart';

import '../../lds_colors.dart';

/// 비율 막대 색 (`docs/design-ssot.md` 3): 대등한 항목(업체 등)은 같은 무게의
/// 색을 차례로 씁니다. 한 색의 진하기로 나누지 않습니다.
const ldsRatioColors = [LdsColors.primary, LdsColors.title, LdsColors.disabled];

/// 비율 막대의 한 칸.
class LdsRatioSegment {
  const LdsRatioSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  /// 화면 낭독기에 읽히는 이름(색만으로 구분하지 않게).
  final String label;
  final num value;
  final Color color;
}

/// 비율 막대 (`docs/design-ssot.md` 3): 높이 12 · 모서리 6 · 칸 사이 4.
class LdsRatioBar extends StatelessWidget {
  const LdsRatioBar({super.key, required this.segments});

  static const height = 12.0;
  static const gap = 4.0;

  final List<LdsRatioSegment> segments;

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final segment in segments)
        if (segment.value > 0 && segment.value.isFinite) segment,
    ];
    final total = shown.fold<num>(0, (sum, segment) => sum + segment.value);
    return Semantics(
      label: shown.isEmpty
          ? null
          : [
              for (final segment in shown)
                "${segment.label} ${(segment.value / total * 100).round()}%",
            ].join(", "),
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: shown.isEmpty
            ? const DecoratedBox(
                decoration: BoxDecoration(
                  color: LdsColors.lineSoft,
                  borderRadius: BorderRadius.all(Radius.circular(height / 2)),
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, segment) in shown.indexed) ...[
                    if (index > 0) const SizedBox(width: gap),
                    Expanded(
                      flex: (segment.value / total * 1000).round().clamp(
                        1,
                        1000,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: segment.color,
                          borderRadius: BorderRadius.circular(height / 2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// 표·목록의 업체 색 점(10, `docs/design-ssot.md` 3).
class LdsColorDot extends StatelessWidget {
  const LdsColorDot(this.color, {super.key, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
