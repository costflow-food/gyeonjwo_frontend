class AnalysisStopReason {
  const AnalysisStopReason({
    required this.stage,
    required this.itemLabel,
    required this.itemTitle,
    required this.itemDescription,
  });

  final String stage;
  final String itemLabel;
  final String itemTitle;
  final String itemDescription;

  static const packagingSpec = AnalysisStopReason(
    stage: '검토 필요 · 포장 규격 확인 단계',
    itemLabel: '확인이 필요한 항목',
    itemTitle: '비교 가능한 품목 규격',
    itemDescription: '냉동·무냉동 여부와 포장 규격을 확인할 수 없습니다.',
  );
}
