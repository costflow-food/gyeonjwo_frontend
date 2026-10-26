import 'package:flutter/material.dart';

import '../../../shared/workspace_colors.dart';
import '../../../features/review_progress/presentation/review_progress_view_model.dart';

class ReviewProgressStep extends StatelessWidget {
  const ReviewProgressStep({
    super.key,
    required this.index,
    required this.current,
  });
  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    final highlighted = done || active;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlighted ? ink : Colors.white,
              border: Border.all(
                color: highlighted ? ink : const Color(0xFFD5D8DD),
              ),
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        color: active ? Colors.white : const Color(0xFFA0A4AA),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reviewSteps[index],
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: highlighted ? ink : const Color(0xFFA0A4AA),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            done
                ? '완료'
                : active
                ? '시연 중'
                : '대기',
            style: TextStyle(
              fontSize: 11,
              color: highlighted ? muted : const Color(0xFFB3B6BC),
            ),
          ),
        ],
      ),
    );
  }
}
