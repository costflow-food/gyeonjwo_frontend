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

/// 업무 상세(폰)의 "통화 녹음" 칸: 올린 녹음, 추가 버튼, 골라서 삭제.
/// 견적 요청을 보낸 뒤에만 보입니다.
class CallRecordingSection extends ConsumerStatefulWidget {
  const CallRecordingSection({
    super.key,
    required this.suppliers,
    required this.onAdd,
  });

  /// The case and its requested suppliers, as passed to the add flow.
  final RecordingSupplierQuery suppliers;
  final VoidCallback onAdd;

  @override
  ConsumerState<CallRecordingSection> createState() =>
      _CallRecordingSectionState();
}

class _CallRecordingSectionState extends ConsumerState<CallRecordingSection> {
  /// Choosing recordings to delete: rows show a check box instead of opening
  /// nothing, and the add tile is closed.
  bool _selecting = false;
  final _chosen = <String>{};

  /// The chosen recordings are being deleted.
  bool _deleting = false;

  /// Deleted here; hidden at once, before the reloaded list arrives.
  final _removed = <String>{};

  void _stopSelecting() => setState(() {
    _selecting = false;
    _chosen.clear();
  });

  Future<void> _delete(
    List<CallRecording> chosen,
    Map<String, String> names,
    String unnamed,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _DeleteDialog(recordings: chosen, names: names, unnamed: unnamed),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    final caseId = widget.suppliers.caseId;
    final provider = callRecordingsProvider(caseId);
    // Taken now: the loop may outlive this widget (the user leaves the case),
    // and `ref` cannot be used after that.
    final container = ProviderScope.containerOf(context, listen: false);
    final repository = container.read(callRecordingRepositoryProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final unsure = <String>[];
    // One at a time: at most ten, and each answer is known before the next.
    for (final recording in chosen) {
      try {
        await repository.deleteRecording(caseId, recording.recordingId);
        _removed.add(recording.recordingId);
      } on CallRecordingFailure {
        unsure.add(recording.recordingId);
      }
    }
    // The reloaded list decides what failed: a request whose answer was lost
    // may have deleted the recording all the same.
    var failed = unsure.length;
    try {
      final list = await container.refresh(provider.future);
      final left = {for (final item in list.items) item.recordingId};
      failed = unsure.where(left.contains).length;
    } catch (_) {
      // No list to check against: report what the requests said.
    }
    // The messenger outlives this section, but not the whole app's screens.
    if (messenger == null || !messenger.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? "녹음 ${chosen.length}개를 삭제했습니다."
              : chosen.length == 1
              ? "녹음을 삭제하지 못했습니다. 다시 시도해 주세요."
              : "${chosen.length}개 중 $failed개를 삭제하지 못했습니다. 다시 시도해 주세요.",
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _deleting = false;
      _selecting = false;
      _chosen.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = widget.suppliers;
    final provider = callRecordingsProvider(suppliers.caseId);
    final value = ref.watch(provider);
    // Keeps showing the last list while it reloads after an upload.
    final list = value.value;
    final items = [
      for (final item in list?.items ?? const <CallRecording>[])
        if (!_removed.contains(item.recordingId)) item,
    ];
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
    // Counted over what is shown, so a slot freed by a delete opens at once.
    // Failed recordings do not count, as in [CallRecordingList.limitReached].
    final limitReached =
        list != null &&
        items
                .where((item) => item.status != CallRecordingStatus.failed)
                .length >=
            list.maxPerCase;
    // Nothing left to choose from ends the choosing.
    final selecting = _selecting && items.isNotEmpty;
    // A recording that left the list is no longer chosen.
    final chosen = [
      for (final item in items)
        if (_chosen.contains(item.recordingId)) item,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          // As tall as its tallest state, so the rows below do not move
          // when the buttons appear.
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _deleting
                      ? "삭제하는 중"
                      : !selecting
                      ? (items.isEmpty ? "통화 녹음" : "통화 녹음 ${items.length}")
                      : chosen.isEmpty
                      ? "삭제할 녹음 선택"
                      : "${chosen.length}개 선택",
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_deleting)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (selecting) ...[
                TextButton(
                  onPressed: _stopSelecting,
                  style: WorkspaceButtonStyles.text(
                    context,
                  ).copyWith(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text("취소"),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: chosen.isEmpty
                      ? null
                      : () => _delete(chosen, names, unnamed),
                  style: FilledButton.styleFrom(
                    backgroundColor: danger,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: context.palette.line,
                    disabledForegroundColor: context.palette.muted,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("삭제"),
                ),
              ] else if (items.isNotEmpty && (list?.deletable ?? false))
                IconButton(
                  tooltip: "녹음 삭제",
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _selecting = true),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 22,
                    color: context.palette.muted,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        for (final recording in items) ...[
          _RecordingRow(
            recording: recording,
            supplierName: names[recording.supplierId] ?? unnamed,
            selecting: selecting,
            selected: _chosen.contains(recording.recordingId),
            fading: _deleting && _chosen.contains(recording.recordingId),
            onToggle: _deleting
                ? null
                : () => setState(() {
                    if (!_chosen.remove(recording.recordingId)) {
                      _chosen.add(recording.recordingId);
                    }
                  }),
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
          // Closed while recordings are being chosen or deleted.
          onTap: limitReached || selecting || _deleting ? null : widget.onAdd,
          caption: limitReached
              ? "업무 하나에 녹음은 ${list.maxPerCase}개까지 올릴 수 있습니다."
              : "견적을 요청한 거래처와의 통화 녹음을 붙입니다.",
        ),
      ],
    );
  }
}

/// "녹음 N개를 삭제하시겠습니까?" with the chosen recordings named again.
class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({
    required this.recordings,
    required this.names,
    required this.unnamed,
  });

  final List<CallRecording> recordings;
  final Map<String, String> names;
  final String unnamed;

  /// More than this many are summed up as "외 N개".
  static const _shown = 3;

  @override
  Widget build(BuildContext context) {
    final rest = recordings.length - _shown;
    return AlertDialog(
      title: const Text("녹음 삭제"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "${recordings.length == 1 ? "이 통화 녹음을" : "통화 녹음 ${recordings.length}개를"}"
              " 삭제하시겠습니까? 올린 파일까지 지워지며 되돌릴 수 없습니다.",
              style: const TextStyle(fontSize: AppFontSizes.body, height: 1.6),
            ),
            const SizedBox(height: 6),
            for (final recording in recordings.take(_shown))
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.palette.panel,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      names[recording.supplierId] ?? unnamed,
                      style: const TextStyle(
                        fontSize: AppFontSizes.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "${recording.fileName} · ${formatFileSize(recording.sizeBytes)}",
                      style: TextStyle(
                        fontSize: AppFontSizes.caption,
                        color: context.palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            if (rest > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "외 $rest개",
                  style: TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: context.palette.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("취소"),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: danger,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("삭제"),
        ),
      ],
    );
  }
}

class _RecordingRow extends StatelessWidget {
  const _RecordingRow({
    required this.recording,
    required this.supplierName,
    required this.selecting,
    required this.selected,
    required this.fading,
    required this.onToggle,
  });

  final CallRecording recording;
  final String supplierName;

  /// Choosing what to delete: the row is a check box.
  final bool selecting, selected;

  /// Being deleted.
  final bool fading;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (selecting)
            SizedBox.square(
              dimension: 36,
              child: Icon(
                selected ? Icons.check_box : Icons.check_box_outline_blank,
                size: 24,
                color: selected ? palette.accentText : palette.muted,
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.blush,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.graphic_eq,
                size: 20,
                color: palette.accentText,
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
                    color: palette.muted,
                  ),
                ),
                Text(
                  "${formatSeoulDateTime(recording.uploadedAt ?? recording.createdAt)}"
                  " · ${formatFileSize(recording.sizeBytes)}",
                  style: TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: palette.muted,
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
    return Opacity(
      opacity: fading ? .5 : 1,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selecting && selected
                ? palette.accentText
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: selecting
            ? Semantics(
                checked: selected,
                child: InkWell(onTap: onToggle, child: row),
              )
            : row,
      ),
    );
  }
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
      // Its own node: closed, it must not swallow the title above it.
      container: true,
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
