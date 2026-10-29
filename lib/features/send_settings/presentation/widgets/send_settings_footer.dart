import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '시연 데이터 · 실제 메일은 발송되지 않습니다.',
            style: TextStyle(fontSize: AppFontSizes.caption, color: muted),
          ),
          const SizedBox(height: 8),
          if (error != null) ...[
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(
                        fontSize: AppFontSizes.body,
                        color: accent,
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
                style: WorkspaceButtonStyles.text,
                onPressed: saving ? null : onCancel,
                child: const Text("취소"),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: saving ? null : onSave,
                style: WorkspaceButtonStyles.filled,
                child: Text(saving ? "저장 중" : "설정 저장"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
