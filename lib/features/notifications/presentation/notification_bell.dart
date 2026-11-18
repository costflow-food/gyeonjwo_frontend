import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../app/app_paths.dart";
import "../../../shared/lds_colors.dart";
import "../../../shared/widgets/lds/lds.dart";
import "../../mail_intake/presentation/mail_intake_dialog.dart";
import "notifications_view_model.dart";

/// 상단 바 알림 단추: 안 읽은 알림이 있으면 오른쪽 위 빨간 점. 누르면 단추
/// 오른쪽 끝에 맞춘 알림 목록 팝오버.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread =
        ref.watch(notificationsViewModelProvider).value?.hasUnread ?? false;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Builder(
          builder: (context) => LdsIconButton(
            icon: Icons.notifications_none,
            tooltip: unread ? "알림, 새 알림 있음" : "알림",
            onPressed: () {
              ref.read(notificationsViewModelProvider.notifier).refresh();
              Navigator.of(context).push(
                LdsPopoverRoute<void>(
                  anchor: LdsPopoverRoute.anchorOf(context),
                  label: "알림 닫기",
                  child: const _NotificationPanel(),
                ),
              );
            },
          ),
        ),
        if (unread)
          const Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: SizedBox.square(
                dimension: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: LdsColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationPanel extends ConsumerWidget {
  const _NotificationPanel();

  static const width = 280.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(notificationsViewModelProvider);
    final data = value.value;
    Widget message(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: LdsColors.muted),
      ),
    );
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "알림",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: LdsColors.ink,
                    ),
                  ),
                ),
                LdsButton(
                  label: "모두 읽음",
                  size: LdsButtonSize.small,
                  variant: LdsButtonVariant.ghostNeutral,
                  onPressed: data?.hasUnread ?? false
                      ? ref
                            .read(notificationsViewModelProvider.notifier)
                            .markAllRead
                      : null,
                ),
              ],
            ),
          ),
          if (data == null && value.hasError)
            message("알림을 불러오지 못했어요")
          else if (data == null)
            message("불러오는 중이에요")
          else if (data.items.isEmpty)
            message("새 알림이 없어요")
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  for (final item in data.items)
                    _NotificationRow(
                      item: item,
                      unread: !data.isRead(item),
                      onTap: _open(context, item),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 알림을 누르면 갈 곳: 검토 카드 준비 → 그 검토 카드, 업무가 있는 알림 →
/// 그 업무 상세, 업무에 아직 붙지 않은 새 메일 → 접수·연결 확인 창.
/// 갈 곳이 없으면 null(누를 수 없음).
VoidCallback? _open(BuildContext context, AppNotification item) {
  final caseId = item.caseId;
  if (caseId == null) {
    if (item.kind != AppNotificationKind.mailReceived) return null;
    return () {
      final navigator = Navigator.of(context);
      navigator.pop();
      showMailIntakeDialog(navigator.context);
    };
  }
  final path = item.kind == AppNotificationKind.reviewReady
      ? AppPaths.review(caseId)
      : AppPaths.task(caseId);
  return () {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(path);
  };
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.unread,
    required this.onTap,
  });

  final AppNotification item;
  final bool unread;
  final VoidCallback? onTap;

  (IconData, Color, Color) get _look => switch (item.kind) {
    AppNotificationKind.mailReceived => (
      Icons.mark_email_unread_outlined,
      LdsColors.primary,
      LdsColors.primarySoft,
    ),
    AppNotificationKind.needsAttention => (
      Icons.pause_circle_outline,
      LdsColors.warning,
      LdsColors.warningBg,
    ),
    AppNotificationKind.reviewReady => (
      Icons.task_outlined,
      LdsColors.success,
      LdsColors.successBg,
    ),
    AppNotificationKind.sendFailed || AppNotificationKind.reviewFailed => (
      Icons.error_outline,
      LdsColors.error,
      LdsColors.errorBg,
    ),
  };

  static String _ago(DateTime at) {
    final gap = DateTime.now().difference(at);
    if (gap.inMinutes < 1) return "이제";
    if (gap.inHours < 1) return "${gap.inMinutes}분 전";
    if (gap.inDays < 1) return "${gap.inHours}시간 전";
    return "${gap.inDays}일 전";
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = _look;
    return InkWell(
      onTap: onTap,
      hoverColor: LdsColors.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.kind.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                      color: LdsColors.ink,
                    ),
                  ),
                  if (item.detail.isNotEmpty)
                    Text(
                      item.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: LdsColors.label,
                      ),
                    ),
                  Text(
                    _ago(item.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: LdsColors.outline,
                    ),
                  ),
                ],
              ),
            ),
            if (unread)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 6),
                child: SizedBox.square(
                  dimension: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: LdsColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
