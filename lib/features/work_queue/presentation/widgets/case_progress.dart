import "package:flutter/material.dart";

import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../domain/case_stage.dart";
import "../../domain/task_group.dart";
import "../../domain/work_case.dart";
import "task_row.dart";

/// 업무 진행 단계 이름. 목록 행의 n/5와 같은 다섯 구간입니다([CaseStage]).
const caseStepLabels = ["요청 확인", "후보 찾기", "견적 요청", "회신", "검토 카드"];

/// Tasks 상세 '진행 상황'의 가로 진행 단계(SSOT 8.2).
///
/// 단계별 시각은 목록 API에 없어 첫 단계에 받은 시각, 지금 단계에 '지금'만
/// 적습니다. 단계를 모르는 업무(처리 오류 등)는 지금 단계를 표시하지 않습니다.
class CaseProgressSteps extends StatelessWidget {
  const CaseProgressSteps({super.key, required this.workCase});

  final WorkCase workCase;

  /// 지금 단계(0부터). 완료(보관)면 단계 수, 모르면 null.
  static int? currentIndex(WorkCase workCase) {
    if (workCase.archived) return CaseStage.total;
    final progress = taskProgressOf(workCase);
    return progress == null ? null : progress - 1;
  }

  @override
  Widget build(BuildContext context) {
    final current = currentIndex(workCase);
    final received = formatSeoulDateTime(workCase.receivedAt);
    return LdsStepBar(
      current: current,
      steps: [
        for (final (index, label) in caseStepLabels.indexed)
          LdsStep(
            label,
            caption: index == current
                ? "지금"
                : index == 0
                ? (received.length > 5 ? received.substring(5) : received)
                : null,
          ),
      ],
    );
  }
}

/// '지금 할 일' 상자 (`docs/design-ssot.md` 7.5).
///
/// 머리: 제목 + 오른쪽에 단계 안 세부 상태 라벨. 몸통에는 지금 있는 처리
/// 화면(수용·다른 대안, 후보 선택, 다시 실행 등)을 그대로 넣습니다. 업무마다
/// 상자 시작 높이와 크기가 같도록 최소 높이를 둡니다(설명 2줄 + 항목 122 +
/// 버튼 줄 36).
class NowToDoBox extends StatelessWidget {
  const NowToDoBox({super.key, required this.workCase, required this.child});

  final WorkCase workCase;
  final Widget child;

  static const minBodyHeight = 15 * 1.6 * 2 + 16 + 122 + 16 + 36;

  @override
  Widget build(BuildContext context) {
    final label = taskLabelOf(workCase);
    final detail = workCase.stepMessage.trim();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: LdsColors.line),
        borderRadius: BorderRadius.circular(LdsRadius.table),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              color: LdsColors.primaryRow,
              border: Border(bottom: BorderSide(color: LdsColors.line)),
            ),
            child: Row(
              children: [
                const Text(
                  "지금 할 일",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: LdsColors.ink,
                  ),
                ),
                const SizedBox(width: 12),
                // 단계 안 세부 상태는 머리 오른쪽(7.5.1).
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: detail.isEmpty
                        ? null
                        : LdsTag(detail, tone: taskLabelTone(label)),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minBodyHeight),
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ],
      ),
    );
  }
}

/// Tasks 상세의 흰 카드(모서리 12): '진행 상황'·'받은 메일'.
class CaseSectionCard extends StatelessWidget {
  const CaseSectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: LdsColors.line),
      borderRadius: BorderRadius.circular(LdsRadius.panel),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: LdsColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 24),
        child,
      ],
    ),
  );
}
