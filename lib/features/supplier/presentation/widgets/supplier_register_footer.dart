import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";

/// 아래 줄: (오류) + 취소(글자 버튼) · 등록/저장(채움).
class SupplierRegisterFooter extends StatelessWidget {
  const SupplierRegisterFooter({
    super.key,
    required this.error,
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
    this.submitLabel = "등록",
  });

  /// "등록" for a new supplier, "저장" when editing.
  final String submitLabel;

  final String? error;
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: LdsColors.errorText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: LdsColors.errorText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: submitting ? null : onCancel,
              child: const Text("취소"),
            ),
            const SizedBox(width: 8),
            LdsButton(
              label: submitting ? "$submitLabel 중" : submitLabel,
              loading: submitting,
              onPressed: submitting ? null : onSubmit,
            ),
          ],
        ),
      ],
    );
  }
}
