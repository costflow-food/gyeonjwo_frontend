import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/workspace_colors.dart";
import "../../../shared/widgets/preview_button.dart";

import "../domain/supplier_evidence.dart";
import "supplier_evidence_view_model.dart";
import "../../../shared/widgets/async_content.dart";
import 'widgets/cost_line.dart';
import 'widgets/evidence_block.dart';
import 'widgets/impact_panel.dart';

Future<void> showSupplierEvidence(
  BuildContext context, {
  required String requestId,
  required String supplierLetter,
  required int supplierCount,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => SupplierEvidenceView(
      requestId: requestId,
      supplierLetter: supplierLetter,
      supplierCount: supplierCount,
    ),
  );
}

class SupplierEvidenceView extends ConsumerWidget {
  const SupplierEvidenceView({
    super.key,
    required this.requestId,
    required this.supplierLetter,
    required this.supplierCount,
  });

  final String requestId, supplierLetter;
  final int supplierCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = supplierEvidenceViewModelProvider(
      requestId,
      supplierLetter,
    );
    final value = ref.watch(provider);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final gutter = compact ? 18.0 : 28.0;

    final header = Padding(
      padding: EdgeInsets.fromLTRB(gutter, 22, 12, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$supplierLetter사 상세 근거',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.value?.subtitle ?? '',
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '닫기',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20, color: ink),
          ),
        ],
      ),
    );
    final body = Padding(
      padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 28),
      child: AsyncContent<SupplierEvidence>(
        value: value,
        onRetry: ref.read(provider.notifier).refresh,
        builder: (evidence) => _SupplierEvidenceContent(evidence: evidence),
      ),
    );
    final footer = Padding(
      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 18),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 10,
        children: [
          const PreviewButton('원문·자료 보기', icon: Icons.description_outlined),
          PreviewButton(
            '$supplierCount개 카드로 돌아가기',
            filled: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
    const divider = Divider(height: 1, color: line);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 40,
        vertical: compact ? 12 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 높이가 부족하면 머리글과 버튼까지 함께 스크롤합니다.
            if (constraints.maxHeight < 420 * textScale) {
              return _ScrollMoreHint(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [header, divider, body, divider, footer],
                ),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                divider,
                Flexible(child: _ScrollMoreHint(child: body)),
                divider,
                footer,
              ],
            );
          },
        ),
      ),
    );
  }
}

// 아래에 내용이 더 남아 있으면 하단에 화살표를 띄우고, 누르면 한 화면쯤 내려갑니다.
class _ScrollMoreHint extends StatefulWidget {
  const _ScrollMoreHint({required this.child});

  final Widget child;

  @override
  State<_ScrollMoreHint> createState() => _ScrollMoreHintState();
}

class _ScrollMoreHintState extends State<_ScrollMoreHint> {
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
      (position.pixels + position.viewportDimension * 0.8)
          .clamp(0.0, position.maxScrollExtent),
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
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white,
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.white,
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

class _SupplierEvidenceContent extends StatelessWidget {
  const _SupplierEvidenceContent({required this.evidence});

  final SupplierEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final lines = evidence.costLines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImpactPanel(evidence: evidence),
        const SizedBox(height: 12),
        for (var i = 0; i < lines.length; i++)
          CostLine(lines[i], divider: i < lines.length - 1),
        if (evidence.crossCheckFormulas.isNotEmpty) ...[
          const SizedBox(height: 28),
          EvidenceBlock(
            '차액 교차 확인',
            body: evidence.crossCheckNote,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 0, 18),
                child: Text(
                  evidence.crossCheckFormulas.join("\n"),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.9,
                    fontFamily: 'monospace',
                    fontFamilyFallback: ['Consolas', 'Courier New'],
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          evidence.disclaimer,
          style: const TextStyle(fontSize: 9, color: muted, height: 1.6),
        ),
        for (final section in evidence.sections) ...[
          const SizedBox(height: 26),
          EvidenceBlock(section.title, body: section.body, tag: section.tag),
        ],
      ],
    );
  }
}
