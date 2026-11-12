import "call_recording.dart";
import "voice_file.dart";

/// 업로드가 지금 어느 단계인지.
enum RecordingUploadStep {
  /// 서버에 업로드 자리를 받는 중.
  requesting,

  /// 파일을 저장소로 보내는 중.
  uploading,

  /// 서버가 올라간 파일을 확인하는 중.
  confirming,
}

abstract interface class CallRecordingRepository {
  /// 업무의 녹음 목록과 한도. 기능이 없는 서버는
  /// [CallRecordingFailure.unavailable].
  Future<CallRecordingList> getRecordings(String caseId);

  /// 자리 받기 → 파일 올리기 → 완료 확인. 중간에 실패해
  /// [CallRecordingFailure.retryable]이면 같은 파일·거래처로 다시 부를 때
  /// 같은 녹음을 이어서 올립니다(녹음이 두 개 생기지 않습니다).
  Future<CallRecording> upload({
    required String caseId,
    required String supplierId,
    required VoiceFile file,
    void Function(RecordingUploadStep step)? onStep,
    void Function(int sent, int total)? onProgress,
  });
}
