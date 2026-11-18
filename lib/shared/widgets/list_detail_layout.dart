import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../lds_colors.dart";
import "workspace_shell.dart";

/// 목록 칸 + 상세 칸 (`docs/design-ssot.md` 7.18): Tasks · Suppliers ·
/// Transactions가 같이 씁니다. [WorkspaceShell]`(scrollable: false)` 안에 두면
/// 목록과 상세가 각각 따로 스크롤합니다.
///
/// 넓은 화면: 왼쪽 끝에 목록 칸(`#F3F4F6` + 오른쪽 1px 선), 나머지는 상세 칸
/// (`#F9FAFB`, 내용 최대 [detailMaxWidth]를 목록 쪽에 붙임).
/// [singlePaneWidth] 이하: 한 화면씩 — 목록, 또는 '목록으로'가 있는 상세.
class ListDetailLayout extends StatelessWidget {
  const ListDetailLayout({
    super.key,
    required this.list,
    required this.detail,
    required this.detailAlone,
    required this.onBack,
    this.detailPadding = const EdgeInsets.all(24),
  });

  /// 이 폭 이하에서는 목록과 상세를 한 화면씩 보여 줍니다(7.18).
  static const singlePaneWidth = 1100.0;

  /// 상세 내용 최대 폭(7.18).
  static const detailMaxWidth = 1040.0;

  /// 목록 영역 전체 = 400px, 안쪽 좌우 16px (2026-11-18 최종 HTML).
  static double listWidth(double screenWidth) => 400.0;

  /// 목록 칸 오른쪽 안쪽 여백(시안 16).
  static const listRightPadding = 16.0;

  /// 화면 폭이 [singlePaneWidth] 이하인지(한 화면씩).
  static bool isSinglePane(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= singlePaneWidth;

  /// 목록: 칸 안쪽 여백과 넓은 화면(목록·상세 나란히) 여부를 받아 만듭니다.
  final Widget Function(EdgeInsets padding, bool wide) list;

  /// 상세 칸 내용. 상세 칸이 스크롤과 여백을 둡니다.
  final WidgetBuilder detail;

  /// 한 화면씩일 때 목록 대신 상세를 보여 줄지.
  final bool detailAlone;

  /// 한 화면씩 보는 상세의 '목록으로'.
  final VoidCallback onBack;
  final EdgeInsets detailPadding;

  static const _gutter = WorkspaceShell.gutter;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final screen = MediaQuery.sizeOf(context).width;
      if (screen <= singlePaneWidth) {
        // 한 화면씩: 목록, 또는 '목록으로'가 있는 상세.
        if (!detailAlone) return list(const EdgeInsets.all(_gutter), false);
        return ColoredBox(
          color: LdsColors.canvas,
          child: _DetailScroll(
            padding: detailPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text("목록으로"),
                ),
                const SizedBox(height: 8),
                detail(context),
              ],
            ),
          ),
        );
      }
      // 목록 칸 #F3F4F6 + 오른쪽 1px 선, 상세 칸 #F9FAFB (시안).
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: listWidth(screen),
            decoration: const BoxDecoration(
              color: LdsColors.lineSoft,
              border: Border(right: BorderSide(color: LdsColors.line)),
            ),
            child: list(
              const EdgeInsets.fromLTRB(16, _gutter, listRightPadding, _gutter),
              true,
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: LdsColors.canvas,
              child: _DetailScroll(
                padding: detailPadding,
                child: detail(context),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// 상세 칸: 위 24에서 시작, 최대 1040을 목록 쪽에 붙이고 오른쪽 여백 24.
/// 남는 폭은 상세 오른쪽 끝에만 둡니다(7.18).
class _DetailScroll extends StatelessWidget {
  const _DetailScroll({required this.child, required this.padding});

  final EdgeInsets padding;

  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: padding,
    child: Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ListDetailLayout.detailMaxWidth,
        ),
        child: child,
      ),
    ),
  );
}

/// 목록 칸 안: 위쪽 머리(검색·필터·건수)는 그대로, 아래 [body]만 스크롤.
/// [padding]은 [ListDetailLayout.list]가 준 칸 안쪽 여백입니다.
class ListPaneColumn extends StatelessWidget {
  const ListPaneColumn({
    super.key,
    required this.padding,
    required this.header,
    required this.body,
  });

  final EdgeInsets padding;
  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: EdgeInsets.fromLTRB(
          padding.left,
          padding.top,
          padding.right,
          0,
        ),
        child: header,
      ),
      const SizedBox(height: 12),
      Expanded(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            0,
            padding.right,
            padding.bottom,
          ),
          child: body,
        ),
      ),
    ],
  );
}

/// 목록(행)에 초점이 있을 때 ↑/↓: [onStep]에 -1·+1을 넘기고, 다음 그림에서
/// [selectedKey]가 붙은 행이 보이게 스크롤합니다. 고른 행이 다시 그려져도
/// 이어서 누를 수 있게 초점은 목록이 받습니다.
class ListArrowKeys extends StatefulWidget {
  const ListArrowKeys({
    super.key,
    required this.onStep,
    required this.child,
    this.selectedKey,
  });

  final ValueChanged<int> onStep;
  final GlobalKey? selectedKey;
  final Widget child;

  @override
  State<ListArrowKeys> createState() => _ListArrowKeysState();
}

class _ListArrowKeysState extends State<ListArrowKeys> {
  final _focus = FocusNode(debugLabel: "목록", skipTraversal: true);

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.arrowUp => -1,
      _ => 0,
    };
    if (step == 0) return KeyEventResult.ignored;
    widget.onStep(step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      final row = widget.selectedKey?.currentContext;
      if (row == null || !row.mounted) return;
      Scrollable.ensureVisible(
        row,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      Scrollable.ensureVisible(
        row,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    onKeyEvent: _onKey,
    // 행을 누르면 목록이 초점을 받아 바로 ↑/↓를 쓸 수 있습니다.
    child: Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _focus.requestFocus(),
      child: widget.child,
    ),
  );
}

/// 목록 묶음 상자: 흰 바탕, 1px `#E5E7EA`, 모서리 12, 줄 사이 1px `#F3F4F6`.
class ListGroupBox extends StatelessWidget {
  const ListGroupBox({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: LdsColors.line),
      borderRadius: BorderRadius.circular(8),
    ),
    // 테두리 안쪽(11)으로 깎아 고른 줄 바탕이 모서리를 넘지 않게 합니다.
    child: ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0) const Divider(height: 1, color: LdsColors.lineSoft),
            child,
          ],
        ],
      ),
    ),
  );
}

/// 목록 한 줄의 틀: 흰 바탕(고르면 `#E8EBEF` + 왼쪽 먹색 3px), 좌우 16·12.
class ListSelectableRow extends StatelessWidget {
  const ListSelectableRow({
    super.key,
    required this.selected,
    required this.onTap,
    required this.semanticLabel,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: semanticLabel,
    excludeSemantics: true,
    onTap: onTap,
    child: Material(
      color: selected ? LdsColors.selectedRow : Colors.white,
      child: InkWell(
        onTap: onTap,
        hoverColor: LdsColors.canvas,
        child: Stack(
          children: [
            if (selected)
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: ColoredBox(color: LdsColors.title),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: child,
            ),
          ],
        ),
      ),
    ),
  );
}
