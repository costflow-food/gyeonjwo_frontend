import 'package:flutter/material.dart';

import '../workspace_colors.dart';
import 'workspace_sidebar.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({super.key, required this.child});
  final Widget child;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  static const _minimumBodyWidth = 280.0;
  static const _collapsedSidebarWidth = 56.0;
  static const _sidebarDividerWidth = 1.0;

  // Keep the user's choice separate from the space available to display it.
  bool _sidebarOpen = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sidebarWidth = (constraints.maxWidth * .16).clamp(180.0, 216.0);
        final canExpandSidebar =
            constraints.maxWidth >=
            sidebarWidth + _sidebarDividerWidth + _minimumBodyWidth;
        final showSidebar = _sidebarOpen && canExpandSidebar;
        final showCollapsedSidebar =
            !showSidebar &&
            constraints.maxWidth >=
                _collapsedSidebarWidth + _sidebarDividerWidth;
        return Scaffold(
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showSidebar)
                  SizedBox(
                    width: sidebarWidth,
                    child: WorkspaceSidebar(
                      onCollapse: () => setState(() => _sidebarOpen = false),
                    ),
                  )
                else if (showCollapsedSidebar)
                  SizedBox(
                    width: _collapsedSidebarWidth,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: IconButton(
                          tooltip: canExpandSidebar
                              ? '사이드바 펼치기'
                              : '창을 넓히면 사이드바를 펼칠 수 있습니다',
                          onPressed: canExpandSidebar
                              ? () => setState(() => _sidebarOpen = true)
                              : null,
                          icon: const Icon(Icons.menu),
                        ),
                      ),
                    ),
                  ),
                if (showSidebar || showCollapsedSidebar)
                  const VerticalDivider(
                    width: _sidebarDividerWidth,
                    color: line,
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, viewport) {
                      final padding = (viewport.maxWidth * .03).clamp(
                        16.0,
                        36.0,
                      );
                      final content = SingleChildScrollView(
                        padding: EdgeInsets.all(padding),
                        child: widget.child,
                      );
                      if (viewport.maxWidth >= _minimumBodyWidth) {
                        return content;
                      }
                      // Preserve readable content in extremely narrow windows.
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: _minimumBodyWidth,
                          height: viewport.maxHeight,
                          child: content,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
