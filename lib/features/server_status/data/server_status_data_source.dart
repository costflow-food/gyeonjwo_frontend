import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_client.dart";

part "server_status_data_source.g.dart";

@Riverpod(keepAlive: true)
ServerStatusDataSource serverStatusDataSource(Ref ref) =>
    ApiServerStatusDataSource(ref.watch(apiClientProvider));

/// 운영 점검 `GET /health`, `GET /ready`.
///
/// 둘 다 인증 없이 열려 있고 `{data, meta}` 봉투 없이 본문을 그대로 줍니다.
abstract interface class ServerStatusDataSource {
  Future<Map<String, dynamic>> fetchHealth();

  /// 503(준비 안 됨)도 본문과 함께 돌려줍니다. 서버에 닿지 못하면 던집니다.
  Future<(int, Map<String, dynamic>)> fetchReady();
}

class ApiServerStatusDataSource implements ServerStatusDataSource {
  const ApiServerStatusDataSource(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> fetchHealth() async {
    final response = await _dio.get<Map<String, dynamic>>("/health");
    return response.data ?? const {};
  }

  @override
  Future<(int, Map<String, dynamic>)> fetchReady() async {
    final response = await _dio.get<Map<String, dynamic>>(
      "/ready",
      options: Options(
        validateStatus: (status) => status == 200 || status == 503,
      ),
    );
    return (response.statusCode ?? 0, response.data ?? const {});
  }
}

/// UI 미리보기와 테스트용 고정 응답.
class PreviewServerStatusDataSource implements ServerStatusDataSource {
  const PreviewServerStatusDataSource({
    this.mailSendingEnabled = false,
    this.degradedFeatures = const ["review"],
  });

  final bool mailSendingEnabled;
  final List<String> degradedFeatures;

  @override
  Future<Map<String, dynamic>> fetchHealth() async => {
    "status": "ok",
    "mail_sending_enabled": mailSendingEnabled,
  };

  @override
  Future<(int, Map<String, dynamic>)> fetchReady() async =>
      (200, {"status": "ready", "degraded_features": degradedFeatures});
}
