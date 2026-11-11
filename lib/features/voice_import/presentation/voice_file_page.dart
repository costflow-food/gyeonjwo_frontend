import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/app_font_sizes.dart";
import "../../../shared/widgets/mobile_scaffold.dart";
import "../../../shared/workspace_colors.dart";
import "../domain/voice_file.dart";
import "voice_import_flow.dart";

/// 업무에 붙일 녹음 파일 확인. 업로드는 서버 API가 정해지면 연결합니다.
class VoiceFilePage extends ConsumerStatefulWidget {
  const VoiceFilePage({
    super.key,
    required this.initial,
    required this.caseTitle,
  });

  final VoiceFile initial;

  /// The case the recording goes to.
  final String caseTitle;

  @override
  ConsumerState<VoiceFilePage> createState() => _VoiceFilePageState();
}

class _VoiceFilePageState extends ConsumerState<VoiceFilePage> {
  late VoiceFile _file = widget.initial;

  Future<void> _pickAnother() async {
    final file = await pickVoiceFile(context, ref);
    if (file != null && mounted) setState(() => _file = file);
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    final format = file.extension.toUpperCase();
    final size = formatFileSize(file.sizeBytes);
    return MobilePageScaffold(
      title: "통화 녹음 추가",
      closeIcon: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Panel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.palette.blush,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.link,
                    size: 18,
                    color: context.palette.accentText,
                  ),
                ),
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
          const SizedBox(height: 12),
          _Panel(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: context.palette.blush,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.graphic_eq,
                    size: 28,
                    color: context.palette.accentText,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        file.name,
                        style: const TextStyle(
                          fontSize: AppFontSizes.bodyLarge,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$format · $size",
                        style: TextStyle(
                          fontSize: AppFontSizes.secondary,
                          color: context.palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Column(
              children: [
                _Fact(label: "형식", value: format),
                Divider(height: 1, color: context.palette.line),
                _Fact(label: "크기", value: size),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.palette.blush,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: context.palette.accentText,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "업로드는 서버 준비가 끝나면 열립니다. 지금은 고른 파일만 확인할 수 있습니다.",
                    style: TextStyle(
                      fontSize: AppFontSizes.secondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomBar: Row(
        children: [
          Expanded(
            flex: 5,
            child: OutlinedButton.icon(
              onPressed: _pickAnother,
              style: MobileButtons.outlined(context),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text("다른 파일"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 7,
            child: FilledButton.icon(
              // No upload API yet.
              onPressed: null,
              style: MobileButtons.filled(context),
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text("업로드 · 준비 중"),
            ),
          ),
        ],
      ),
    );
  }
}

String formatFileSize(int? bytes) {
  if (bytes == null) return "크기 미확인";
  if (bytes < 1024) return "${bytes}B";
  if (bytes < 1024 * 1024) return "${(bytes / 1024).round()}KB";
  return "${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB";
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSizes.body,
            color: context.palette.muted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
