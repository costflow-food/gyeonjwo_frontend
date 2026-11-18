import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";

/// 아래 줄: (오류) + 취소(글자 버튼) · 설정 저장(채움).
class SendSettingsFooter extends StatelessWidget {
  const SendSettingsFooter({
    super.key,
    required this.error,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  final String? error;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback? onSave;

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
              onPressed: saving ? null : onCancel,
              child: const Text("취소"),
            ),
            const SizedBox(width: 8),
            LdsButton(
              label: saving ? "저장 중" : "설정 저장",
              onPressed: saving ? null : onSave,
            ),
          ],
        ),
      ],
    );
  }
}
