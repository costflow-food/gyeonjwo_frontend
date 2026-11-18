import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/intake_mail.dart";
import "case_candidate_tile.dart";
import "intake_reason_badge.dart";

/// 고른 메일: Tasks 상세와 같은 구성. 제목 20/700 · 메타 줄 → '연결할 업무
/// 고르기' 카드(이유 · 후보 라디오 카드 · 확인 사유) → '받은 메일' 카드 → 첨부.
class IntakeMailDetail extends StatelessWidget {
  const IntakeMailDetail({
    super.key,
    required this.mail,
    required this.selectedCaseId,
    required this.onSelectCase,
    required this.reason,
  });

  final IntakeMail mail;
  final String? selectedCaseId;
  final ValueChanged<String> onSelectCase;
  final TextEditingController reason;

  static const _muted = TextStyle(fontSize: 13, color: LdsColors.mutedStrong);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectableText(
          mail.subject,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: LdsColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IntakeReasonBadge(mail.reason),
            Text(mail.sender, style: _muted),
            Text("접수 ${formatSeoulDateTime(mail.receivedAt)}", style: _muted),
          ],
        ),
        const SizedBox(height: 20),
        _Card(
          title: "연결할 업무 고르기",
          trailing: mail.candidates.isEmpty
              ? "연결 후보 업무 없음"
              : "후보 ${mail.candidates.length}건",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                mail.reasonDetail,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: LdsColors.title,
                ),
              ),
              const SizedBox(height: 16),
              for (final candidate in mail.candidates)
                CaseCandidateTile(
                  candidate: candidate,
                  selected: candidate.caseId == selectedCaseId,
                  onTap: () => onSelectCase(candidate.caseId),
                ),
              const SizedBox(height: 4),
              LdsTextField(
                controller: reason,
                label: "확인 사유 (선택)",
                hintText: "예: 회신 규격이 달라 새 업무로 접수",
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          title: "받은 메일",
          child: SelectableText(
            mail.bodyText,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: LdsColors.ink,
            ),
          ),
        ),
        if (mail.attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Card(
            title: "첨부",
            trailing: "${mail.attachments.length}개",
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in mail.attachments)
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: LdsColors.line),
                      borderRadius: BorderRadius.circular(LdsRadius.button),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.attach_file,
                          size: 16,
                          color: LdsColors.mutedStrong,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: LdsColors.title,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 카드 섹션: 흰 패널, 제목 17/700 + 오른쪽 보조 글, 아래 구분선.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => LdsPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: LdsColors.ink,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 13,
                  color: LdsColors.mutedStrong,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: LdsColors.lineSoft),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}
