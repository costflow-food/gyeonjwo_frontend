import "package:flutter/foundation.dart";

/// `/ready`의 일부 기능 코드(degraded_features). 이 목록에 없는 코드는 무시합니다.
enum ServerFeature {
  /// 그래프 워커가 없어 검토를 시작할 수 없음.
  review("review", "검토 실행"),

  /// 회신이 연결돼도 회신 검토(③④⑤)를 실행하지 못함.
  reviewReply("review_reply", "거래처 회신 검토"),

  /// 구매안 선택·보류 같은 최종 판단을 저장하지 못함.
  finalDecision("final_decision", "구매안 확정·보류 저장"),

  /// 보낸 견적 요청을 기록하지 못해 회신이 업무에 자동으로 연결되지 않을 수 있음.
  rfqMetadata("rfq_metadata", "거래처 회신 자동 연결"),

  /// 발송 워커가 꺼져 승인하거나 자동 발송해도 메일이 나가지 않음.
  /// BE가 이 코드를 보내기 시작하면 바로 표시됩니다.
  rfqDispatch("rfq_dispatch", "견적 요청 메일 발송");

  const ServerFeature(this.code, this.label);
  final String code;
  final String label;
}

/// 서버가 지금 무엇을 할 수 있는지(`GET /ready`).
///
/// 서버에 닿지 못했거나 응답을 이해하지 못하면 [unknown]으로 두고 아무것도 안내하지
/// 않습니다.
class ServerStatus {
  const ServerStatus({this.notReady = false, this.degraded});

  static const unknown = ServerStatus();

  /// 503: 설정·DB·메일 수신 워커 중 하나가 준비되지 않음.
  final bool notReady;

  /// 200일 때 준비되지 않은 기능. null이면 확인하지 못했습니다.
  final Set<ServerFeature>? degraded;

  bool get showReviewBanner =>
      notReady || (degraded?.contains(ServerFeature.review) ?? false);

  /// 검토 실행은 되지만 막혀 있는 기능. [showReviewBanner]일 때는 비웁니다.
  List<ServerFeature> get limitedFeatures => showReviewBanner
      ? const []
      : [
          for (final feature in ServerFeature.values)
            if (feature != ServerFeature.review &&
                (degraded?.contains(feature) ?? false))
              feature,
        ];

  /// 회신을 받아도 검토로 이어지지 않는 상태. '거래처 회신 확인 중' 업무에 함께 알립니다.
  bool get replyReviewBlocked =>
      showReviewBanner ||
      (degraded?.contains(ServerFeature.reviewReply) ?? false);

  @override
  bool operator ==(Object other) =>
      other is ServerStatus &&
      other.notReady == notReady &&
      setEquals(other.degraded, degraded);

  @override
  int get hashCode => Object.hash(
    notReady,
    degraded == null ? null : Object.hashAllUnordered(degraded!),
  );
}
