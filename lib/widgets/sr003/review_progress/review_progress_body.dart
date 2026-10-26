import 'package:flutter/material.dart';

import '../../../shared/workspace_colors.dart';
import '../../../features/review_progress/presentation/review_progress_view_model.dart';
import 'review_progress_step.dart';

/// Progress icon, explanatory text, step list, and preview notice.
class ReviewProgressBody extends StatelessWidget {
  const ReviewProgressBody({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final complete = step >= reviewSteps.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                complete ? Icons.check : Icons.layers_outlined,
                color: Colors.white,
                size: 27,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            liveRegion: true,
            child: Text(
              complete ? '검토카드가 준비되었어요' : '요청의 근거를 모으고 있어요',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '단가변경 요청부터 거래처 대안까지, 한 번에 살펴봅니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.7, color: muted),
          ),
          const SizedBox(height: 28),
          for (var index = 0; index < reviewSteps.length; index++)
            ReviewProgressStep(index: index, current: step),
          const SizedBox(height: 16),
          const Text(
            '합성 사례의 화면 전환 시연입니다. 실제 AI 분석과 독립 계산 검증을 실행하지 않습니다.',
            style: TextStyle(fontSize: 11, height: 1.7, color: muted),
          ),
        ],
      ),
    );
  }
}
