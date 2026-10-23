import "dart:convert";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "work_queue_preview_data.dart";

part 'work_queue_data_source.g.dart';

@Riverpod(keepAlive: true)
WorkQueueDataSource workQueueDataSource(Ref ref) {
  return const PreviewWorkQueueDataSource();
}

abstract interface class WorkQueueDataSource {
  Future<Map<String, dynamic>> fetchRequests();
}

/// Replace this implementation with Dio when the API contract is ready.
class PreviewWorkQueueDataSource implements WorkQueueDataSource {
  const PreviewWorkQueueDataSource({
    this.latency = const Duration(milliseconds: 250),
  });

  final Duration latency;

  @override
  Future<Map<String, dynamic>> fetchRequests() async {
    await Future<void>.delayed(latency);
    // A fresh JSON object per call, just like a decoded HTTP response.
    return jsonDecode(jsonEncode(workQueuePreviewResponse))
        as Map<String, dynamic>;
  }
}
