import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/network/api_request.dart";
import "../../auth/data/auth_session_data_source.dart";

part "mail_intake_data_source.g.dart";

@Riverpod(keepAlive: true)
MailIntakeDataSource mailIntakeDataSource(Ref ref) => ApiMailIntakeDataSource(
  ref.watch(apiClientProvider),
  ref.watch(authSessionDataSourceProvider).freshAccessToken,
);

/// API-23 `GET /mail-intake`, API-24 `POST /mail-messages/{mail_id}/resolve`.
abstract interface class MailIntakeDataSource {
  Future<Map<String, dynamic>> fetchPending({String? cursor, int limit = 25});

  Future<Map<String, dynamic>> resolve(
    String mailId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });
}

class ApiMailIntakeDataSource implements MailIntakeDataSource {
  const ApiMailIntakeDataSource(this._dio, this._accessToken);

  final Dio _dio;
  final ApiTokenReader _accessToken;

  @override
  Future<Map<String, dynamic>> fetchPending({String? cursor, int limit = 25}) =>
      _send(
        (headers) => _dio.get<Map<String, dynamic>>(
          "/api/v1/mail-intake",
          queryParameters: {"limit": limit, "cursor": ?cursor},
          options: Options(headers: headers),
        ),
      );

  @override
  Future<Map<String, dynamic>> resolve(
    String mailId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _send(
    (headers) => _dio.post<Map<String, dynamic>>(
      "/api/v1/mail-messages/$mailId/resolve",
      // The server rejects unknown fields; null optionals are omitted.
      data: {
        for (final entry in body.entries)
          if (entry.value != null) entry.key: entry.value,
      },
      options: Options(headers: headers),
    ),
    idempotencyKey: idempotencyKey,
  );

  Future<T> _send<T>(
    Future<Response<T>> Function(Map<String, String> headers) request, {
    String? idempotencyKey,
  }) => sendApiRequest(_accessToken, request, idempotencyKey: idempotencyKey);
}
