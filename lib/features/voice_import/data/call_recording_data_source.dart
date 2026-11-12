import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/network/api_request.dart";
import "../../auth/data/auth_session_data_source.dart";

final callRecordingDataSourceProvider = Provider<CallRecordingDataSource>(
  (ref) => ApiCallRecordingDataSource(
    ref.watch(apiClientProvider),
    ref.watch(authSessionDataSourceProvider).freshAccessToken,
  ),
);

/// `POST /work-cases/{case_id}/call-recordings` (업로드 자리),
/// `POST /work-cases/{case_id}/call-recordings/{recording_id}/complete`,
/// `GET /work-cases/{case_id}/call-recordings`,
/// `DELETE /work-cases/{case_id}/call-recordings/{recording_id}`.
abstract interface class CallRecordingDataSource {
  /// [body]: `supplier_id`, `file_name`, `extension`, `size_bytes`.
  Future<Map<String, dynamic>> createRecording(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  /// Repeat-safe on the server; takes no key.
  Future<Map<String, dynamic>> completeRecording(
    String caseId,
    String recordingId,
  );

  Future<Map<String, dynamic>> fetchRecordings(String caseId);

  /// Repeat-safe on the server (a recording already gone is a success);
  /// takes no key and answers without a body.
  Future<void> deleteRecording(String caseId, String recordingId);
}

class ApiCallRecordingDataSource implements CallRecordingDataSource {
  const ApiCallRecordingDataSource(this._dio, this._accessToken);

  static const _cases = "/api/v1/work-cases";

  final Dio _dio;
  final ApiTokenReader _accessToken;

  @override
  Future<Map<String, dynamic>> createRecording(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "$_cases/$caseId/call-recordings",
      data: body,
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Map<String, dynamic>> completeRecording(
    String caseId,
    String recordingId,
  ) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "$_cases/$caseId/call-recordings/$recordingId/complete",
      options: Options(headers: headers),
    ),
  );

  @override
  Future<Map<String, dynamic>> fetchRecordings(String caseId) => _send(
    (headers) => _dio.get<Map<String, dynamic>>(
      "$_cases/$caseId/call-recordings",
      options: Options(headers: headers),
    ),
  );

  @override
  Future<void> deleteRecording(String caseId, String recordingId) =>
      _send((headers) async {
        final response = await _dio.delete<void>(
          "$_cases/$caseId/call-recordings/$recordingId",
          options: Options(headers: headers),
        );
        // 204 has no body, which the shared sender reads as a broken answer.
        return Response<bool>(
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          data: true,
        );
      });

  Future<T> _send<T>(
    Future<Response<T>> Function(Map<String, String> headers) request, {
    String? idempotencyKey,
  }) async {
    try {
      return await sendApiRequest(
        _accessToken,
        request,
        idempotencyKey: idempotencyKey,
      );
    } on ApiException catch (error) {
      // A server without these routes answers a plain 404; a missing case or
      // recording has its own CALL_RECORDING_* code.
      if (error.statusCode == 404 &&
          const {"RESOURCE_NOT_FOUND", "HTTP_404"}.contains(error.code)) {
        throw const ApiException(
          404,
          "CALL_RECORDING_UNAVAILABLE",
          "통화 녹음 기능을 사용할 수 없습니다.",
        );
      }
      rethrow;
    }
  }
}
