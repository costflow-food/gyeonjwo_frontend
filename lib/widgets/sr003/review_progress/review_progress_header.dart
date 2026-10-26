import 'package:flutter/material.dart';

import '../../../shared/workspace_colors.dart';

/// Title, request label, and close button.
class ReviewProgressHeader extends StatelessWidget {
  const ReviewProgressHeader({
    super.key,
    required this.supplier,
    required this.onClose,
  });
  final String supplier;
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
              const Text(
                '검토 진행',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '디자인 시연 · $supplier',
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '검토 진행 닫기',
          onPressed: onClose,
          icon: const Icon(Icons.close, size: 20, color: muted),
        ),
      ],
    ),
  );
}
