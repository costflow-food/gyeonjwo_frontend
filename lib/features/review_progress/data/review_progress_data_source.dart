import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/network/api_request.dart";
import "../../auth/data/auth_session_data_source.dart";

part "review_progress_data_source.g.dart";

@Riverpod(keepAlive: true)
ReviewProgressDataSource reviewProgressDataSource(Ref ref) =>
    ApiReviewProgressDataSource(
      ref.watch(apiClientProvider),
      ref.watch(authSessionDataSourceProvider).freshAccessToken,
    );

/// API-03 `GET /work-cases/{case_id}/progress`. 조회만 하며 업무를 바꾸지 않습니다.
abstract interface class ReviewProgressDataSource {
  Future<Map<String, dynamic>> fetchProgress(String caseId);
}

class ApiReviewProgressDataSource implements ReviewProgressDataSource {
  const ApiReviewProgressDataSource(this._dio, this._accessToken);

  static const _cases = "/api/v1/work-cases";

  final Dio _dio;
  final ApiTokenReader _accessToken;

  /// 세션 갱신·429 대기·오류 변환은 [sendApiRequest]가 맡습니다.
  @override
  Future<Map<String, dynamic>> fetchProgress(String caseId) => sendApiRequest(
    _accessToken,
    (headers) => _dio.get<Map<String, dynamic>>(
      "$_cases/$caseId/progress",
      options: Options(headers: headers),
    ),
  );
}
