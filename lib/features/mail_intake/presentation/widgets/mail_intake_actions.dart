import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/intake_mail.dart";

/// 아래 줄: (오류) + 비업무로 확인 · 새 업무로 접수(테두리) · 선택한 업무에
/// 연결(채움).
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
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            LdsButton(
              label: "비업무로 확인",
              variant: LdsButtonVariant.outlinedNeutral,
              onPressed: active
                  ? () => onResolve(IntakeResolution.nonBusiness)
                  : null,
            ),
            LdsButton(
              label: "새 업무로 접수",
              variant: LdsButtonVariant.outlinedNeutral,
              onPressed: active
                  ? () => onResolve(IntakeResolution.createCase)
                  : null,
            ),
            LdsButton(
              label: busy ? "처리 중" : "선택한 업무에 연결",
              onPressed: active && canLink
                  ? () => onResolve(IntakeResolution.linkCase)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
