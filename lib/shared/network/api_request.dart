import "dart:convert";

import "package:dio/dio.dart";

/// Reads the current access token; `forceRefresh` refreshes the session first.
typedef ApiTokenReader = Future<String?> Function({bool forceRefresh});

/// 429 code. The server sends it too; a 429 without a body gets it here.
const rateLimitedCode = "RATE_LIMITED";

/// Longest `Retry-After` the app waits out by itself before one more try.
const maxRateLimitWait = Duration(seconds: 10);

/// Used when a 429 has no readable `Retry-After`.
const _defaultRateLimitWait = Duration(seconds: 1);

/// 08 오류 응답(`error.code`, `error.message`)을 토큰 없이 옮긴 실패.
class ApiException implements Exception {
  const ApiException(
    this.statusCode,
    this.code,
    this.message, {
    this.retryable = false,
    this.unknownOutcome = false,
    this.retryAfter,
  });

  /// 0이면 응답을 받지 못했습니다.
  final int statusCode;
  final String code;
  final String message;

  /// 응답 없음, 5xx, 또는 본문 `retryable: true`. 서버가 이미 처리했을 수
  /// 있으니 같은 멱등 키를 남기고 상태를 바로 다시 읽습니다.
  final bool retryable;

  /// 응답 없음, 또는 서버가 `retryable: false`라고 하지 않은 5xx.
  /// 처리 여부를 알 수 없어 서버 문구 대신 확인 안내를 보여 줍니다.
  final bool unknownOutcome;

  /// 429의 `Retry-After`.
  final Duration? retryAfter;

  bool get rateLimited => statusCode == 429;

  @override
  String toString() => "ApiException($statusCode, $code)";
}

const _authRequired = ApiException(401, "AUTH_REQUIRED", "다시 로그인해 주세요.");

const _invalidResponse = ApiException(
  502,
  "INVALID_RESPONSE",
  "서버 응답을 확인하지 못했습니다.",
);

/// 인증된 API 요청 하나를 보내고 응답 본문을 돌려줍니다.
///
/// - 만료된 세션은 한 번 갱신해 같은 요청(같은 멱등 키)으로 다시 보냅니다.
/// - 429는 `Retry-After`가 [maxRateLimitWait] 이하면 그만큼 기다렸다 한 번 더
///   보냅니다. 그래도 막히면 [rateLimitedCode] 실패를 던집니다.
/// - DioException은 요청 헤더(토큰)를 담고 있어 그대로 던지지 않고
///   [ApiException]으로 바꿉니다.
Future<T> sendApiRequest<T>(
  ApiTokenReader accessToken,
  Future<Response<T>> Function(Map<String, String> headers) request, {
  String? idempotencyKey,
  Future<void> Function(Duration delay)? wait,
}) async {
  for (var attempt = 0; ; attempt++) {
    try {
      return await _sendWithSession(accessToken, request, idempotencyKey);
    } on ApiException catch (error) {
      final delay = error.retryAfter ?? _defaultRateLimitWait;
      if (!error.rateLimited || attempt > 0 || delay > maxRateLimitWait) {
        rethrow;
      }
      await (wait ?? Future<void>.delayed)(delay);
    }
  }
}

Future<T> _sendWithSession<T>(
  ApiTokenReader accessToken,
  Future<Response<T>> Function(Map<String, String> headers) request,
  String? idempotencyKey,
) async {
  for (final forceRefresh in const [false, true]) {
    final token = await accessToken(forceRefresh: forceRefresh);
    if (token == null) throw _authRequired;
    try {
      final response = await request({
        "Authorization": "Bearer $token",
        "Idempotency-Key": ?idempotencyKey,
      });
      final body = response.data;
      if (body == null) throw _invalidResponse;
      return body;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 && !forceRefresh) continue;
      throw apiExceptionFrom(error);
    }
  }
  throw _authRequired;
}

/// Maps a Dio failure to the 08 error shape without the request headers.
ApiException apiExceptionFrom(DioException error) {
  final response = error.response;
  if (response == null) {
    return const ApiException(
      0,
      "NETWORK_UNAVAILABLE",
      "서버에 연결하지 못했습니다.",
      retryable: true,
      unknownOutcome: true,
    );
  }
  final status = response.statusCode ?? 0;
  if (status == 429) {
    return ApiException(
      429,
      rateLimitedCode,
      "요청이 많습니다. 잠시 후 다시 해 주세요.",
      retryAfter: _retryAfter(response.headers.value("retry-after")),
    );
  }
  final body = _errorBody(response.data);
  final detail = body is Map<String, dynamic> ? body["error"] : null;
  final fields = detail is Map<String, dynamic>
      ? detail
      : const <String, dynamic>{};
  final flagged = fields["retryable"];
  final serverError = status >= 500;
  return ApiException(
    status,
    fields["code"] as String? ?? "HTTP_$status",
    fields["message"] as String? ?? "요청을 처리하지 못했습니다.",
    retryable: serverError || flagged == true,
    unknownOutcome: serverError && flagged != false,
  );
}

/// Byte responses (attachments) also carry their error body as bytes.
Object? _errorBody(Object? data) {
  if (data is! List<int>) return data;
  try {
    return jsonDecode(utf8.decode(data));
  } on FormatException {
    return null;
  }
}

/// Seconds only; the server never sends an HTTP date.
Duration? _retryAfter(String? header) {
  final seconds = int.tryParse(header?.trim() ?? "");
  return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
}
