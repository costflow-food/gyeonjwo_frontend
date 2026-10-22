import "request_item.dart";

abstract interface class WorkQueueRepository {
  Future<List<RequestItem>> getRequests();
}
