import 'package:flutter/material.dart';

import '../../../../shared/lds_colors.dart';
import '../../../../shared/widgets/lds/lds.dart';

/// 첨부 칩: 파일마다 클립 아이콘 + 이름(높이 32, 1px 선, 모서리 4) + 개수.
class SourceDocumentAttachments extends StatelessWidget {
  const SourceDocumentAttachments({super.key, required this.attachments});
  final List<String> attachments;

  static const _muted = TextStyle(fontSize: 13, color: LdsColors.mutedStrong);

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const Row(
        children: [
          Icon(Icons.attach_file, size: 16, color: LdsColors.mutedStrong),
          SizedBox(width: 6),
          Text('첨부파일 없음', style: _muted),
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final name in attachments)
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: LdsColors.line),
              borderRadius: BorderRadius.circular(LdsRadius.button),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.attach_file,
                  size: 16,
                  color: LdsColors.mutedStrong,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LdsColors.title,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Text('첨부 ${attachments.length}개', style: _muted),
      ],
    );
  }
}
