import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/lds/lds.dart';
import '../../../shared/widgets/mobile_scaffold.dart';
import 'source_document_view_model.dart';
import 'widgets/source_document_content.dart';
import 'widgets/source_document_error.dart';

Future<void> showSourceDocument(
  BuildContext context, {
  required String requestId,
}) {
  return showDialog<void>(
    context: context,
    // Full screen on a phone: the dialog paints behind the system bars and
    // LdsDialog's own SafeArea keeps the content clear of them.
    useSafeArea: !isCompactLayout(context),
    barrierColor: LdsDialog.barrierColor,
    builder: (context) => SourceDocumentDialog(requestId: requestId),
  );
}

/// 원문·첨부 창: 메타 줄(발신·수신·일시·문서 유형) → 본문 → 첨부 칩.
class SourceDocumentDialog extends ConsumerWidget {
  const SourceDocumentDialog({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = sourceDocumentViewModelProvider(requestId);
    return LdsDialog(
      title: '원문·근거 보기',
      subtitle: '수신 문서 원문',
      maxWidth: 760,
      footerNote: '연결된 메일함에서 가져온 원문입니다.',
      child: ref
          .watch(provider)
          .when(
            skipLoadingOnRefresh: false,
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => SourceDocumentError(
              error: error,
              onRetry: () => ref.read(provider.notifier).refresh(),
            ),
            data: (document) => SourceDocumentContent(document: document),
          ),
    );
  }
}
