import "server_status.dart";

abstract interface class ServerStatusRepository {
  /// `/health`와 `/ready`를 함께 읽습니다. 한쪽이 실패해도 다른 쪽 값은 남깁니다.
  /// 이 메서드는 던지지 않습니다.
  Future<ServerStatus> getStatus();
}
