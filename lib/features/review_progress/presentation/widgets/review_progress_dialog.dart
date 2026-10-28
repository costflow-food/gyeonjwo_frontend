import "package:flutter/material.dart";

import "../../../../shared/workspace_colors.dart";
import "review_progress_header.dart";
import "review_progress_footer.dart";

class ReviewProgressDialog extends StatelessWidget {
  const ReviewProgressDialog({
    super.key,
    required this.supplier,
    required this.complete,
    required this.body,
    required this.onClose,
    required this.onViewResult,
  });

  final String supplier;
  final bool complete;
  final Widget body;
  final VoidCallback onClose, onViewResult;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReviewProgressHeader(supplier: supplier, onClose: onClose),
              const Divider(height: 1, color: line),
              body,
              const Divider(height: 1, color: line),
              ReviewProgressFooter(
                complete: complete,
                onViewResult: onViewResult,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
