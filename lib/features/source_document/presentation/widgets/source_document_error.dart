import 'package:flutter/material.dart';

import '../../../../shared/widgets/preview_button.dart';
import '../../../work_queue/domain/work_case.dart';

class SourceDocumentError extends StatelessWidget {
  const SourceDocumentError({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          switch (error) {
            StateError() => '이 요청의 합성 원문이 준비되지 않았습니다.',
            // API-25 failure: the server's own message (e.g. not found).
            WorkQueueFailure(:final message) => message,
            _ => '원문을 불러오지 못했습니다.',
          },
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        PreviewButton('다시 시도', onPressed: onRetry),
      ],
    );
  }
}
