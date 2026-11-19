import 'package:flutter/material.dart';

import 'lds_text_field.dart';

/// 목록 위 검색칸 (LDS 입력칸, 높이 36): 돋보기 + [hintText], 글자가 있으면
/// 오른쪽에 '검색 지우기'. Suppliers·Invoices 목록 칸이 같이 씁니다.
class LdsSearchField extends StatelessWidget {
  const LdsSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: controller,
    builder: (context, value, _) => LdsTextField(
      controller: controller,
      onChanged: onChanged,
      hintText: hintText,
      prefixIcon: Icons.search,
      suffix: value.text.isEmpty
          ? null
          : IconButton(
              tooltip: '검색 지우기',
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
    ),
  );
}
