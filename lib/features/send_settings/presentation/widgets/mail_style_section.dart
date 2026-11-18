import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/send_settings.dart";

/// 문안·서명: 문체 = Tab round, 서명 = 입력칸.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "문체",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: LdsColors.label,
          ),
        ),
        const SizedBox(height: 8),
        LdsRoundTabs<MailTone>(
          tabs: [
            for (final option in MailTone.values)
              LdsTabItem(value: option, label: option.label),
          ],
          selected: tone,
          onSelected: onToneChanged,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 320,
          child: LdsTextField(
            controller: signature,
            label: "서명",
            hintText: "예: 구매팀 드림",
            onChanged: onSignatureChanged,
          ),
        ),
      ],
    );
  }
}
