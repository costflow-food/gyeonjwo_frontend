/// 업무에 붙은 통화 녹음 (`/work-cases/{case_id}/call-recordings`).
library;

enum CallRecordingStatus {
  /// 자리만 받았거나 올리는 중. 이 휴대폰이 올리고 있다는 뜻은 아닙니다.
  uploading("UPLOADING", "업로드 미완료"),
  uploaded("UPLOADED", "업로드됨"),
  failed("FAILED", "실패"),
  unknown("", "확인 필요");

  const CallRecordingStatus(this.code, this.label);
  final String code;
  final String label;

  static CallRecordingStatus fromCode(String code) => values.firstWhere(
    (status) => status.code == code && status != unknown,
    orElse: () => unknown,
  );
}

class CallRecording {
  const CallRecording({
    required this.recordingId,
    required this.supplierId,
    required this.fileName,
    required this.extension,
    required this.sizeBytes,
    required this.status,
    required this.createdAt,
    this.failureReason,
    this.uploadedAt,
  });

  final String recordingId;

  /// 견적 요청을 보낸 거래처: 이 통화의 상대.
  final String supplierId;
  final String fileName;
  final String extension;
  final int sizeBytes;
  final CallRecordingStatus status;

  /// `EXPIRED` 또는 `SIZE_MISMATCH`. 실패가 아니면 null.
  final String? failureReason;

  /// UTC ISO 8601.
  final String createdAt;
  final String? uploadedAt;

  /// 실패 사유까지 담은 상태 문구.
  String get statusLabel => switch (failureReason) {
    _ when status != CallRecordingStatus.failed => status.label,
    "EXPIRED" => "기한 만료",
    "SIZE_MISMATCH" => "크기 불일치",
    _ => status.label,
  };
}

/// 업무의 녹음 목록과 서버가 정한 한도.
class CallRecordingList {
  const CallRecordingList({
    required this.items,
    required this.maxPerCase,
    required this.maxBytes,
  });

  /// 최신순.
  final List<CallRecording> items;
  final int maxPerCase;
  final int maxBytes;

  /// 실패한 녹음은 한도에 세지 않습니다.
  bool get limitReached =>
      items.where((item) => item.status != CallRecordingStatus.failed).length >=
      maxPerCase;
}

/// 목록을 읽기 전에 쓰는 파일 크기 한도. 서버 기본값(50MB)과 같습니다.
const defaultMaxRecordingBytes = 52428800;

class CallRecordingFailure implements Exception {
  const CallRecordingFailure(
    this.code,
    this.message, {
    this.unknownOutcome = false,
    this.retryable = false,
  });

  final String code;
  final String message;

  /// 서버가 처리했는지 알 수 없습니다. 같은 요청으로 다시 확인합니다.
  final bool unknownOutcome;

  /// 다시 누르면 같은 녹음으로 이어서 올립니다.
  final bool retryable;

  /// 서버에 통화 녹음 기능이 아직 없거나 꺼져 있습니다.
  bool get unavailable => code == "CALL_RECORDING_UNAVAILABLE";

  /// 고른 거래처나 업무가 더는 맞지 않습니다: 거래처 목록을 다시 읽습니다.
  bool get suppliersChanged => const {
    "CALL_RECORDING_SUPPLIER_NOT_ALLOWED",
    "CALL_RECORDING_CASE_NOT_FOUND",
  }.contains(code);

  @override
  String toString() => "CallRecordingFailure($code)";
}
