import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/mail_draft.dart";

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
      // 받는 사람·제목 = 이름표-값 표, 본문은 아래 상자.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LdsKeyValueTable(
            labelWidth: 96,
            rows: [
              LdsKeyValueRow(
                "받는 사람",
                child: SelectableText(draft.recipient, style: _value),
              ),
              LdsKeyValueRow(
                "제목",
                child: SelectableText(
                  draft.subject,
                  style: _value.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: LdsColors.line),
              borderRadius: BorderRadius.circular(LdsRadius.table),
            ),
            child: SelectableText(draft.body, style: _value),
          ),
        ],
      );
    }
    // LDS 입력칸 테두리(7.14b): 1px `#D1D6DC`, 초점 `#333D4B`, 오류 빨강, 모서리 4.
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(LdsRadius.button),
      borderSide: BorderSide(color: color),
    );
    InputDecoration decoration(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 14, color: LdsColors.label),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: border(LdsColors.borderStrong),
      focusedBorder: border(LdsColors.title),
      errorBorder: border(LdsColors.error),
      focusedErrorBorder: border(LdsColors.error),
      errorStyle: const TextStyle(fontSize: 13, color: LdsColors.errorText),
    );
    const style = TextStyle(fontSize: 15, color: LdsColors.ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: recipient,
          style: style,
          keyboardType: TextInputType.emailAddress,
          decoration: decoration("받는 사람"),
          validator: (value) =>
              RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")
                  .hasMatch(value?.trim() ?? "")
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
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: LdsColors.ink,
          ),
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
          decoration: decoration("수정 사유", hint: "예: 수신자 주소 정정, 표현 수정"),
          validator: (value) =>
              (value?.trim().isEmpty ?? true) ? "수정 사유를 입력해 주세요." : null,
        ),
      ],
    );
  }
}

const _value = TextStyle(fontSize: 15, height: 1.6, color: LdsColors.ink);
