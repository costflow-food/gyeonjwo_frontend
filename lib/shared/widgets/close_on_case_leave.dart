import "package:flutter/widgets.dart";
import "package:go_router/go_router.dart";

/// Closes the modal route this widget sits in once the app moves to a screen
/// that is not [caseId] (e.g. another case picked in the queue, or the
/// browser's back button). Opening the case itself (/cases/:id and its
/// subpaths such as /review) keeps it open.
///
/// [keepOpen] can hold the route open, e.g. while there are unsaved edits or a
/// send is in flight; the route is then left to the user to close.
class CloseOnCaseLeave extends StatefulWidget {
  const CloseOnCaseLeave({
    super.key,
    required this.router,
    required this.caseId,
    required this.child,
    this.keepOpen,
  });

  /// Without a router (e.g. a widget test) this widget does nothing.
  final GoRouter? router;
  final String caseId;
  final Widget child;
  final bool Function()? keepOpen;

  @override
  State<CloseOnCaseLeave> createState() => _CloseOnCaseLeaveState();
}

class _CloseOnCaseLeaveState extends State<CloseOnCaseLeave> {
  String? _openedAt;
  ModalRoute<Object?>? _route;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    final router = widget.router;
    if (router != null) {
      _openedAt = router.routerDelegate.currentConfiguration.uri.path;
      router.routerDelegate.addListener(_onRouteChanged);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    widget.router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    final router = widget.router;
    if (router == null || _closing || !mounted) return;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (!leavesCase(path, caseId: widget.caseId, openedAt: _openedAt)) return;
    if (widget.keepOpen?.call() ?? false) return;
    _closing = true;
    // Not during the router's own notification: remove only this route,
    // whatever else is open on top of it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = _route;
      if (!mounted || route == null || !route.isActive) return;
      route.navigator?.removeRoute(route);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Whether moving to [path] leaves the case [caseId] that a window was opened
/// for. The screen it was opened on ([openedAt]) and the case's own pages
/// do not count as leaving.
bool leavesCase(String path, {required String caseId, String? openedAt}) {
  final ownCase = "/cases/$caseId";
  return !(path == openedAt || path == ownCase || path.startsWith("$ownCase/"));
}
