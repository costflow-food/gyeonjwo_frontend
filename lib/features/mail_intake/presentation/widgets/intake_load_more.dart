import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";

class IntakeLoadMore extends StatelessWidget {
  const IntakeLoadMore({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.expand_more, size: 16),
      label: const Text(
        "더 불러오기",
        style: TextStyle(fontSize: AppFontSizes.secondary),
      ),
      style: TextButton.styleFrom(foregroundColor: context.palette.muted),
    ),
  );
}
