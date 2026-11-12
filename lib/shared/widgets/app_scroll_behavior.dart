import 'package:flutter/material.dart';

/// Scrolling stops at the edge: no Android stretch (or glow) when the user
/// pulls past the end of a list. Pull-to-refresh is separate and still works.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
