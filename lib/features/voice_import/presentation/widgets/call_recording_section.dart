import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../data/call_recording_repository_impl.dart";
import "../../data/recording_supplier_source.dart";
import "../../domain/call_recording.dart";
import "../../domain/recording_supplier.dart";
import "../voice_file_page.dart";

/// 업무 상세(폰)의 "통화 녹음" 칸: 올린 녹음과 추가 버튼.
/// 견적 요청을 보낸 뒤에만 보입니다.
class CallRecordingSection extends ConsumerWidget {
  const CallRecordingSection({
    super.key,
    required this.suppliers,
    required this.onAdd,
  });

  /// The case and its requested suppliers, as passed to the add flow.
  final RecordingSupplierQuery suppliers;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = callRecordingsProvider(suppliers.caseId);
    final value = ref.watch(provider);
    // Keeps showing the last list while it reloads after an upload.
    final list = value.value;
    final items = list?.items ?? const <CallRecording>[];
    // A server without the feature just has no list: only the add tile.
    final failed = switch (value.error) {
      null => false,
      final CallRecordingFailure failure => !failure.unavailable,
      _ => true,
    };
    // Names are only needed once there is something to name.
    final requested = items.isEmpty
        ? null
        : ref.watch(recordingSuppliersProvider(suppliers));
    final names = {
      for (final supplier in requested?.value ?? const <RecordingSupplier>[])
        supplier.supplierId: supplier.name,
    };
    // Still reading the names is not the same as an unknown supplier.
    final unnamed = requested?.isLoading ?? false ? "거래처 확인 중" : "거래처 미확인";
    final limitReached = list?.limitReached ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          items.isEmpty ? "통화 녹음" : "통화 녹음 ${items.length}",
          style: const TextStyle(
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final recording in items) ...[
          _RecordingRow(
            recording: recording,
            supplierName: names[recording.supplierId] ?? unnamed,
          ),
          const SizedBox(height: 8),
        ],
        if (failed && list == null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  "올린 녹음을 불러오지 못했습니다.",
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: context.palette.muted,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(provider),
                style: WorkspaceButtonStyles.text(context),
                child: const Text("다시 시도"),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _AddTile(
          onTap: limitReached ? null : onAdd,
          caption: limitReached
              ? "업무 하나에 녹음은 ${list!.maxPerCase}개까지 올릴 수 있습니다."
              : "견적을 요청한 거래처와의 통화 녹음을 붙입니다.",
        ),
      ],
    );
  }
}

class _RecordingRow extends StatelessWidget {
  const _RecordingRow({required this.recording, required this.supplierName});

  final CallRecording recording;
  final String supplierName;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.palette.blush,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.graphic_eq,
            size: 20,
            color: context.palette.accentText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                supplierName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                recording.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppFontSizes.caption,
                  color: context.palette.muted,
                ),
              ),
              Text(
                "${formatSeoulDateTime(recording.uploadedAt ?? recording.createdAt)}"
                " · ${formatFileSize(recording.sizeBytes)}",
                style: TextStyle(
                  fontSize: AppFontSizes.caption,
                  color: context.palette.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StatusChip(recording),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.recording);

  final CallRecording recording;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (recording.status) {
      CallRecordingStatus.uploading => (
        Icons.schedule,
        const Color(0xFF2F5E8C),
        const Color(0xFFE6EEF6),
      ),
      CallRecordingStatus.uploaded => (
        Icons.check,
        const Color(0xFF00754A),
        const Color(0xFFE2F4EA),
      ),
      CallRecordingStatus.failed => (Icons.error_outline, danger, dangerTint),
      CallRecordingStatus.unknown => (
        Icons.help_outline,
        const Color(0xFF8A6516),
        const Color(0xFFF6EEDC),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            recording.statusLabel,
            style: TextStyle(fontSize: AppFontSizes.caption, color: color),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap, required this.caption});

  /// Null when the case cannot take another recording.
  final VoidCallback? onTap;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: CustomPaint(
        foregroundPainter: _DashedBorder(
          color: context.palette.muted.withValues(alpha: .5),
        ),
        child: Material(
          color: context.palette.surface.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.palette.blush,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic,
                      size: 20,
                      color: enabled
                          ? context.palette.accentText
                          : context.palette.muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "통화 녹음 추가",
                          style: TextStyle(
                            fontSize: AppFontSizes.body,
                            fontWeight: FontWeight.w700,
                            color: enabled
                                ? context.palette.accentText
                                : context.palette.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          caption,
                          style: TextStyle(
                            fontSize: AppFontSizes.caption,
                            color: context.palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.75),
          const Radius.circular(14),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 9) {
        canvas.drawPath(metric.extractPath(start, start + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => oldDelegate.color != color;
}
