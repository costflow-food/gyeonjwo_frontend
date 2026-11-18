import 'package:flutter/material.dart';

import '../lds_colors.dart';

/// Thoner 가로 로고. T 심볼과 같은 주황 `#FF6000`으로 칠합니다
/// (`docs/design-ssot.md` 7.8.2). 주어진 폭 안에서 왼쪽에 붙습니다.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 32});

  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Thoner',
    child: Image.asset(
      'assets/branding/thoner_logo.png',
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      color: LdsColors.primary,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    ),
  );
}
