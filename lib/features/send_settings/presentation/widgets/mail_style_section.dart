import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../domain/send_settings.dart";

/// Tone and signature. Changes apply to new drafts, never to sent mail.
class MailStyleSection extends StatelessWidget {
  const MailStyleSection({
    super.key,
    required this.tone,
    required this.signature,
    required this.onToneChanged,
    required this.onSignatureChanged,
  });

  final MailTone tone;
  final TextEditingController signature;
  final ValueChanged<MailTone> onToneChanged;
  final ValueChanged<String> onSignatureChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<MailTone>(
          showSelectedIcon: false,
          style: WorkspaceButtonStyles.segmented,
          segments: [
            for (final option in MailTone.values)
              ButtonSegment(value: option, label: Text(option.label)),
          ],
          selected: {tone},
          onSelectionChanged: (selection) => onToneChanged(selection.first),
        ),
        SizedBox(
          width: 260,
          child: TextField(
            controller: signature,
            onChanged: onSignatureChanged,
            style: const TextStyle(fontSize: AppFontSizes.body),
            decoration: const InputDecoration(
              labelText: "서명",
              hintText: "예: 구매팀 드림",
              labelStyle: TextStyle(fontSize: AppFontSizes.body),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
