import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/workspace_colors.dart';
import 'source_document_view_model.dart';
import 'widgets/source_document_header.dart';
import 'widgets/source_document_footer.dart';
import 'widgets/source_document_content.dart';
import 'widgets/source_document_error.dart';

Future<void> showSourceDocument(
  BuildContext context, {
  required String requestId,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: SourceDocumentDialog(requestId: requestId),
    ),
  );
}

/// SCR-004: 원문·근거 보기. 닫으면 호출한 화면의 상태와 스크롤을 유지합니다.
class SourceDocumentDialog extends ConsumerWidget {
  const SourceDocumentDialog({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = sourceDocumentViewModelProvider(requestId);
    return Dialog(
      backgroundColor: canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SourceDocumentHeader(),
            const Divider(height: 1, color: line),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
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
                      data: (document) =>
                          SourceDocumentContent(document: document),
                    ),
              ),
            ),
            const Divider(height: 1, color: line),
            const SourceDocumentFooter(),
          ],
        ),
      ),
    );
  }
}
