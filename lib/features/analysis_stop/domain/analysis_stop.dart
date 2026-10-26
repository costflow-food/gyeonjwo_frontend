/// Temporary app models for SCR-006; these do not prescribe database tables.
///
/// 분석 중단 사유는 현재 실행 응답(`outcome=REVIEW_REQUIRED`)에만 담기며
/// DB에 저장하지 않습니다(08 API 명세 · 09 화면 흐름도).
class AnalysisStop {
  AnalysisStop({
    required this.requestId,
    required this.stageLabel,
    required this.summary,
    required this.guidance,
    required List<StopIssue> issues,
  }) : issues = List.unmodifiable(issues);

  final String requestId, stageLabel, summary, guidance;
  final List<StopIssue> issues;
}

/// 08 API 명세의 `issues` 항목 하나. 화면에는 [label]과 [message]를 보여 줍니다.
class StopIssue {
  const StopIssue({
    required this.code,
    required this.label,
    required this.message,
    required this.sourceLocation,
  });

  final String code, label, message, sourceLocation;
}
