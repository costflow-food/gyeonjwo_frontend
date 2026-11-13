import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";

class SupplierRegisterHeader extends StatelessWidget {
  const SupplierRegisterHeader({
    super.key,
    required this.onClose,
    this.title = "거래처 등록",
  });
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 16, 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSizes.dialogTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: "닫기",
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
