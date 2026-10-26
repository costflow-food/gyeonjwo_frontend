import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

class EvidenceBlock extends StatelessWidget {
  const EvidenceBlock(
    this.title, {
    super.key,
    this.body,
    this.tag,
    this.children = const [],
  });
  final String title;
  final String? body, tag;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...children,
        if (body != null)
          Text(
            body!,
            style: const TextStyle(fontSize: 11, color: muted, height: 1.75),
          ),
        if (tag != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              tag!,
              style: const TextStyle(fontSize: 9, color: muted),
            ),
          ),
        ],
      ],
    );
  }
}
