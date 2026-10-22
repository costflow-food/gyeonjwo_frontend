import 'package:flutter/material.dart';

import '../../../shared/workspace_colors.dart';

import 'queue_tab.dart';

class QueueToolbar extends StatelessWidget {
  const QueueToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    const tabs = Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        QueueTab('전체', '6'),
        QueueTab('검토 대기', '2'),
        QueueTab('완료', '2'),
        QueueTab('검토 필요', '1'),
        QueueTab('제외', '1'),
      ],
    );
    const search = TextField(
      readOnly: true,
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
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [tabs, SizedBox(height: 16), search],
          );
        }
        return Row(
          children: [
            const Expanded(child: tabs),
            const SizedBox(width: 20),
            SizedBox(width: constraints.maxWidth * .26, child: search),
          ],
        );
      },
    );
  }
}
