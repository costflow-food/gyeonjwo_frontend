import "package:flutter/material.dart";

import "../../../shared/lds_colors.dart";
import "../domain/task_group.dart";

/// 업무 상태 색 한 벌. Dashboard(상태 카드 점·전체 업무 막대)와 Tasks(업무 행·
/// 상세 머리 상태 라벨)가 같은 값을 씁니다. 바꿀 때는 여기만 고칩니다.
abstract final class TaskStatusColors {
  /// 확인 필요(대기·보류): 주황.
  static const confirm = LdsColors.primary;

  /// 진행 중: 노랑.
  static const running = LdsColors.warning;

  /// 완료.
  static const complete = Color(0xFF161716);

  /// 오류: 빨강(확인 필요 묶음 안의 따로 알리는 상태).
  static const error = Color(0xFFE12337);

  /// 상태 묶음별 색(Dashboard).
  static Color ofGroup(TaskGroup group) => switch (group) {
    TaskGroup.confirm => confirm,
    TaskGroup.running => running,
    TaskGroup.complete => complete,
  };

  /// 상태 라벨의 (바탕, 글자). 바탕은 [ofGroup]과 같은 색이고, 글자는 읽기
  /// 좋은 쪽(노랑 위는 먹색 약 9.5:1, 완료 위는 흰색 약 18:1).
  static (Color, Color) ofLabel(TaskLabel label) => switch (label) {
    TaskLabel.waiting || TaskLabel.hold => (confirm, Colors.white),
    TaskLabel.error => (error, Colors.white),
    TaskLabel.running => (running, LdsColors.ink),
    TaskLabel.done => (complete, Colors.white),
  };
}
