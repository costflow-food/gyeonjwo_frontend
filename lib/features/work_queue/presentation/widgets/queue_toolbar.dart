import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

import "queue_tab.dart";
import "../work_queue_view_model.dart";

class QueueToolbar extends StatelessWidget {
  const QueueToolbar({
    super.key,
    required this.data,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  final WorkQueueState data;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final status in ["전체", "검토 대기", "완료", "검토 필요", "제외"])
          QueueTab(
            status,
            data.countFor(status).toString(),
            selected: data.selectedStatus == status,
            onTap: () => onStatusChanged(status),
          ),
      ],
    );
    final search = TextFormField(
      initialValue: data.query,
      onChanged: onSearchChanged,
      style: TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: '문서 제목, 거래처 검색',
        hintStyle: TextStyle(fontSize: 12, color: muted),
        suffixIcon: Icon(Icons.search, size: 19),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(color: Color(0xFFB4B7BD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(color: ink),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [tabs, SizedBox(height: 16), search],
          );
        }
        return Row(
          children: [
            Expanded(child: tabs),
            const SizedBox(width: 20),
            SizedBox(width: constraints.maxWidth * .26, child: search),
          ],
        );
      },
    );
  }
}
