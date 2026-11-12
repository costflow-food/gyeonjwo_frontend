import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/idempotency_key.dart";
import "../../../shared/network/api_request.dart";
import "../domain/call_recording.dart";
import "../domain/call_recording_repository.dart";
import "../domain/voice_file.dart";
import "call_recording_data_source.dart";
import "recording_file_uploader.dart";

// Kept alive: it owns the idempotency keys of unfinished uploads.
final callRecordingRepositoryProvider = Provider<CallRecordingRepository>(
  (ref) => CallRecordingRepositoryImpl(
    ref.watch(callRecordingDataSourceProvider),
    ref.watch(recordingFileUploaderProvider),
  ),
);

// A failed read shows its error and 다시 시도 at once, like the other screens.
Duration? _noRetry(int retryCount, Object error) => null;

/// 업무의 녹음 목록. 업로드가 끝나면 invalidate합니다.
final callRecordingsProvider = FutureProvider.autoDispose
    .family<CallRecordingList, String>(
      (ref, caseId) =>
          ref.watch(callRecordingRepositoryProvider).getRecordings(caseId),
      retry: _noRetry,
    );

class CallRecordingRepositoryImpl implements CallRecordingRepository {
  CallRecordingRepositoryImpl(
    this._dataSource,
    this._uploader, {
    DateTime Function()? now,
  }) : _keys = IdempotencyKeys(lifetime: uploadKeyLifetime, now: now);

  /// As long as the server lets an upload continue, not the usual 10 minutes:
  /// a slow upload or a late retry must still reach the same recording. A
  /// replay answers with the recording's current state, never a stored one.
  static const uploadKeyLifetime = Duration(hours: 2);

  final CallRecordingDataSource _dataSource;
  final RecordingFileUploader _uploader;
  final IdempotencyKeys _keys;

  @override
  Future<CallRecordingList> getRecordings(String caseId) => _guard(() async {
    final response = await _dataSource.fetchRecordings(caseId);
    final data = response["data"] as Map<String, dynamic>;
    final limits = data["limits"] as Map<String, dynamic>;
    return CallRecordingList(
      items: [
        for (final item in data["items"] as List)
          _recording(item as Map<String, dynamic>),
      ],
      maxPerCase: limits["max_per_case"] as int,
      maxBytes: limits["max_bytes"] as int,
    );
  });

  @override
  Future<CallRecording> upload({
    required String caseId,
    required String supplierId,
    required VoiceFile file,
    void Function(RecordingUploadStep step)? onStep,
    void Function(int sent, int total)? onProgress,
  }) {
    final size = file.sizeBytes;
    if (size == null || size < 1) {
      return Future.error(
        const CallRecordingFailure(
          "FILE_SIZE_UNKNOWN",
          "파일 크기를 확인하지 못했습니다. 다른 파일을 골라 주세요.",
        ),
      );
    }
    // The server keys the recording on this exact body: a retry with the
    // same file and supplier continues the same recording.
    final body = <String, Object?>{
      "supplier_id": supplierId,
      "file_name": file.name,
      "extension": file.extension,
      "size_bytes": size,
    };
    // The whole sequence runs under one key. The key is dropped only when it
    // ends or the server definitely refused, so a retry after a broken upload
    // re-asks with the same key and gets a fresh URL for the same recording.
    // One kept key per file and supplier: trying another in between must not
    // forget this one's unfinished upload.
    return _keys.run(
      "recording:$caseId:$supplierId:$size:${file.name}",
      body,
      (key) => _guard(
        () => _upload(caseId, body, key, file, size, onStep, onProgress),
      ),
      serverCode: (error) =>
          error is CallRecordingFailure && !error.retryable ? error.code : null,
    );
  }

  Future<CallRecording> _upload(
    String caseId,
    Map<String, Object?> body,
    String key,
    VoiceFile file,
    int size,
    void Function(RecordingUploadStep step)? onStep,
    void Function(int sent, int total)? onProgress,
  ) async {
    onStep?.call(RecordingUploadStep.requesting);
    final created = await _dataSource.createRecording(
      caseId,
      body,
      idempotencyKey: key,
    );
    final data = created["data"] as Map<String, dynamic>;
    final recording = _recording(data);
    switch (recording.status) {
      // An earlier try already finished; only its answer was lost.
      case CallRecordingStatus.uploaded:
        return recording;
      // Not retryable, so the next press starts a new recording.
      case CallRecordingStatus.failed:
        throw const CallRecordingFailure(
          "CALL_RECORDING_FAILED",
          "이 녹음은 올리지 못한 채 끝났습니다. 다시 눌러 새로 올려 주세요.",
        );
      case CallRecordingStatus.uploading || CallRecordingStatus.unknown:
    }

    // Null when the upload window has passed: the server decides below.
    final target = data["upload"];
    if (target is Map<String, dynamic>) {
      onStep?.call(RecordingUploadStep.uploading);
      try {
        await _uploader.upload(
          url: target["url"] as String,
          contentType: target["content_type"] as String,
          length: size,
          open: file.openRead,
          onProgress: onProgress,
        );
      } on RecordingUploadFailed catch (failure) {
        if (failure.unreadable) {
          // Retryable so the key stays: picking the same file again
          // continues this recording.
          throw const CallRecordingFailure(
            "FILE_UNREADABLE",
            "파일을 읽지 못했습니다. 파일을 다시 골라 주세요.",
            retryable: true,
          );
        }
        if (failure.statusCode == null) {
          throw const CallRecordingFailure(
            "UPLOAD_INTERRUPTED",
            "파일을 올리는 중 연결이 끊겼습니다. 다시 시도해 주세요.",
            retryable: true,
          );
        }
        // The storage refused. It does not overwrite, so the file may already
        // be there from a try whose answer was lost: let the server check.
      }
    }

    onStep?.call(RecordingUploadStep.confirming);
    try {
      final completed = await _dataSource.completeRecording(
        caseId,
        recording.recordingId,
      );
      return _recording(completed["data"] as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.code == "CALL_RECORDING_UPLOAD_INCOMPLETE") {
        // The file is not there: the same recording takes another upload.
        throw const CallRecordingFailure(
          "CALL_RECORDING_UPLOAD_INCOMPLETE",
          "파일을 올리지 못했습니다. 다시 시도해 주세요.",
          retryable: true,
        );
      }
      rethrow;
    }
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException catch (error) {
      throw CallRecordingFailure(
        error.code,
        error.message,
        unknownOutcome: error.unknownOutcome,
        retryable: error.retryable,
      );
    } on CallRecordingFailure {
      rethrow;
    } catch (_) {
      throw const CallRecordingFailure(
        "INVALID_RESPONSE",
        "서버 응답을 확인하지 못했습니다.",
      );
    }
  }

  static CallRecording _recording(Map<String, dynamic> json) => CallRecording(
    recordingId: json["recording_id"] as String,
    supplierId: json["supplier_id"] as String,
    fileName: json["file_name"] as String,
    extension: json["extension"] as String,
    sizeBytes: json["size_bytes"] as int,
    status: CallRecordingStatus.fromCode(json["status"] as String),
    failureReason: json["failure_reason"] as String?,
    createdAt: json["created_at"] as String,
    uploadedAt: json["uploaded_at"] as String?,
  );
}
