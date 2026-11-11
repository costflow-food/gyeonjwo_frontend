import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../source_document/presentation/source_document_dialog.dart";

class SourceMailButton extends StatelessWidget {
  const SourceMailButton({super.key, required this.mailId});
  final String mailId;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showSourceDocument(context, requestId: mailId),
      icon: const Icon(Icons.mail_outline, size: 14),
      label: const Text(
        "원문 보기",
        style: TextStyle(fontSize: AppFontSizes.caption),
      ),
      style: TextButton.styleFrom(
        foregroundColor: context.palette.accentText,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
