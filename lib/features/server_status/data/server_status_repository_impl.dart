import "package:riverpod_annotation/riverpod_annotation.dart";

import "../domain/server_status.dart";
import "../domain/server_status_repository.dart";
import "server_status_data_source.dart";

part "server_status_repository_impl.g.dart";

@Riverpod(keepAlive: true)
ServerStatusRepository serverStatusRepository(Ref ref) =>
    ServerStatusRepositoryImpl(ref.watch(serverStatusDataSourceProvider));

class ServerStatusRepositoryImpl implements ServerStatusRepository {
  const ServerStatusRepositoryImpl(this._dataSource);

  final ServerStatusDataSource _dataSource;

  @override
  Future<ServerStatus> getStatus() async {
    final (reviewReady, mailSendingEnabled) = await (
      _reviewReady(),
      _mailSendingEnabled(),
    ).wait;
    return ServerStatus(
      reviewReady: reviewReady,
      mailSendingEnabled: mailSendingEnabled,
    );
  }

  Future<bool?> _reviewReady() async {
    try {
      final (status, body) = await _dataSource.fetchReady();
      if (status == 503) return false;
      final degraded = body["degraded_features"];
      if (body["status"] != "ready" || degraded is! List) return null;
      return !degraded.contains("review");
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _mailSendingEnabled() async {
    try {
      final value = (await _dataSource.fetchHealth())["mail_sending_enabled"];
      return value is bool ? value : null;
    } catch (_) {
      return null;
    }
  }
}
