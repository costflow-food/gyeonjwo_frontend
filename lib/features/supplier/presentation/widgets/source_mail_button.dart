import "package:flutter/material.dart";

import "../../../../shared/widgets/lds/lds.dart";
import "../../../source_document/presentation/source_document_dialog.dart";

/// '원문 보기': 작은 테두리 버튼(메일 아이콘).
class SourceMailButton extends StatelessWidget {
  const SourceMailButton({super.key, required this.mailId});
  final String mailId;

  @override
  Widget build(BuildContext context) => LdsButton(
    label: "원문 보기",
    icon: Icons.mail_outline,
    size: LdsButtonSize.small,
    variant: LdsButtonVariant.outlinedNeutral,
    onPressed: () => showSourceDocument(context, requestId: mailId),
  );
}
