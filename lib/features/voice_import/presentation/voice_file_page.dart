import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/app_font_sizes.dart";
import "../../../shared/widgets/mobile_scaffold.dart";
import "../../../shared/widgets/workspace_button_styles.dart";
import "../../../shared/workspace_colors.dart";
import "../data/call_recording_repository_impl.dart";
import "../data/recording_supplier_source.dart";
import "../domain/call_recording.dart";
import "../domain/call_recording_repository.dart";
import "../domain/recording_supplier.dart";
import "../domain/voice_file.dart";
import "voice_import_flow.dart";

/// 업무에 붙일 통화 녹음: 파일과 거래처를 확인하고 올립니다.
/// 서버에 통화 녹음 기능이 아직 없으면 올리기는 닫아 둡니다.
class VoiceFilePage extends ConsumerStatefulWidget {
  const VoiceFilePage({
    super.key,
    required this.initial,
    required this.caseTitle,
    required this.suppliers,
  });

  final VoiceFile initial;

  /// The case the recording goes to.
  final String caseTitle;

  /// Which suppliers the recording can belong to.
  final RecordingSupplierQuery suppliers;

  @override
  ConsumerState<VoiceFilePage> createState() => _VoiceFilePageState();
}

class _VoiceFilePageState extends ConsumerState<VoiceFilePage> {
  late VoiceFile _file = widget.initial;

  /// The call's supplier. Required before the upload.
  String? _supplierId;

  /// Null when no upload is running.
  RecordingUploadStep? _step;
  int _percent = 0;
  String? _error;

  /// The last try may have left its recording on the server. The next press
  /// continues it, so the per-case limit is not checked here again.
  bool _resumable = false;

  /// The picker answers only after it copied the file, which can be well
  /// after its screen closed: nothing else starts until then.
  bool _picking = false;

  bool get _busy => _step != null;

  Future<void> _pickAnother() async {
    if (_picking || _busy) return;
    setState(() => _picking = true);
    final file = await pickVoiceFile(context, ref);
    if (!mounted) return;
    setState(() {
      _picking = false;
      if (file != null) {
        _file = file;
        _error = null;
        _resumable = false;
      }
    });
  }

  /// Leaving mid-upload would lose track of it; it ends or fails by itself.
  void _close() {
    if (!_busy) Navigator.of(context).pop();
  }

  Future<void> _upload(RecordingSupplier supplier) async {
    if (_busy || _picking) return;
    final caseId = widget.suppliers.caseId;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    setState(() {
      _step = RecordingUploadStep.requesting;
      _percent = 0;
      _error = null;
    });
    try {
      await ref
          .read(callRecordingRepositoryProvider)
          .upload(
            caseId: caseId,
            supplierId: supplier.supplierId,
            file: _file,
            onStep: (step) {
              if (mounted) setState(() => _step = step);
            },
            onProgress: (sent, total) {
              // Per percent, not per chunk: chunks arrive many times a second.
              final percent = total > 0 ? sent * 100 ~/ total : 0;
              if (mounted && percent != _percent) {
                setState(() => _percent = percent);
              }
            },
          );
      if (!mounted) return;
      ref.invalidate(callRecordingsProvider(caseId));
      messenger?.showSnackBar(const SnackBar(content: Text("통화 녹음을 올렸습니다.")));
      navigator.pop();
    } on CallRecordingFailure catch (failure) {
      if (!mounted) return;
      // The list may have changed, or the try may have gone through.
      ref.invalidate(callRecordingsProvider(caseId));
      if (failure.suppliersChanged) {
        ref.invalidate(recordingSuppliersProvider(widget.suppliers));
      }
      setState(() {
        _step = null;
        _error = failure.unknownOutcome ? _unknownOutcome : failure.message;
        _resumable = failure.retryable || failure.unknownOutcome;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _step = null;
        _error = _unknownOutcome;
        _resumable = true;
      });
    }
  }

  static const _unknownOutcome = "결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다.";

  @override
  Widget build(BuildContext context) {
    final file = _file;
    final provider = recordingSuppliersProvider(widget.suppliers);
    final suppliers = ref.watch(provider);
    // A supplier that left the list is no longer chosen.
    final chosen = suppliers.value
        ?.where((supplier) => supplier.supplierId == _supplierId)
        .firstOrNull;

    // The case's recordings give the limits before anything is sent.
    final recordings = ref.watch(
      callRecordingsProvider(widget.suppliers.caseId),
    );
    final limits = recordings.value;
    final checking =
        recordings.isLoading && limits == null && !recordings.hasError;
    final maxBytes = limits?.maxBytes ?? defaultMaxRecordingBytes;
    // Why this file cannot go up as it is.
    final blocked = limits != null && limits.limitReached && !_resumable
        ? "업무 하나에 녹음은 ${limits.maxPerCase}개까지 올릴 수 있습니다."
        : (file.sizeBytes ?? 0) > maxBytes
        ? "녹음 파일은 ${maxBytes ~/ (1024 * 1024)}MB까지 올릴 수 있습니다."
        : null;
    return MobilePageScaffold(
      title: "통화 녹음 추가",
      closeIcon: true,
      onBack: _close,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Panel(
            child: Row(
              children: [
                const _IconBadge(icon: Icons.link, size: 34, iconSize: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "연결할 업무",
                        style: TextStyle(
                          fontSize: AppFontSizes.caption,
                          color: context.palette.muted,
                        ),
                      ),
                      Text(
                        widget.caseTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppFontSizes.secondary,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Panel(
            child: Row(
              children: [
                const _IconBadge(
                  icon: Icons.graphic_eq,
                  size: 44,
                  iconSize: 24,
                  radius: 13,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        file.name,
                        style: const TextStyle(
                          fontSize: AppFontSizes.body,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${file.extension.toUpperCase()} · "
                        "${formatFileSize(file.sizeBytes)}",
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
          const SizedBox(height: 18),
          const Text(
            "어느 거래처와의 통화입니까?",
            style: TextStyle(
              fontSize: AppFontSizes.bodyLarge,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "이 업무에서 견적을 요청한 거래처입니다.",
            style: TextStyle(
              fontSize: AppFontSizes.caption,
              color: context.palette.muted,
            ),
          ),
          const SizedBox(height: 4),
          suppliers.when(
            skipLoadingOnRefresh: false,
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => _ListMessage(
              "거래처 목록을 불러오지 못했습니다.",
              action: TextButton(
                onPressed: () => ref.invalidate(provider),
                style: WorkspaceButtonStyles.text(context),
                child: const Text("다시 시도"),
              ),
            ),
            data: (list) => list.isEmpty
                ? const _ListMessage("견적 요청을 보낸 거래처가 없습니다.")
                : Column(
                    children: [
                      for (final supplier in list)
                        _SupplierOption(
                          supplier: supplier,
                          selected: supplier.supplierId == chosen?.supplierId,
                          onTap: _busy
                              ? null
                              : () => setState(() {
                                  _supplierId = supplier.supplierId;
                                  _error = null;
                                  _resumable = false;
                                }),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_busy) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                // Only the file transfer has a known length.
                value: _step == RecordingUploadStep.uploading
                    ? _percent / 100
                    : null,
                minHeight: 4,
                color: context.palette.accent,
                backgroundColor: context.palette.line,
              ),
            ),
            const SizedBox(height: 10),
          ] else if (_error ?? blocked case final message?) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: AppFontSizes.secondary,
                  color: danger,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                flex: 5,
                child: OutlinedButton.icon(
                  onPressed: _busy || _picking ? null : _pickAnother,
                  style: MobileButtons.outlined(context),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const _OneLine("다른 파일"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 7,
                child: switch (chosen) {
                  null => FilledButton(
                    onPressed: null,
                    style: MobileButtons.filled(context),
                    child: const _OneLine("거래처를 골라 주세요"),
                  ),
                  _ when _busy => FilledButton.icon(
                    onPressed: null,
                    style: MobileButtons.filled(context),
                    icon: SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.palette.muted,
                      ),
                    ),
                    label: _OneLine(switch (_step!) {
                      RecordingUploadStep.requesting => "업로드 준비 중",
                      RecordingUploadStep.uploading => "올리는 중 $_percent%",
                      RecordingUploadStep.confirming => "확인 중",
                    }),
                  ),
                  _ when checking => FilledButton(
                    onPressed: null,
                    style: MobileButtons.filled(context),
                    child: const _OneLine("확인 중"),
                  ),
                  final supplier => FilledButton.icon(
                    onPressed: blocked == null && !_picking
                        ? () => _upload(supplier)
                        : null,
                    style: MobileButtons.filled(context),
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: _OneLine(_error == null ? "업로드" : "다시 시도"),
                  ),
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A button label that shrinks instead of wrapping at large text sizes, so
/// the two bottom buttons keep the same height.
class _OneLine extends StatelessWidget {
  const _OneLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));
}

String formatFileSize(int? bytes) {
  if (bytes == null) return "크기 미확인";
  if (bytes < 1024) return "${bytes}B";
  if (bytes < 1024 * 1024) return "${(bytes / 1024).round()}KB";
  return "${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB";
}

class _SupplierOption extends StatelessWidget {
  const _SupplierOption({
    required this.supplier,
    required this.selected,
    required this.onTap,
  });

  final RecordingSupplier supplier;
  final bool selected;

  /// Null while an upload is running.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final replied = supplier.replied;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        child: Material(
          color: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected ? palette.accentText : Colors.transparent,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? palette.accentText : palette.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: const TextStyle(
                            fontSize: AppFontSizes.body,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // Without a registered name the address is the name.
                        if (supplier.email != supplier.name)
                          Text(
                            supplier.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppFontSizes.caption,
                              color: palette.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (replied != null) ...[
                    const SizedBox(width: 8),
                    _ReplyMark(replied: replied),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyMark extends StatelessWidget {
  const _ReplyMark({required this.replied});

  final bool replied;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: replied ? const Color(0xFFE2F4EA) : context.palette.line,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      replied ? "메일 회신 있음" : "회신 전",
      style: TextStyle(
        fontSize: AppFontSizes.captionSmall,
        fontWeight: FontWeight.w600,
        color: replied ? const Color(0xFF00754A) : context.palette.ink,
      ),
    ),
  );
}

class _ListMessage extends StatelessWidget {
  const _ListMessage(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: AppFontSizes.secondary,
            color: context.palette.muted,
          ),
        ),
        ?action,
      ],
    ),
  );
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.size,
    required this.iconSize,
    this.radius,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  /// Rounded square with this radius; a circle when null.
  final double? radius;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.palette.blush,
      shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: radius == null ? null : BorderRadius.circular(radius!),
    ),
    child: Icon(icon, size: iconSize, color: context.palette.accentText),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}
