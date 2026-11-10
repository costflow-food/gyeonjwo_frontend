import 'package:flutter/material.dart';

import '../../../../shared/workspace_colors.dart';

class SourceDocumentMetadataRow extends StatelessWidget {
  const SourceDocumentMetadataRow(this.label, this.value, {super.key});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: context.palette.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
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
