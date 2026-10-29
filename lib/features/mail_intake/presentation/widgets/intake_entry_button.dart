import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/widgets/preview_button.dart";
import "../mail_intake_dialog.dart";
import "../mail_intake_view_model.dart";

/// Work queue entry for SCR-009. Hidden when nothing is pending; the count
/// is kept apart from the case status counts.
class IntakeEntryButton extends ConsumerWidget {
  const IntakeEntryButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(mailIntakeViewModelProvider).asData?.value.totalPending;
    if (total == null || total == 0) return const SizedBox.shrink();
    return PreviewButton(
      "접수 확인 $total건",
      icon: Icons.mark_email_unread_outlined,
      onPressed: () => showMailIntakeDialog(context),
    );
  }
}
