import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/workspace_colors.dart";
import "../server_status_view_model.dart";

/// 검토 실행·메일 발송이 서버에서 막혀 있을 때만 보이는 안내 줄.
class ServerStatusBanner extends ConsumerWidget {
  const ServerStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(serverStatusViewModelProvider).asData?.value;
    if (status == null) return const SizedBox.shrink();
    final notices = [
      if (status.showReviewBanner)
        const _Notice(
          icon: Icons.warning_amber_rounded,
          title: "검토 실행 준비 안 됨",
          body: "서버의 검토 기능이 아직 준비되지 않아 지금은 검토를 시작할 수 없어요. 준비되면 이 안내는 저절로 사라져요.",
          color: accent,
          background: blush,
        ),
      if (status.showMailSendingBanner)
        const _Notice(
          icon: Icons.unsubscribe_outlined,
          title: "메일 발송 꺼짐",
          body: "서버에서 메일 발송이 꺼져 있어 승인해도 실제 메일은 나가지 않아요.",
          color: ink,
          background: line,
        ),
    ];
    if (notices.isEmpty) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final notice in notices) notice,
          const Divider(height: 1, thickness: 1, color: line),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "$title  ",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: body,
                      style: const TextStyle(color: ink),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: AppFontSizes.body,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
