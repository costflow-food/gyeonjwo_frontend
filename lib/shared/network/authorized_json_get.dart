import "package:dio/dio.dart";

/// Reads the current access token; `forceRefresh` refreshes the session first.
typedef ApiTokenReader = Future<String?> Function({bool forceRefresh});

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

/// 인증된 GET 조회. 만료된 세션은 한 번 갱신해 다시 보냅니다.
///
/// 조회만 하므로 멱등 키를 보내지 않습니다. DioException은 요청 헤더(토큰)를
/// 담고 있어 그대로 던지지 않고 [ApiReadException]으로 바꿉니다.
Future<Map<String, dynamic>> authorizedJsonGet(
  Dio dio,
  ApiTokenReader accessToken,
  String path, {
  Map<String, Object?>? queryParameters,
}) async {
  for (final forceRefresh in const [false, true]) {
    final token = await accessToken(forceRefresh: forceRefresh);
    if (token == null) throw _authRequired;
    try {
      final response = await dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      final body = response.data;
      if (body == null || body["data"] == null) {
        throw const ApiReadException(502, {
          "error": {"code": "INVALID_RESPONSE", "message": "서버 응답을 확인하지 못했어요."},
        });
      }
      return body;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 && !forceRefresh) continue;
      throw _toException(error);
    }
  }
  throw _authRequired;
}

const _authRequired = ApiReadException(401, {
  "error": {"code": "AUTH_REQUIRED", "message": "다시 로그인해 주세요."},
});

ApiReadException _toException(DioException error) {
  final response = error.response;
  if (response == null) {
    return const ApiReadException(0, {
      "error": {"code": "NETWORK_UNAVAILABLE", "message": "서버에 연결하지 못했어요."},
    });
  }
  final status = response.statusCode ?? 0;
  final data = response.data;
  final detail = data is Map<String, dynamic> ? data["error"] : null;
  return ApiReadException(status, {
    "error": {
      "code": detail is Map<String, dynamic>
          ? detail["code"] as String? ?? "HTTP_$status"
          : "HTTP_$status",
      "message": detail is Map<String, dynamic>
          ? detail["message"] as String? ?? "요청을 처리하지 못했어요."
          : "요청을 처리하지 못했어요.",
    },
  });
}
