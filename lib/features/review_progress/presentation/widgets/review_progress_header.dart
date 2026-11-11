import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

class ReviewProgressHeader extends StatelessWidget {
  const ReviewProgressHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 20, 20, 20),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '검토 진행',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.palette.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: context.palette.muted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '검토 진행 닫기',
          onPressed: onClose,
          icon: Icon(Icons.close, size: 20, color: context.palette.muted),
        ),
      ],
    ),
  );
}
