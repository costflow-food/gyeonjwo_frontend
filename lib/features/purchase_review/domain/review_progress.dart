/// Temporary app model; independent of the eventual database schema.
class ReviewProgress {
  const ReviewProgress({
    required this.completedSteps,
    required this.totalSteps,
    required this.synthetic,
  });

  final int completedSteps, totalSteps;

  /// 합성 시연 응답이면 true. 화면은 이 값으로 시연 문구 표시 여부를 정합니다.
  final bool synthetic;

  bool get isComplete => completedSteps >= totalSteps;
}
