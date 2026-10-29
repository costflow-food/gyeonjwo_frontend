import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../source_document/presentation/source_document_dialog.dart";

/// Opens SCR-004 above the current dialog; closing it returns here.
class SourceMailButton extends StatelessWidget {
  const SourceMailButton({super.key, required this.mailId});
  final String mailId;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      // SCR-004 still looks up by request ID; switch to the API-25 mail_id later.
      onPressed: () => showSourceDocument(context, requestId: mailId),
      icon: const Icon(Icons.mail_outline, size: 14),
      label: const Text(
        "원문 보기",
        style: TextStyle(fontSize: AppFontSizes.caption),
      ),
      style: TextButton.styleFrom(
        foregroundColor: accent,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
