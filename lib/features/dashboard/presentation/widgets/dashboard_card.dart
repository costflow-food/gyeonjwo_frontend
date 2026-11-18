import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";

/// Dashboard 아래 카드(월별 처리 추세 · 품목별 구매 비중): 흰 패널, 1px
/// `#E5E7EA`, 모서리 12. 그림자는 쓰지 않습니다(`docs/design-ssot.md` 1장).
class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LdsPanel(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    child: child,
  );
}

/// Dashboard 글자: 굵기 400·700·800, 자간 15px 이상 -0.3 · 13px 이하 0
/// (`docs/design-ssot.md` 2.1).
TextStyle dashText(
  double size,
  FontWeight weight,
  Color color, {
  double? height,
}) => TextStyle(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height ?? (size >= 19 ? 1.3 : 1.6),
  letterSpacing: size >= 15 ? -0.3 : 0,
);

/// 카드 제목 17/700 + 설명 13 (예: '월별 처리 추세', 2.1 크기 단계).
class DashboardCardHeader extends StatelessWidget {
  const DashboardCardHeader({
    super.key,
    required this.title,
    required this.caption,
  });

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: dashText(17, FontWeight.w700, LdsColors.ink)),
      ),
      const SizedBox(height: 4),
      Text(caption, style: dashText(13, FontWeight.w400, LdsColors.muted)),
    ],
  );
}
