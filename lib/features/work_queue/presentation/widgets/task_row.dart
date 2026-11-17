import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/task_group.dart";
import "../../domain/task_row_text.dart";
import "../../domain/work_case.dart";

/// 상태 라벨 색 (4.1 weak).
LdsTagTone taskLabelTone(TaskLabel label) => switch (label) {
  TaskLabel.waiting => LdsTagTone.enabled,
  TaskLabel.hold => LdsTagTone.warning,
  TaskLabel.error => LdsTagTone.error,
  TaskLabel.running => LdsTagTone.progressing,
  TaskLabel.done => LdsTagTone.success,
};

/// Tasks 업무 행 = 한 줄형 (`docs/design-ssot.md` 7.13).
///
/// 높이 48, 시작선 40, 오른쪽 12, 칸 사이 6.
/// `[거래처 | 요청 유형 · 구분 | 상태 라벨 56 | 진행도 28]`.
/// 보낸 사람·받은 시각은 화면에 보이지 않게 두고 툴팁·화면 낭독기로 알립니다.
class TaskRow extends StatelessWidget {
  const TaskRow(
    this.workCase, {
    super.key,
    required this.selected,
    required this.onTap,
  });

  static const height = 48.0;

  /// 머리칸 왼쪽 12 + 화살표 18 + 간격 6 + 여백 4.
  static const start = 40.0;

  final WorkCase workCase;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final party = taskPartyOf(workCase);
    final detail = taskDetailOf(workCase);
    final label = taskLabelOf(workCase);
    final progress = taskProgressOf(workCase);
    final received = formatSeoulDateTime(workCase.receivedAt);
    final from = workCase.senderName ?? workCase.sender;
    return Semantics(
      selected: selected,
      button: true,
      label: [
        party,
        detail,
        label.text,
        if (progress != null) "5단계 중 $progress단계",
        "$from, $received 수신",
      ].join(", "),
      excludeSemantics: true,
      child: Tooltip(
        message: "$from · $received 수신",
        waitDuration: const Duration(milliseconds: 600),
        child: Material(
          color: selected ? LdsColors.selectedRow : Colors.white,
          child: InkWell(
            onTap: onTap,
            hoverColor: LdsColors.canvas,
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  if (selected)
                    const Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 3,
                      child: ColoredBox(color: LdsColors.primary),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: start, right: 12),
                    child: Row(
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 88),
                          child: Text(
                            party,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: LdsColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: LdsColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 칸 폭 56. '진행 중'처럼 긴 라벨은 라벨 여백(8)을
                        // 지키느라 조금 넓어집니다.
                        Container(
                          constraints: const BoxConstraints(minWidth: 56),
                          alignment: Alignment.center,
                          child: LdsTag(label.text, tone: taskLabelTone(label)),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 28,
                          child: Text(
                            taskProgressText(progress),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: LdsColors.ink,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
