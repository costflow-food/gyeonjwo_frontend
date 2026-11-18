import "package:flutter/material.dart";

import "../../../../shared/widgets/lds/lds.dart";

/// configured=false: the server has no stored value for some purposes yet.
/// The dialog shows them as the default (auto-send off) until saved.
class SettingsMissingBanner extends StatelessWidget {
  const SettingsMissingBanner({
    super.key,
    required this.missingItems,
    required this.caseScope,
  });

  final List<String> missingItems;
  final bool caseScope;

  @override
  Widget build(BuildContext context) {
    final items = missingItems.join(", ");
    return LdsNotice(
      tone: LdsNoticeTone.warning,
      icon: Icons.warning_amber_rounded,
      message: caseScope
          ? "메일함 기본값이 아직 저장되지 않았습니다 · $items. 메일함 발송 설정을 저장하면 기본값(자동 발송 꺼짐)이 적용됩니다."
          : "아직 저장되지 않은 항목이 있습니다 · $items. 기본값(자동 발송 꺼짐)으로 표시했으며, 저장하면 적용됩니다.",
    );
  }
}
