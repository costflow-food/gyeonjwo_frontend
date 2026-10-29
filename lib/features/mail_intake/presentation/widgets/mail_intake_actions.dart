import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../domain/intake_mail.dart";

/// Three explicit outcomes. A new case starts as Waiting without analysis.
class MailIntakeActions extends StatelessWidget {
  const MailIntakeActions({
    super.key,
    required this.enabled,
    required this.canLink,
    required this.busy,
    required this.error,
    required this.onResolve,
  });

  final bool enabled;
  final bool canLink;
  final bool busy;
  final String? error;
  final ValueChanged<IntakeResolution> onResolve;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '시연 데이터 · 새로고침하면 초기화됩니다.',
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
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                style: WorkspaceButtonStyles.outlined,
                onPressed: active
                    ? () => onResolve(IntakeResolution.nonBusiness)
                    : null,
                child: const Text("비업무로 확인"),
              ),
              OutlinedButton(
                style: WorkspaceButtonStyles.outlined,
                onPressed: active
                    ? () => onResolve(IntakeResolution.createCase)
                    : null,
                child: const Text("새 업무로 접수"),
              ),
              FilledButton(
                onPressed: active && canLink
                    ? () => onResolve(IntakeResolution.linkCase)
                    : null,
                style: WorkspaceButtonStyles.filled,
                child: Text(busy ? "처리 중" : "선택한 업무에 연결"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
