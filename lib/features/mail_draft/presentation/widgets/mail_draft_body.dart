import "package:flutter/material.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/mail_draft.dart";

/// Recipient, subject, and text. Editable only while [editing].
class MailDraftBody extends StatelessWidget {
  const MailDraftBody({
    super.key,
    required this.draft,
    required this.editing,
    required this.recipient,
    required this.subject,
    required this.body,
    required this.editReason,
  });

  final MailDraft draft;
  final bool editing;
  final TextEditingController recipient;
  final TextEditingController subject;
  final TextEditingController body;
  final TextEditingController editReason;

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReadOnlyLine("받는 사람", draft.recipient),
            _ReadOnlyLine("제목", draft.subject),
            const Divider(color: line, height: 24),
            SelectableText(
              draft.body,
              style: const TextStyle(fontSize: AppFontSizes.bodyLarge, height: 1.6),
            ),
          ],
        ),
      );
    }
    InputDecoration decoration(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: AppFontSizes.body),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
    );
    const style = TextStyle(fontSize: AppFontSizes.body);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: recipient,
          style: style,
          keyboardType: TextInputType.emailAddress,
          decoration: decoration("받는 사람"),
          validator: (value) =>
              RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(value?.trim() ?? "")
              ? null
              : "이메일 형식을 확인해 주세요.",
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: subject,
          style: style,
          decoration: decoration("제목"),
          validator: (value) =>
              (value?.trim().isEmpty ?? true) ? "제목을 입력해 주세요." : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: body,
          style: const TextStyle(fontSize: AppFontSizes.body, height: 1.5),
          minLines: 8,
          maxLines: 16,
          decoration: decoration("본문"),
          validator: (value) =>
              (value?.trim().isEmpty ?? true) ? "본문을 입력해 주세요." : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: editReason,
          style: style,
          decoration: decoration(
            "수정 사유",
            hint: "예: 수신자 주소 정정, 표현 수정",
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyLine extends StatelessWidget {
  const _ReadOnlyLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSizes.secondary,
                color: muted,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
