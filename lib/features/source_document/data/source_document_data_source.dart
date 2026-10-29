import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/preview_workspace.dart';

import 'source_document_preview_data.dart';

part 'source_document_data_source.g.dart';

@Riverpod(keepAlive: true)
SourceDocumentDataSource sourceDocumentDataSource(Ref ref) =>
    PreviewSourceDocumentDataSource(
      workspace: ref.watch(previewWorkspaceProvider),
    );

abstract interface class SourceDocumentDataSource {
  Future<Map<String, dynamic>> fetchDocument(String requestId);
}

class PreviewSourceDocumentDataSource implements SourceDocumentDataSource {
  const PreviewSourceDocumentDataSource({this.workspace});

  final PreviewWorkspace? workspace;

  @override
  Future<Map<String, dynamic>> fetchDocument(String requestId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final response =
        workspace?.documents[requestId] ??
        sourceDocumentPreviewResponses[requestId];
    if (response == null) {
      throw StateError('이 요청의 합성 원문이 준비되지 않았습니다.');
    }
    return jsonDecode(jsonEncode(response)) as Map<String, dynamic>;
  }
}
