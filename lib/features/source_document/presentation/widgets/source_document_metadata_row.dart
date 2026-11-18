import 'package:flutter/material.dart';

import '../../../../shared/lds_colors.dart';

/// 메타 줄 하나: 이름표 13px `#6B7583` · 값 13px `#333D4B`.
class SourceDocumentMetadataRow extends StatelessWidget {
  const SourceDocumentMetadataRow(this.label, this.value, {super.key});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: LdsColors.muted),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: LdsColors.title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
