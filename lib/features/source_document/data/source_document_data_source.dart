import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/formatters.dart';
import '../../../shared/preview_workspace.dart';
import '../../work_queue/data/work_queue_repository_impl.dart';
import '../../work_queue/domain/work_queue_repository.dart';

import 'source_document_preview_data.dart';

part 'source_document_data_source.g.dart';

/// The real app reads the mail through API-25; the UI preview overrides this
/// with [PreviewSourceDocumentDataSource].
@Riverpod(keepAlive: true)
SourceDocumentDataSource sourceDocumentDataSource(Ref ref) =>
    ApiSourceDocumentDataSource(ref.watch(workQueueRepositoryProvider));

abstract interface class SourceDocumentDataSource {
  Future<Map<String, dynamic>> fetchDocument(String requestId);
}

/// API-25 원문을 이 다이얼로그의 형태로 바꿉니다. [fetchDocument]의 ID는
/// 거래처 근거·가격 이력·실행 로그가 주는 메일 ID입니다. 열기만 해서는
/// 추출·OCR이 실행되지 않습니다.
class ApiSourceDocumentDataSource implements SourceDocumentDataSource {
  const ApiSourceDocumentDataSource(this._repository);

  final WorkQueueRepository _repository;

  @override
  Future<Map<String, dynamic>> fetchDocument(String requestId) async {
    final mail = await _repository.getOriginalMail(requestId);
    return {
      'title': mail.subject,
      'sender': mail.sender,
      'recipient': mail.recipients.join(', '),
      'receivedAt': formatSeoulDateTime(mail.receivedAt),
      'documentType': '수신 메일',
      'paragraphs': [
        for (final paragraph in mail.bodyText.split(RegExp(r'\n\s*\n')))
          if (paragraph.trim().isNotEmpty) paragraph.trim(),
      ],
      'highlights': <String>[],
      'attachments': [
        for (final attachment in mail.attachments) attachment.filename,
      ],
    };
  }
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
