import "package:flutter/material.dart";

import "../../../shared/lds_colors.dart";
import "../domain/task_group.dart";

/// 업무 상태 색 한 벌. Dashboard(상태 카드 점·전체 업무 막대)와 Tasks(업무 행·
/// 상세 머리 상태 라벨)가 같은 값을 씁니다. 바꿀 때는 여기만 고칩니다.
abstract final class TaskStatusColors {
  /// 확인 필요(대기): 주황. Dashboard의 확인 필요 묶음도 이 색입니다.
  static const confirm = LdsColors.primary;

  /// 보류 라벨 바탕: 연한 살구색(Tasks 상태 라벨에만 씁니다).
  static const hold = Color(0xFFFAE0CE);

  /// 진행 중: 노랑.
  static const running = LdsColors.warning;

  /// 완료: 현대카드 the Green Edition4 '에센셜 그린'(공식 카드 이미지 면의 색).
  static const complete = Color(0xFF3BB553);

  /// 오류: 빨강(확인 필요 묶음 안의 따로 알리는 상태).
  static const error = Color(0xFFE12337);

  /// 상태 묶음별 색(Dashboard).
  static Color ofGroup(TaskGroup group) => switch (group) {
    TaskGroup.confirm => confirm,
    TaskGroup.running => running,
    TaskGroup.complete => complete,
  };

  /// 상태 라벨의 (바탕, 글자). 보류를 뺀 바탕은 [ofGroup]과 같은 색이고,
  /// 글자는 모든 상태가 먹색입니다. 먹색 대비: 보류 살구색 약 13:1, 노랑
  /// 약 9.5:1, 초록 약 6.3:1, 주황 약 5.6:1, 빨강 약 3.4:1.
  static (Color, Color) ofLabel(TaskLabel label) => (
    switch (label) {
      TaskLabel.waiting => confirm,
      TaskLabel.hold => hold,
      TaskLabel.error => error,
      TaskLabel.running => running,
      TaskLabel.done => complete,
    },
    LdsColors.ink,
  );
}
