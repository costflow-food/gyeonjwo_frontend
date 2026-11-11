import 'package:flutter/material.dart';

import '../workspace_colors.dart';
import 'mobile_scaffold.dart';

/// Frame for the workspace's header / body / footer dialogs: a centered panel
/// on wide screens, the whole screen on a phone.
class WorkspaceDialog extends StatelessWidget {
  const WorkspaceDialog({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  final double maxWidth;

  /// A column of header, [DialogScrollArea] and footer.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isCompactLayout(context)) {
      return Dialog.fullscreen(
        backgroundColor: context.palette.canvas,
        child: SafeArea(child: child),
      );
    }
    return Dialog(
      backgroundColor: context.palette.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// The scrolling middle of a [WorkspaceDialog]. Full screen, it fills the
/// space so the footer stays at the bottom.
class DialogScrollArea extends StatelessWidget {
  const DialogScrollArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Flexible(
    fit: isCompactLayout(context) ? FlexFit.tight : FlexFit.loose,
    child: child,
  );
}
