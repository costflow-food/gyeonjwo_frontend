import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";

/// Error message, cancel, and submit with an in-progress state.
class SupplierRegisterFooter extends StatelessWidget {
  const SupplierRegisterFooter({
    super.key,
    required this.error,
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
  });

  final String? error;
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                onPressed: submitting ? null : onCancel,
                child: const Text("취소"),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: submitting ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: ink,
                  disabledBackgroundColor: ink.withValues(alpha: .7),
                  disabledForegroundColor: Colors.white,
                ),
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 16),
                label: Text(submitting ? "등록 중" : "등록"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
