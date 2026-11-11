import "package:dio/dio.dart";

import "api_request.dart";

export "api_request.dart" show ApiTokenReader;

/// 조회 실패. `body`는 08 오류 형식(`error.code`, `error.message`)입니다.
class ApiReadException implements Exception {
  const ApiReadException(this.statusCode, this.body);

  /// 0이면 서버에 닿지 못했습니다.
  final int statusCode;
  final Map<String, dynamic> body;

  String? get code =>
      (body["error"] as Map<String, dynamic>?)?["code"] as String?;

  String? get message =>
      (body["error"] as Map<String, dynamic>?)?["message"] as String?;
}

/// 인증된 GET 조회. 세션 갱신·429 대기는 [sendApiRequest]가 맡습니다.
///
/// 조회만 하므로 멱등 키를 보내지 않습니다.
Future<Map<String, dynamic>> authorizedJsonGet(
  Dio dio,
  ApiTokenReader accessToken,
  String path, {
  Map<String, Object?>? queryParameters,
}) async {
  final Map<String, dynamic> body;
  try {
    body = await sendApiRequest(
      accessToken,
      (headers) => dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      ),
    );
  } on ApiException catch (error) {
    throw ApiReadException(error.statusCode, {
      "error": {"code": error.code, "message": error.message},
    });
  }
  if (body["data"] == null) {
    throw const ApiReadException(502, {
      "error": {"code": "INVALID_RESPONSE", "message": "서버 응답을 확인하지 못했습니다."},
    });
  }
  return body;
}
