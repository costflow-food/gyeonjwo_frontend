import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/source_document_repository_impl.dart';
import '../domain/source_document.dart';

part 'source_document_view_model.g.dart';

Duration? _noRetry(int retryCount, Object error) => null;

@Riverpod(keepAlive: true, retry: _noRetry)
class SourceDocumentViewModel extends _$SourceDocumentViewModel {
  @override
  Future<SourceDocument> build(String requestId) =>
      ref.watch(sourceDocumentRepositoryProvider).getDocument(requestId);

  void refresh() => ref.invalidateSelf();
}
