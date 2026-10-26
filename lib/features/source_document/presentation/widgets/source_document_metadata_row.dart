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
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF60636A),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
