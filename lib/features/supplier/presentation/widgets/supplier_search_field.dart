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
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: controller,
    builder: (context, value, _) => LdsTextField(
      controller: controller,
      onChanged: onChanged,
      hintText: "업체명, 품목, 담당자, 지역 검색",
      prefixIcon: Icons.search,
      suffix: value.text.isEmpty
          ? null
          : IconButton(
              tooltip: "검색 지우기",
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                controller.clear();
                onChanged("");
              },
            ),
    ),
  );
}
