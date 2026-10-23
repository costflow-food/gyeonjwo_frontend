import 'source_document.dart';

abstract interface class SourceDocumentRepository {
  Future<SourceDocument> getDocument(String requestId);
}
