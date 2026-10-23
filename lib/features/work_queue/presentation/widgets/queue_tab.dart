import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

class QueueTab extends StatelessWidget {
  const QueueTab(
    this.label,
    this.count, {
    super.key,
    required this.selected,
    required this.onTap,
  });
  final bool selected;
  final VoidCallback onTap;
  final String label, count;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? ink : line,
              width: selected ? 2 : 1,
            ),
          ),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? ink : muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              TextSpan(
                text: '  $count',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
