import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/workspace_colors.dart";
import "../../../shared/widgets/preview_button.dart";

import "../domain/supplier_evidence.dart";
import "supplier_evidence_view_model.dart";
import "../../../shared/widgets/async_content.dart";
import 'widgets/scroll_more_hint.dart';
import 'widgets/supplier_evidence_content.dart';

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
        builder: (evidence) => SupplierEvidenceContent(evidence: evidence),
      ),
    );
    final footer = Padding(
      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 18),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: PreviewButton('원문·자료 보기', icon: Icons.description_outlined),
      ),
    );
    const divider = Divider(height: 1, color: line);

    return Dialog(
      backgroundColor: canvas,
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
              return ScrollMoreHint(
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
                Flexible(child: ScrollMoreHint(child: body)),
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
