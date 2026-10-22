import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import "../../../../shared/workspace_colors.dart";
import "../../../../shared/widgets/preview_button.dart";

import "../../domain/request_item.dart";
import 'status_badge.dart';

class RequestRow extends StatelessWidget {
  const RequestRow(this.data, {super.key, required this.table});
  final RequestItem data;
  final bool table;

  @override
  Widget build(BuildContext context) {
    final document = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            data.attachments == 0
                ? Icons.mail_outline
                : Icons.description_outlined,
            size: 18,
            color: const Color(0xFF686B71),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${data.supplier} · 수신 메일',
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                  if (data.attachments > 0)
                    Text(
                      '첨부 ${data.attachments}',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    final action = data.action == '원문 보기'
        ? TextButton(
            onPressed: () {},
            child: const Text(
              '원문 보기',
              style: TextStyle(color: ink, fontSize: 12),
            ),
          )
        : PreviewButton(
            data.action,
            icon: data.action == '실행' ? Icons.play_arrow_outlined : null,
            filled: data.action == '실행',
            onPressed: data.action == '실행' || data.action == '결과 보기'
                ? () => context.go(
                    Uri(
                      path: "/review",
                      queryParameters: {"requestId": data.id},
                    ).toString(),
                  )
                : null,
          );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: table ? 12 : 0, vertical: 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: table
          ? Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: document,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(data.status),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${data.date}\n${data.time}',
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.8,
                      color: muted,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Align(alignment: Alignment.centerRight, child: action),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                document,
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(data.status),
                    Text(
                      '${data.date}  ${data.time}',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            ),
    );
  }
}
