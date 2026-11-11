import "server_status.dart";

abstract interface class ServerStatusRepository {
  /// `/ready`를 읽습니다. 실패하면 [ServerStatus.unknown]을 돌려주며 던지지 않습니다.
  Future<ServerStatus> getStatus();
}
