import 'package:flutter/material.dart';

import '../../shared/workspace_colors.dart';
import '../../shared/widgets/workspace_shell.dart';
import '../../shared/widgets/outline_panel.dart';
import '../../shared/widgets/preview_button.dart';
import '../../shared/widgets/note_line.dart';

import 'widgets/queue_summary.dart';
import 'widgets/queue_toolbar.dart';
import 'widgets/request_row.dart';
import 'work_queue_preview_data.dart';

class WorkQueueView extends StatelessWidget {
  const WorkQueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkspaceShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: PreviewButton('목록 새로고침', icon: Icons.refresh),
          ),
          const SizedBox(height: 24),
          const QueueSummary(),
          const SizedBox(height: 28),
          OutlinePanel(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final table =
                    constraints.maxWidth >= 680 &&
                    MediaQuery.textScalerOf(context).scale(12) <= 18;
                return Column(
                  children: [
                    const QueueToolbar(),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFF64666B)),
                    if (table)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: Text(
                                '요청 문서',
                                style: TextStyle(fontSize: 12, color: muted),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '상태',
                                style: TextStyle(fontSize: 12, color: muted),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '수신 일시',
                                style: TextStyle(fontSize: 12, color: muted),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '작업',
                                  style: TextStyle(fontSize: 12, color: muted),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final row in requestPreviews)
                      RequestRow(row, table: table),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        const Text(
                          '총 6건 · 최신 수신순',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chevron_left,
                              size: 18,
                              color: Color(0xFFBCC0C6),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: blush,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(fontSize: 12, color: accent),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Color(0xFFBCC0C6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 20, 4, 32),
            child: NoteLine(
              '실행 전에는 요청 문서의 제목과 원문을 확인합니다. 상세 분석은 실행한 요청에 한해 시작되며, 원문 메일은 변경하지 않습니다.',
            ),
          ),
          const Divider(color: line),
          const SizedBox(height: 12),
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                '견줘 · 근거를 모아, 더 선명한 구매 검토.',
                style: TextStyle(fontSize: 10, color: muted),
              ),
              Text(
                'HTML DESIGN PROTOTYPE · 2026',
                style: TextStyle(fontSize: 9, color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
