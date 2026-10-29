import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/send_settings.dart";

/// Unset, approval ON, or approval OFF for one purpose. Unset never shows a
/// default ON/OFF because the team has not decided one.
class PurposeApprovalRow extends StatelessWidget {
  const PurposeApprovalRow({
    super.key,
    required this.approval,
    required this.value,
    required this.caseScope,
    required this.onChanged,
  });

  final PurposeApproval approval;

  /// Value being edited at this scope; null means unset or inherited.
  final bool? value;
  final bool caseScope;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final source = approval.source;
    final effective = approval.effectiveValue;
    final note = value != approval.ownValue
        ? value == null
              ? (caseScope ? '저장 후 메일함 기본값 적용' : '미설정으로 저장')
              : '저장 후 승인 ${value! ? 'ON' : 'OFF'} 적용'
        : effective == null
        ? "설정 필요"
        : "현재 ${effective ? "승인 ON" : "승인 OFF"} · ${source?.label ?? "출처 미확인"}";
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 150,
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
                  style: TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: effective == null ? const Color(0xFFBC793C) : muted,
                  ),
                ),
              ],
            ),
          ),
          SegmentedButton<int>(
            showSelectedIcon: false,
            style: WorkspaceButtonStyles.segmented,
            segments: [
              ButtonSegment(
                value: 0,
                label: Text(caseScope ? "메일함 기본값 따름" : "미설정"),
              ),
              const ButtonSegment(value: 1, label: Text("승인 필요 (ON)")),
              const ButtonSegment(value: 2, label: Text("자동 발송 (OFF)")),
            ],
            selected: {
              switch (value) {
                null => 0,
                true => 1,
                false => 2,
              },
            },
            onSelectionChanged: (selection) =>
                onChanged(switch (selection.first) {
                  1 => true,
                  2 => false,
                  _ => null,
                }),
          ),
        ],
      ),
    );
  }
}
