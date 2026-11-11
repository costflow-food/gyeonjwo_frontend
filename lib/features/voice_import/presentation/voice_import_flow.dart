import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/voice_file_picker.dart";
import "../domain/voice_file.dart";
import "voice_file_page.dart";

/// 업무 상세의 "통화 녹음 추가": 파일 선택창 → 녹음 파일 확인.
Future<void> addCallRecording(
  BuildContext context,
  WidgetRef ref, {
  required String caseTitle,
}) async {
  final file = await pickVoiceFile(context, ref);
  if (file == null || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => VoiceFilePage(initial: file, caseTitle: caseTitle),
    ),
  );
}

/// Opens the system picker. Null when cancelled or refused; the reason, if
/// any, is shown in a snack bar.
Future<VoiceFile?> pickVoiceFile(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    return await ref.read(voiceFilePickerProvider).pick();
  } on VoiceFileRejected {
    messenger?.showSnackBar(
      const SnackBar(content: Text("오디오 파일만 가져올 수 있습니다.")),
    );
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(content: Text("파일을 불러오지 못했습니다. 다시 시도해 주세요.")),
    );
  }
  return null;
}
