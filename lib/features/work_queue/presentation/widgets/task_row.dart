import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/app_icons.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/case_stage.dart";
import "../../domain/task_group.dart";
import "../../domain/task_row_text.dart";
import "../../domain/work_case.dart";

/// 상태 라벨 색 (4.1 weak): 대기 주황 · 진행 중 파랑 · 보류 노랑 · 오류 빨강 ·
/// 완료 초록.
LdsTagTone taskLabelTone(TaskLabel label) => switch (label) {
  TaskLabel.waiting => LdsTagTone.enabled,
  TaskLabel.hold => LdsTagTone.warning,
  TaskLabel.error => LdsTagTone.error,
  TaskLabel.running => LdsTagTone.progressing,
  TaskLabel.done => LdsTagTone.success,
};

/// 업무 행의 상태 라벨(채운 색): 진행 중 연주황 + 먹색 글자 · 보류 주황 +
/// 흰 글자 · 오류 빨강 + 흰 글자 · 완료 아주 연한 살구(`#FFEBE5`) + 먹색 글자 ·
/// 대기 주황 + 흰 글자.
/// 업무 행과 상세 머리가 같이 씁니다([TaskStatusLabel]).
(Color, Color) taskRowLabelColors(TaskLabel label) => switch (label) {
  TaskLabel.running => (const Color(0xFFFFA066), LdsColors.ink),
  TaskLabel.hold => (LdsColors.primary, Colors.white),
  TaskLabel.error => (const Color(0xFFE12337), Colors.white),
  // 밝은 살구 바탕 + 먹색 글자(대비 약 14:1).
  TaskLabel.done => (const Color(0xFFFFEBE5), LdsColors.ink),
  TaskLabel.waiting => (LdsColors.primary, Colors.white),
};

/// 업무 상태 라벨(채운 색, [taskRowLabelColors]): 높이 24, 최소 폭 56, 좌우 8,
/// 모서리 4, 13px/700. Tasks 업무 행과 상세 머리가 같이 씁니다.
class TaskStatusLabel extends StatelessWidget {
  const TaskStatusLabel(this.label, {super.key});

  final TaskLabel label;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = taskRowLabelColors(label);
    return Container(
      constraints: const BoxConstraints(minWidth: 64),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      // 글자 길이만큼(최소 64). alignment를 쓰면 Wrap 안에서 폭 전체로 늘어납니다.
      child: Center(
        widthFactor: 1,
        child: Text(
          label.text,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

/// Tasks 업무 행 = 한 줄형 (`docs/design-ssot.md` 7.13, 2026-11-18 시안).
///
/// 높이 48, 시작선 40, 오른쪽 12.
/// `[가게 아이콘 16 · 거래처 | 지금 단계 이름 | 채운 상태 라벨]`.
/// 고른 줄 = 바탕 `#E8EBEF` + 왼쪽 `#4E5968` 3px, 거래처 이름만 굵게.
/// 요청 유형·보낸 사람·받은 시각은 화면에 보이지 않게 두고 툴팁·화면
/// 낭독기로 알립니다.
class TaskRow extends StatelessWidget {
  const TaskRow(
    this.workCase, {
    super.key,
    required this.selected,
    required this.onTap,
  });

  static const height = 48.0;

  /// 머리칸 왼쪽 12 + 화살표 18 + 간격 6 + 여백 4.
  static const start = 16.0;

  /// 거래처 칸(아이콘 포함) 폭: 단계 이름이 줄마다 같은 선에서 시작합니다.
  static const partyWidth = 128.0;

  static const selectedColor = Color(0xFFE8EBEF);
  static const selectedBar = LdsColors.title;

  final WorkCase workCase;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final party = taskPartyOf(workCase);
    final detail = taskDetailOf(workCase);
    final label = taskLabelOf(workCase);
    final progress = taskProgressOf(workCase);
    final stepName = progress == null ? "" : caseStepNames[progress - 1];
    final received = formatSeoulDateTime(workCase.receivedAt);
    final from = workCase.senderName ?? workCase.sender;
    return Semantics(
      selected: selected,
      button: true,
      label: [
        party,
        if (stepName.isNotEmpty) stepName,
        label.text,
        detail,
        "$from, $received 수신",
      ].join(", "),
      excludeSemantics: true,
      child: Tooltip(
        message: "$detail · $from · $received 수신",
        waitDuration: const Duration(milliseconds: 600),
        child: Material(
          color: selected ? selectedColor : Colors.white,
          child: InkWell(
            onTap: onTap,
            hoverColor: LdsColors.canvas,
            child: SizedBox(
              height: height,
              child: Stack(
                // 줄 내용은 세로 가운데(기본값 위쪽 붙음을 막음).
                alignment: AlignmentDirectional.centerStart,
                children: [
                  if (selected)
                    const Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 3,
                      child: ColoredBox(color: selectedBar),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: start, right: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: partyWidth,
                          child: Row(
                            children: [
                              const AppIconView(
                                AppIcon.suppliers,
                                size: 16,
                                color: LdsColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  party,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: LdsColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            stepName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: LdsColors.label,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(width: 64, child: TaskStatusLabel(label)),
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
