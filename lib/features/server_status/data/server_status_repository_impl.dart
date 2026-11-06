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
    try {
      final (status, body) = await _dataSource.fetchReady();
      if (status == 503) return const ServerStatus(notReady: true);
      final degraded = body["degraded_features"];
      if (body["status"] != "ready" || degraded is! List) {
        return ServerStatus.unknown;
      }
      return ServerStatus(
        degraded: {
          for (final feature in ServerFeature.values)
            if (degraded.contains(feature.code)) feature,
        },
      );
    } catch (_) {
      return ServerStatus.unknown;
    }
  }
}
