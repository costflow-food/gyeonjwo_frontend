import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:pdfrx/pdfrx.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/outline_panel.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/work_case.dart";
import "../work_queue_view_model.dart";

/// PDF 바이트를 그리는 위젯. 테스트는 PDF 엔진 없이 자리표시로 바꿉니다.
final pdfDocumentViewProvider =
    Provider<Widget Function(Uint8List bytes, String sourceName)>(
      (ref) =>
          (bytes, sourceName) => PdfViewer.data(bytes, sourceName: sourceName),
    );

/// 메일 본문 옆에 띄우는 첨부 PDF 뷰어(API-26).
class AttachmentViewer extends ConsumerWidget {
  const AttachmentViewer({
    super.key,
    required this.mailId,
    required this.attachment,
    required this.height,
    required this.onClose,
  });

  final String mailId;
  final MailAttachment attachment;
  final double height;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = attachmentContentProvider(mailId, attachment.id);
    final content = ref.watch(provider);
    return SizedBox(
      height: height,
      child: OutlinePanel(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 18,
                    color: muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attachment.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSizes.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: "첨부 닫기",
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: line),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
                child: content.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ViewerError(
                    message: error is WorkQueueFailure
                        ? error.message
                        : "첨부파일을 불러오지 못했어요.",
                    onRetry: () => ref.invalidate(provider),
                  ),
                  data: (bytes) => ref.watch(pdfDocumentViewProvider)(
                    bytes,
                    "$mailId/${attachment.id}",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerError extends StatelessWidget {
  const _ViewerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 28, color: muted),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: AppFontSizes.body, color: muted),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onRetry,
          style: WorkspaceButtonStyles.outlined,
          child: const Text("다시 시도"),
        ),
      ],
    ),
  );
}
