import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/workspace_colors.dart';
import 'source_document_view_model.dart';
import 'widgets/source_document_header.dart';
import 'widgets/source_document_footer.dart';
import 'widgets/source_document_content.dart';
import 'widgets/source_document_error.dart';
import '../../../shared/widgets/mobile_scaffold.dart';
import '../../../shared/widgets/workspace_dialog.dart';

Future<void> showSourceDocument(
  BuildContext context, {
  required String requestId,
}) {
  return showDialog<void>(
    context: context,
    // Full screen on a phone: the dialog paints behind the system bars and
    // WorkspaceDialog's own SafeArea keeps the content clear of them.
    useSafeArea: !isCompactLayout(context),
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: SourceDocumentDialog(requestId: requestId),
    ),
  );
}

class SourceDocumentDialog extends ConsumerWidget {
  const SourceDocumentDialog({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = sourceDocumentViewModelProvider(requestId);
    return WorkspaceDialog(
      maxWidth: 760,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SourceDocumentHeader(),
          Divider(height: 1, color: context.palette.line),
          DialogScrollArea(
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
          Divider(height: 1, color: context.palette.line),
          const SourceDocumentFooter(),
        ],
      ),
    );
  }
}
