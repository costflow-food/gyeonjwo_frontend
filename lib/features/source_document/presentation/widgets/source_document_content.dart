import 'package:flutter/material.dart';

import '../../../../shared/workspace_colors.dart';
import '../../domain/source_document.dart';
import 'source_document_body.dart';
import 'source_document_attachments.dart';
import 'source_document_metadata_row.dart';

class SourceDocumentContent extends StatelessWidget {
  const SourceDocumentContent({super.key, required this.document});
  final SourceDocument document;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SourceDocumentMetadataRow('발신', document.sender),
        SourceDocumentMetadataRow('수신', document.recipient),
        SourceDocumentMetadataRow('일시', document.receivedAt),
        SourceDocumentMetadataRow('문서 유형', document.documentType),
        const SizedBox(height: 16),
        SourceDocumentBody(document: document),
        const SizedBox(height: 20),
        SourceDocumentAttachments(attachments: document.attachments),
        const SizedBox(height: 16),
        const Text(
          '시연용 수신 시각·제목·본문입니다. 실제 메일이나 PDF를 조회한 결과가 아닙니다. 규격·구매계획·부대비용은 별도의 합성 근거 자료에서 구분해 제공합니다.',
          style: TextStyle(fontSize: 10, color: muted, height: 1.7),
        ),
      ],
    );
  }
}
