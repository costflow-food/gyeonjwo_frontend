enum HitlStatus {
  waiting('검토 대기'),
  held('보류'),
  approved('승인 완료'),
  returned('수정 요청');

  const HitlStatus(this.label);
  final String label;
  bool get actionable => this == waiting || this == held;
}

enum HitlKind {
  information('정보 확인'),
  purchase('구매안 검토'),
  send('발송 승인');

  const HitlKind(this.label);
  final String label;
}

class HitlRequest {
  const HitlRequest({
    required this.id,
    required this.kind,
    required this.title,
    required this.supplier,
    required this.item,
    required this.reason,
    required this.proposal,
    required this.effect,
    required this.facts,
    required this.source,
    required this.valueLabel,
    required this.value,
    this.status = HitlStatus.waiting,
    this.note = '',
    this.history = const ['AI가 검토 요청을 생성했습니다. (시연)'],
  });

  final String id, title, supplier, item, reason, proposal, effect, source;
  final String valueLabel, value, note;
  final HitlKind kind;
  final HitlStatus status;
  final Map<String, String> facts;
  final List<String> history;

  HitlRequest decide(HitlStatus next, String comment, String correctedValue) =>
      HitlRequest(
        id: id,
        kind: kind,
        title: title,
        supplier: supplier,
        item: item,
        reason: reason,
        proposal: proposal,
        effect: effect,
        facts: facts,
        source: source,
        valueLabel: valueLabel,
        value: correctedValue,
        status: next,
        note: comment,
        history: [
          ...history,
          '담당자: ${next.label} (시연)${comment.isEmpty ? '' : ' · $comment'}',
        ],
      );
}
