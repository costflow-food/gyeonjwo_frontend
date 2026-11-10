import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../mailbox_sync_view_model.dart";

/// 메일함 수신이 멈췄거나 늦어질 때만 보이는 안내 줄(S1-2).
/// 새 메일과 거래처 회신이 목록에 없는 이유를 알려 줍니다.
class MailboxSyncBanner extends ConsumerWidget {
  const MailboxSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(mailboxSyncViewModelProvider).asData?.value;
    if (status == null) return const SizedBox.shrink();
    final failed = status.failed;
    if (!failed && !status.isStale(DateTime.now())) {
      return const SizedBox.shrink();
    }
    final last = status.lastSyncedAt == null
        ? "마지막 수신 시각을 알 수 없어요."
        : "마지막 수신 ${formatSeoulDateTime(status.lastSyncedAt!.toUtc().toIso8601String())}.";
    final title = failed ? "메일 수신 멈춤" : "메일 수신 지연";
    final body = failed
        ? "$last 서버가 메일함을 읽지 못하고 있어 그 뒤에 온 메일과 거래처 회신은 아직 목록에 없어요."
        : "$last 그 뒤에 온 메일과 거래처 회신은 아직 목록에 없을 수 있어요.";
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: failed ? dangerTint : line,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 16,
                      color: failed ? danger : ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "$title  ",
                            style: TextStyle(
                              color: failed ? danger : ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: body),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: AppFontSizes.body,
                        color: ink,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: line),
        ],
      ),
    );
  }
}
