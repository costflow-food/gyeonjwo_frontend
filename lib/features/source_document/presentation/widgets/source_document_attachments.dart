import 'package:flutter/material.dart';

import '../../../../shared/workspace_colors.dart';

class SourceDocumentAttachments extends StatelessWidget {
  const SourceDocumentAttachments({super.key, required this.attachments});
  final List<String> attachments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 18, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              attachments.isEmpty
                  ? '첨부파일 없음'
                  : '${attachments.join(', ')} · 합성 첨부 ${attachments.length}개',
              style: const TextStyle(fontSize: 11, color: muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
