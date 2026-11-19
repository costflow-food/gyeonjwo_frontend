import "package:flutter/material.dart";

import "../../../../shared/widgets/lds/lds.dart";

/// 거래처 검색칸 (LDS 입력칸, 높이 36).
class SupplierSearchField extends StatelessWidget {
  const SupplierSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => LdsSearchField(
    controller: controller,
    onChanged: onChanged,
    hintText: "업체명, 품목, 담당자, 지역 검색",
  );
}
