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
        border: Border.all(color: context.palette.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file, size: 18, color: context.palette.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              attachments.isEmpty
                  ? '첨부파일 없음'
                  : '${attachments.join(', ')} · 합성 첨부 ${attachments.length}개',
              style: TextStyle(
                fontSize: 13,
                color: context.palette.muted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
