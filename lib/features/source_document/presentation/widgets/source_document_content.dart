import 'package:flutter/material.dart';

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
      ],
    );
  }
}
