import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/send_settings.dart";

/// Whether auto-send is shown as on for one purpose.
///
/// [value] is the edited approval (`approval_required`); null falls back to the
/// stored effective value, and an unset effective value uses the team default:
/// auto-send off (approval required).
bool autoSendShown(PurposeApproval approval, bool? value) =>
    !(value ?? approval.effectiveValue ?? true);

/// Auto-send on/off for one purpose. ON maps to `approval_required: false`,
/// OFF to `approval_required: true`.
class PurposeApprovalRow extends StatelessWidget {
  const PurposeApprovalRow({
    super.key,
    required this.approval,
    required this.value,
    required this.caseScope,
    required this.onChanged,
  });

  final PurposeApproval approval;

  /// Approval being edited at this scope; null means unset or inherited.
  final bool? value;
  final bool caseScope;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final autoSend = autoSendShown(approval, value);
    final state = autoSend ? "자동 발송 켜짐" : "자동 발송 꺼짐";
    final note = value != null && value != approval.ownValue
        ? "저장 후 $state"
        : value == null && approval.effectiveValue == null
        // Nothing to inherit: saving fills the team default (S4-14).
        ? "미설정 · 저장하면 자동 발송 꺼짐으로 정해져요"
        : value == null
        ? caseScope
              ? "메일함 기본값 따름 · $state"
              : "기본값 · 자동 발송 꺼짐"
        : "현재 $state · ${approval.source?.label ?? "출처 미확인"}";
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approval.purpose.label,
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  note,
                  style: const TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "자동 발송",
            style: TextStyle(
              fontSize: AppFontSizes.body,
              fontWeight: FontWeight.w600,
              color: autoSend ? ink : muted,
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: "${approval.purpose.label} 자동 발송",
            child: Switch(
              value: autoSend,
              activeThumbColor: Colors.white,
              activeTrackColor: accent,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: line,
              trackOutlineColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
              onChanged: (on) => onChanged(!on),
            ),
          ),
        ],
      ),
    );
  }
}
