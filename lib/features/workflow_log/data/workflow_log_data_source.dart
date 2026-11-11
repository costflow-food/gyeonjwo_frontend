import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";
import "../../../shared/network/authorized_json_get.dart";
import "../../auth/data/auth_session_data_source.dart";

part "workflow_log_data_source.g.dart";

@Riverpod(keepAlive: true)
WorkflowLogDataSource workflowLogDataSource(Ref ref) =>
    ApiWorkflowLogDataSource(
      ref.watch(apiClientProvider),
      ref.watch(authSessionDataSourceProvider).freshAccessToken,
    );

/// API-28 `GET /workflow-logs` with snake_case query parameters.
/// Failures use the 08 error shape via [ApiReadException].
abstract interface class WorkflowLogDataSource {
  Future<Map<String, dynamic>> fetchLogs(
    Map<String, String> query, {
    String? cursor,
    int limit = 25,
  });
}

class ApiWorkflowLogDataSource implements WorkflowLogDataSource {
  const ApiWorkflowLogDataSource(this._dio, this._accessToken);

  final Dio _dio;
  final ApiTokenReader _accessToken;

  @override
  Future<Map<String, dynamic>> fetchLogs(
    Map<String, String> query, {
    String? cursor,
    int limit = 25,
  }) => authorizedJsonGet(
    _dio,
    _accessToken,
    "/api/v1/workflow-logs",
    queryParameters: {...query, "cursor": ?cursor, "limit": limit},
  );
}
