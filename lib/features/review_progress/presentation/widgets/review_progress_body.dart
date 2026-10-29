import "package:flutter/material.dart";

import "../../../../shared/workspace_colors.dart";

class ReviewProgressBody extends StatelessWidget {
  const ReviewProgressBody({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(28, 32, 28, 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle_outline, size: 56, color: ink),
        SizedBox(height: 20),
        Semantics(
          liveRegion: true,
          child: Text(
            "검토카드가 준비되었어요",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          "요청에 대한 검토 결과를 불러왔습니다.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.7, color: muted),
        ),
        SizedBox(height: 16),
        Text(
          "현재는 합성 응답을 조회합니다. 실제 AI 분석과 독립 계산 검증은 실행하지 않습니다.",
          style: TextStyle(fontSize: 11, height: 1.7, color: muted),
        ),
      ],
    ),
  );
}
