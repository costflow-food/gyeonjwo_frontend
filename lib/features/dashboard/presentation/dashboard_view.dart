import "package:flutter/material.dart";

import "../../work_queue/presentation/work_queue_view.dart";

/// Dashboard (`/`, SSOT 7.9). 상태 카드가 들어오기 전까지는 기존 첫 화면을
/// 그대로 보여 줍니다.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) => const WorkQueueView();
}
