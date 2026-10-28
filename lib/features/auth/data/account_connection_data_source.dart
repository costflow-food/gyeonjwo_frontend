import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../domain/auth_failure.dart";

part "account_connection_data_source.g.dart";

/// Draft contract with the server (KAN-17). Update both sides together.
abstract final class AccountConnectionPaths {
  static const connect = "/api/v1/mailboxes/google/connect";
  static const connection = "/api/v1/mailboxes/google/connection";
}

@Riverpod(keepAlive: true)
AccountConnectionDataSource accountConnectionDataSource(Ref ref) =>
    ApiAccountConnectionDataSource(ref.watch(apiClientProvider));

abstract interface class AccountConnectionDataSource {
  /// POST the Google tokens; the server verifies them and starts receiving.
  Future<Map<String, dynamic>> connectGoogle({
    required String accessToken,
    required String providerAccessToken,
    required String? providerRefreshToken,
    required String idempotencyKey,
  });

  /// GET the connection the server currently keeps for this user.
  Future<Map<String, dynamic>> fetchGoogleConnection({
    required String accessToken,
  });
}

class ApiAccountConnectionDataSource implements AccountConnectionDataSource {
  const ApiAccountConnectionDataSource(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> connectGoogle({
    required String accessToken,
    required String providerAccessToken,
    required String? providerRefreshToken,
    required String idempotencyKey,
  }) => _send(
    () => _dio.post<Map<String, dynamic>>(
      AccountConnectionPaths.connect,
      data: {
        "provider_access_token": providerAccessToken,
        "provider_refresh_token": providerRefreshToken,
      },
      options: Options(
        headers: {
          "Authorization": "Bearer $accessToken",
          "Idempotency-Key": idempotencyKey,
        },
      ),
    ),
  );

  @override
  Future<Map<String, dynamic>> fetchGoogleConnection({
    required String accessToken,
  }) => _send(
    () => _dio.get<Map<String, dynamic>>(
      AccountConnectionPaths.connection,
      options: Options(
        headers: {
          "Authorization": "Bearer $accessToken",
          "Cache-Control": "no-store",
        },
      ),
    ),
  );

  Future<Map<String, dynamic>> _send(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    _ensureSecureBaseUrl();
    try {
      final response = await request();
      final body = response.data;
      if (body == null) {
        throw const AuthFailure(AuthFailureCode.serverUnavailable);
      }
      return body;
    } on DioException catch (error) {
      // Map to a token-free failure; DioException keeps request options.
      throw _toFailure(error);
    }
  }

  void _ensureSecureBaseUrl() {
    final uri = Uri.tryParse(_dio.options.baseUrl);
    if (uri == null || uri.host.isEmpty) {
      throw const AuthFailure(AuthFailureCode.notConfigured);
    }
    final isLocal = uri.host == "localhost" || uri.host == "127.0.0.1";
    if (uri.scheme != "https" && !isLocal) {
      throw const AuthFailure(AuthFailureCode.insecureServer);
    }
  }

  AuthFailure _toFailure(DioException error) {
    final response = error.response;
    if (response == null) {
      return const AuthFailure(
        AuthFailureCode.serverUnavailable,
        retryable: true,
      );
    }
    final body = response.data;
    final errorBody = body is Map<String, dynamic> ? body["error"] : null;
    final serverCode = errorBody is Map<String, dynamic>
        ? errorBody["code"] as String?
        : null;
    final status = response.statusCode ?? 0;
    if (status == 401) {
      return AuthFailure(
        AuthFailureCode.sessionExpired,
        serverCode: serverCode,
      );
    }
    if (status == 409 && serverCode == "REQUEST_IN_PROGRESS") {
      return AuthFailure(
        AuthFailureCode.serverUnavailable,
        serverCode: serverCode,
        retryable: true,
      );
    }
    if (status >= 500 || status == 429) {
      return AuthFailure(
        AuthFailureCode.serverUnavailable,
        serverCode: serverCode,
        retryable: true,
      );
    }
    return AuthFailure(AuthFailureCode.serverRejected, serverCode: serverCode);
  }
}
