import "package:flutter/material.dart";

import "../../../../shared/widgets/mobile_scaffold.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/review_phase.dart";
import "review_progress_header.dart";
import "review_progress_footer.dart";

class ReviewProgressDialog extends StatelessWidget {
  const ReviewProgressDialog({
    super.key,
    required this.title,
    required this.outcome,
    required this.body,
    required this.onClose,
    required this.onViewCase,
  });

  final String title;

  /// null while the server is still working.
  final ReviewOutcome? outcome;
  final Widget body;
  final VoidCallback onClose, onViewCase;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReviewProgressHeader(title: title, onClose: onClose),
        Divider(height: 1, color: context.palette.line),
        body,
        Divider(height: 1, color: context.palette.line),
        ReviewProgressFooter(outcome: outcome, onViewCase: onViewCase),
      ],
    );
    // Phone: shown in a bottom sheet, which brings its own frame.
    if (isCompactLayout(context)) {
      return SingleChildScrollView(child: SafeArea(top: false, child: content));
    }
    return _dialog(context, content);
  }

  Widget _dialog(BuildContext context, Widget content) => Dialog(
    backgroundColor: context.palette.surface,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 760,
        maxHeight: MediaQuery.sizeOf(context).height - 40,
      ),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: "검토 진행",
        child: SingleChildScrollView(child: content),
      ),
    ),
  );
}
