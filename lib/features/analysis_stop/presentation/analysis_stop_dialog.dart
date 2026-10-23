import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/preview_button.dart';
import '../../../shared/workspace_colors.dart';
import '../domain/analysis_stop_reason.dart';
import 'widgets/analysis_stop_header.dart';
import 'widgets/stop_reason_card.dart';

/// SCR-006 분석 중단 사유. SCR-003에서 필수 조건 미확인으로 분석이 중단될 때 연다.
Future<void> showAnalysisStopDialog(
  BuildContext context, {
  AnalysisStopReason reason = AnalysisStopReason.packagingSpec,
  VoidCallback? onOpenSource,
  VoidCallback? onGoToQueue,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AnalysisStopDialog(
      reason: reason,
      onOpenSource: onOpenSource,
      onGoToQueue:
          onGoToQueue ??
          () {
            Navigator.of(dialogContext).pop();
            context.go('/');
          },
    ),
  );
}

class AnalysisStopDialog extends StatelessWidget {
  const AnalysisStopDialog({
    super.key,
    required this.reason,
    required this.onGoToQueue,
    this.onOpenSource,
  });

  final AnalysisStopReason reason;
  final VoidCallback? onOpenSource;
  final VoidCallback onGoToQueue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnalysisStopHeader(stage: reason.stage),
              const Divider(height: 1, color: line),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StopReasonCard(reason: reason),
                    const SizedBox(height: 18),
                    const Text(
                      '필수 조건이 확인되지 않아 전체 분석을 중단한 합성 사례입니다. '
                      '담당자는 기존 업무 절차로 거래처의 규격과 비용 조건을 재확인할 수 있습니다. '
                      '새 회신은 새 업무로 접수합니다.',
                      style: TextStyle(fontSize: 11, color: muted, height: 1.7),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '필수 정보가 없는 항목 값으로 채우거나 일부 규격만 계산한 카드를 제공하지 않습니다.',
                      style: TextStyle(fontSize: 10, color: muted, height: 1.6),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: line),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    PreviewButton('원문 확인', onPressed: onOpenSource),
                    PreviewButton('업무 큐', filled: true, onPressed: onGoToQueue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
