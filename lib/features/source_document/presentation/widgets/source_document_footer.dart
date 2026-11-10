import 'package:flutter/material.dart';

import '../../../../shared/workspace_colors.dart';

class SourceDocumentFooter extends StatelessWidget {
  const SourceDocumentFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Text(
        '연결된 메일함에서 가져온 원문입니다.',
        style: TextStyle(fontSize: 12, color: context.palette.muted),
      ),
    );
  }
}
