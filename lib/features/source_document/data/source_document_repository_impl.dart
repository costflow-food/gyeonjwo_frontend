import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/source_document.dart';
import '../domain/source_document_repository.dart';
import 'source_document_data_source.dart';

part 'source_document_repository_impl.g.dart';

@Riverpod(keepAlive: true)
SourceDocumentRepository sourceDocumentRepository(Ref ref) =>
    SourceDocumentRepositoryImpl(ref.watch(sourceDocumentDataSourceProvider));

class SourceDocumentRepositoryImpl implements SourceDocumentRepository {
  const SourceDocumentRepositoryImpl(this._dataSource);
  final SourceDocumentDataSource _dataSource;

  @override
  Future<SourceDocument> getDocument(String requestId) async {
    final json = await _dataSource.fetchDocument(requestId);
    return SourceDocument(
      title: json['title'] as String,
      sender: json['sender'] as String,
      recipient: json['recipient'] as String,
      receivedAt: json['receivedAt'] as String,
      documentType: json['documentType'] as String,
      paragraphs: List<String>.from(json['paragraphs'] as List),
      highlights: List<String>.from(json['highlights'] as List),
      attachments: List<String>.from(json['attachments'] as List),
    );
  }
}
