import 'package:flutter/material.dart';

import "../../../../shared/workspace_colors.dart";

// 아래에 내용이 더 남아 있으면 하단에 화살표를 띄우고, 누르면 한 화면쯤 내려갑니다.
class ScrollMoreHint extends StatefulWidget {
  const ScrollMoreHint({super.key, required this.child});

  final Widget child;

  @override
  State<ScrollMoreHint> createState() => _ScrollMoreHintState();
}

class _ScrollMoreHintState extends State<ScrollMoreHint> {
  final _controller = ScrollController();
  var _hasMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    final hasMore = position.hasContentDimensions && position.extentAfter > 8;
    if (hasMore != _hasMore) setState(() => _hasMore = hasMore);
  }

  void _scrollDown() {
    final position = _controller.position;
    _controller.animateTo(
      (position.pixels + position.viewportDimension * 0.8).clamp(
        0.0,
        position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            _update();
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) {
              _update();
              return false;
            },
            child: SingleChildScrollView(
              controller: _controller,
              child: widget.child,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: !_hasMore,
            child: AnimatedOpacity(
              opacity: _hasMore ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                height: 56,
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [canvas.withValues(alpha: 0), canvas],
                  ),
                ),
                child: Material(
                  color: canvas,
                  shape: const CircleBorder(side: BorderSide(color: line)),
                  elevation: 1,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _scrollDown,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Tooltip(
                        message: '아래에 내용이 더 있어요',
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
