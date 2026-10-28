import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

/// Completion message and result navigation. No queue or rerun button.
class ReviewProgressFooter extends StatelessWidget {
  const ReviewProgressFooter({
    super.key,
    required this.complete,
    required this.onViewResult,
  });
  final bool complete;
  final VoidCallback onViewResult;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Text(
            complete ? "검토 결과 조회가 완료되었습니다." : "창을 닫아도 조회는 계속됩니다.",
            style: const TextStyle(fontSize: 11, color: muted),
          ),
          if (complete)
            FilledButton(
              onPressed: onViewResult,
              style: FilledButton.styleFrom(
                fixedSize: Size(144 * scale, 44 * scale),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: ink,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: const BorderSide(color: ink),
              ),
              child: const Text('검토 결과 보기'),
            ),
        ],
      ),
    );
  }
}
