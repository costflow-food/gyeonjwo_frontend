import 'package:flutter/material.dart';

import '../../../../shared/workspace_colors.dart';

class SourceDocumentHeader extends StatelessWidget {
  const SourceDocumentHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 24),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '원문·근거 보기',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                SizedBox(height: 4),
                Text('수신 문서 원문', style: TextStyle(fontSize: 11, color: muted)),
              ],
            ),
          ),
          IconButton(
            tooltip: '닫기',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20, color: muted),
          ),
        ],
      ),
    );
  }
}
