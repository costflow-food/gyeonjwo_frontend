import 'package:flutter/material.dart';

import '../workspace_colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      // 선 그림 로고. 테마 글자색으로 칠해 다크 모드에서도 보이게 합니다.
      Image.asset(
        'assets/branding/logo.png',
        width: 38,
        height: 38,
        color: context.palette.ink,
        colorBlendMode: BlendMode.srcIn,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
      const SizedBox(width: 8),
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
