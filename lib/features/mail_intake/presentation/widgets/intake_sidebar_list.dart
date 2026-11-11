import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/workspace_colors.dart";
import "../mail_intake_dialog.dart";
import "../mail_intake_view_model.dart";
import "intake_load_more.dart";

class IntakeSidebarList extends ConsumerWidget {
  const IntakeSidebarList({super.key, this.shrinkWrap = false});

  /// Inside a scrolling page (the phone home), with each row on a card.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(mailIntakeViewModelProvider);
    if (!value.hasValue) {
      if (value.hasError) {
        return _Message(
          "접수 확인 목록을 불러오지 못했습니다.",
          action: TextButton(
            onPressed: ref.read(mailIntakeViewModelProvider.notifier).refresh,
            child: const Text("다시 시도"),
          ),
        );
      }
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final page = value.requireValue;
    final mails = page.items;
    if (mails.isEmpty) return const _Message("확인할 메일이 없습니다.");
    final more = page.nextCursor != null;
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.zero,
      itemCount: mails.length + (more ? 1 : 0),
      separatorBuilder: (_, _) => SizedBox(height: shrinkWrap ? 8 : 2),
      itemBuilder: (context, index) {
        if (index == mails.length) {
          return IntakeLoadMore(
            loading: page.loadingMore,
            onPressed: ref.read(mailIntakeViewModelProvider.notifier).loadMore,
          );
        }
        final mail = mails[index];
        final received = formatSeoulDateTime(mail.receivedAt);
        return Material(
          color: shrinkWrap ? context.palette.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => showMailIntakeDialog(context, mailId: mail.mailId),
            child: Padding(
              padding: shrinkWrap
                  ? const EdgeInsets.fromLTRB(14, 12, 12, 12)
                  : const EdgeInsets.fromLTRB(10, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mail.subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSizes.body,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mail.sender,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppFontSizes.secondary,
                      color: context.palette.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6EEDC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          mail.reason.label,
                          style: const TextStyle(
                            fontSize: AppFontSizes.caption,
                            color: Color(0xFF8A6516),
                          ),
                        ),
                      ),
                      Text(
                        received.length > 5 ? received.substring(5) : received,
                        style: TextStyle(
                          fontSize: AppFontSizes.caption,
                          color: context.palette.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: AppFontSizes.secondary,
            color: context.palette.muted,
          ),
        ),
        ?action,
      ],
    ),
  );
}
