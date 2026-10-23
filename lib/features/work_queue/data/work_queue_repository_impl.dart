import "package:riverpod_annotation/riverpod_annotation.dart";

import "../domain/request_item.dart";
import "../domain/work_queue_repository.dart";
import "work_queue_data_source.dart";

part 'work_queue_repository_impl.g.dart';

@Riverpod(keepAlive: true)
WorkQueueRepository workQueueRepository(Ref ref) {
  return WorkQueueRepositoryImpl(ref.watch(workQueueDataSourceProvider));
}

class WorkQueueRepositoryImpl implements WorkQueueRepository {
  const WorkQueueRepositoryImpl(this._dataSource);

  final WorkQueueDataSource _dataSource;

  @override
  Future<List<RequestItem>> getRequests() async {
    final response = await _dataSource.fetchRequests();
    return List.unmodifiable(
      (response["requests"] as List).map((entry) {
        final json = entry as Map<String, dynamic>;
        return RequestItem(
          id: json["id"] as String,
          title: json["title"] as String,
          supplier: json["supplier"] as String,
          attachments: json["attachments"] as int,
          status: json["status"] as String,
          date: json["date"] as String,
          time: json["time"] as String,
          action: json["action"] as String,
        );
      }),
    );
  }
}
