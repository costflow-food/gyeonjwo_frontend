/// 통화 녹음을 붙일 수 있는 거래처: 이 업무에서 견적 요청이 발송된 업체.
class RecordingSupplier {
  const RecordingSupplier({
    required this.supplierId,
    required this.name,
    required this.email,
    this.replied,
  });

  final String supplierId;
  final String name;
  final String email;

  /// 견적 회신이 들어왔는지. 확인할 수 없으면 null.
  final bool? replied;
}
