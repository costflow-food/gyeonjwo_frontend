import "package:flutter/material.dart";

import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/intake_mail.dart";

/// A case the mail may belong to. Shows differences so a shared item name
/// alone does not decide the link.
///
/// 라디오 카드: 머리(라디오 · 업무 제목 · 상태 · 업무 번호) 아래 이름표-값 표
/// (품목 · 필수 조건 · 차이 · 답장 근거). 고른 카드는 주황 2px.
class CaseCandidateTile extends StatelessWidget {
  const CaseCandidateTile({
    super.key,
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final CaseCandidate candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final difference = candidate.difference;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LdsRadius.table),
          side: selected
              ? const BorderSide(color: LdsColors.primary, width: 2)
              : const BorderSide(color: LdsColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LdsRadio<String>(
                      value: candidate.caseId,
                      groupValue: selected ? candidate.caseId : null,
                      onChanged: (_) => onTap(),
                      semanticLabel: candidate.title,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidate.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: LdsColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${candidate.status} · ${candidate.caseId}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: LdsColors.mutedStrong,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 표 바깥 틀은 카드 테두리와 겹치므로 위쪽 선만 둡니다.
            const Divider(height: 1, color: LdsColors.lineSoft),
            _Table(
              rows: [
                if (candidate.itemName != null)
                  LdsKeyValueRow("품목", text: candidate.itemName!),
                if (candidate.conditions != null)
                  LdsKeyValueRow("필수 조건", text: candidate.conditions!),
                if (difference != null)
                  LdsKeyValueRow(
                    "차이",
                    child: Text(
                      difference,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w700,
                        color: LdsColors.errorText,
                      ),
                    ),
                  ),
                LdsKeyValueRow("답장 근거", text: candidate.replyEvidence ?? "없음"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 카드 안 이름표-값 줄(9.1과 같은 칸, 바깥 틀 없이).
class _Table extends StatelessWidget {
  const _Table({required this.rows});

  final List<LdsKeyValueRow> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, row) in rows.indexed) ...[
        if (index > 0) const Divider(height: 1, color: LdsColors.lineSoft),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 112,
                  color: LdsColors.canvas,
                  alignment: Alignment.center,
                  child: Text(
                    row.label,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: LdsColors.label,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child:
                          row.child ??
                          Text(
                            row.text!,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: LdsColors.ink,
                            ),
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}
