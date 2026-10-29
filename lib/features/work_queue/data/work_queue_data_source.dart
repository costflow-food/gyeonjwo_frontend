import "dart:convert";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/preview_workspace.dart";

import "work_queue_preview_data.dart";

part 'work_queue_data_source.g.dart';

@Riverpod(keepAlive: true)
WorkQueueDataSource workQueueDataSource(Ref ref) {
  return PreviewWorkQueueDataSource(
    workspace: ref.watch(previewWorkspaceProvider),
  );
}

abstract interface class WorkQueueDataSource {
  Future<Map<String, dynamic>> fetchRequests();
}

/// Replace this implementation with Dio when the API contract is ready.
class PreviewWorkQueueDataSource implements WorkQueueDataSource {
  const PreviewWorkQueueDataSource({
    this.latency = const Duration(milliseconds: 250),
    this.workspace,
  });

  final Duration latency;
  final PreviewWorkspace? workspace;

  @override
  Future<Map<String, dynamic>> fetchRequests() async {
    await Future<void>.delayed(latency);
    // A fresh JSON object per call, just like a decoded HTTP response.
    final response = jsonDecode(
      jsonEncode(workQueuePreviewResponse),
    ) as Map<String, dynamic>;
    response['requests'] = [
      ...?workspace?.requests,
      ...response['requests'] as List,
    ];
    return jsonDecode(jsonEncode(response)) as Map<String, dynamic>;
  }
}
