import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/mobile_scaffold.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../auth/presentation/gmail_connection_view_model.dart";
import "../../../mail_intake/presentation/mail_intake_view_model.dart";
import "../../../mail_intake/presentation/widgets/intake_sidebar_list.dart";
import "../widgets/gmail_read_notice.dart";
import "../widgets/queue_group_list.dart";
import "../work_queue_view_model.dart";

/// 폰의 첫 화면: 요약, 업무 큐 / 접수 확인 전환, 목록.
class MobileWorkQueueHome extends ConsumerStatefulWidget {
  const MobileWorkQueueHome({super.key});

  @override
  ConsumerState<MobileWorkQueueHome> createState() =>
      _MobileWorkQueueHomeState();
}

class _MobileWorkQueueHomeState extends ConsumerState<MobileWorkQueueHome> {
  bool _intake = false;

  void _refresh() {
    ref.read(workQueueViewModelProvider.notifier).refresh();
    ref.read(mailIntakeViewModelProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(workQueueViewModelProvider);
    final intake = ref.watch(mailIntakeViewModelProvider);
    final readDenied = ref.watch(gmailCapabilitiesProvider).readDenied;
    final data = queue.value;
    return MobileTabScaffold(
      actions: [
        IconButton(
          tooltip: "목록 새로고침",
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: RefreshIndicator(
        color: context.palette.accent,
        onRefresh: () async {
          _refresh();
          // Keep the spinner until the queue has reloaded.
          try {
            await ref.read(workQueueViewModelProvider.future);
          } catch (_) {
            // The list shows the error.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (readDenied) ...[
              const GmailReadNotice(),
              const SizedBox(height: 12),
            ],
            _Summary(waitingCount: data?.allWaiting ?? data?.counts.waiting),
            const SizedBox(height: 14),
            _ListSwitch(
              intake: _intake,
              queueCount: data?.counts.total,
              intakeCount: intake.value?.totalPending,
              onChanged: (value) => setState(() => _intake = value),
            ),
            const SizedBox(height: 12),
            if (_intake)
              const IntakeSidebarList(shrinkWrap: true)
            else
              const QueueGroupList(shrinkWrap: true),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.waitingCount});

  final int? waitingCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [context.palette.accentText, context.palette.deep],
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "검토를 기다리는 요청",
                style: TextStyle(
                  fontSize: AppFontSizes.secondary,
                  color: context.palette.onDeepMuted,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "흩어진 요청을, 한눈에 검토하십시오.",
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: (waitingCount ?? 0).toString().padLeft(2, "0"),
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const TextSpan(text: "건", style: TextStyle(fontSize: 15)),
            ],
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    ),
  );
}

/// 업무 큐 / 접수 확인. 웹은 사이드바 탭에 있던 전환입니다.
class _ListSwitch extends StatelessWidget {
  const _ListSwitch({
    required this.intake,
    required this.queueCount,
    required this.intakeCount,
    required this.onChanged,
  });

  final bool intake;
  final int? queueCount;
  final int? intakeCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: context.palette.frame,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        _segment(context, "업무 큐", queueCount, selected: !intake, value: false),
        _segment(context, "접수 확인", intakeCount, selected: intake, value: true),
      ],
    ),
  );

  Widget _segment(
    BuildContext context,
    String label,
    int? count, {
    required bool selected,
    required bool value,
  }) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? context.palette.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? context.palette.ink
                        : context.palette.muted,
                  ),
                ),
                if (count != null && count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.blush,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "$count",
                      style: TextStyle(
                        fontSize: AppFontSizes.captionSmall,
                        fontWeight: FontWeight.w700,
                        color: context.palette.accentText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
