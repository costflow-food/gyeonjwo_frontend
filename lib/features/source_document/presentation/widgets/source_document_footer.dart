import 'package:flutter/material.dart';

import '../../../../shared/workspace_colors.dart';

class SourceDocumentFooter extends StatelessWidget {
  const SourceDocumentFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Text(
        '합성 자료 · 실제 외부 연결 없음',
        style: TextStyle(fontSize: 10, color: muted),
      ),
    );
  }
}
