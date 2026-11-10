import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";
import "../../domain/review_phase.dart";

/// What happens next, and the way to the case once the server stops.
class ReviewProgressFooter extends StatelessWidget {
  const ReviewProgressFooter({
    super.key,
    required this.outcome,
    required this.onViewCase,
  });

  /// null while the server is still working.
  final ReviewOutcome? outcome;
  final VoidCallback onViewCase;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
    final current = outcome;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Text(
            switch (current) {
              null => "창을 닫아도 검토는 서버에서 계속돼요.",
              ReviewOutcome(stopped: true) => "멈춘 이유는 업무에서 확인할 수 있어요.",
              ReviewOutcome.waitingReply => "회신이 오면 업무 큐에서 이어서 볼 수 있어요.",
              _ => "다음 단계는 업무에서 진행해 주세요.",
            },
            style: const TextStyle(fontSize: 13, color: muted),
          ),
          if (current != null)
            FilledButton(
              onPressed: onViewCase,
              style: FilledButton.styleFrom(
                fixedSize: Size(144 * scale, 44 * scale),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: ink,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: ink),
              ),
              child: const Text('업무 보기'),
            ),
        ],
      ),
    );
  }
}
