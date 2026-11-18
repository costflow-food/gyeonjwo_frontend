import "package:flutter/material.dart";

import "../lds_colors.dart";

/// 목록 칸 맨 위 화면 설명 한 줄(Suppliers·Invoices 공용): 13px 회색, 줄간격 1.6.
/// 아래 단추·필터와는 12 띄웁니다.
class PageLeadText extends StatelessWidget {
  const PageLeadText(this.text, {super.key});

  final String text;

  /// 설명 줄과 아래 단추 줄 사이.
  static const gap = 12.0;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      height: 1.6,
      letterSpacing: -.3,
      color: LdsColors.muted,
    ),
  );
}
