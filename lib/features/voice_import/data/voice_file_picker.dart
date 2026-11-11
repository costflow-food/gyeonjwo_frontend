import "package:file_picker/file_picker.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../domain/voice_file.dart";

final voiceFilePickerProvider = Provider<VoiceFilePicker>(
  (ref) => const FileVoiceFilePicker(),
);

abstract interface class VoiceFilePicker {
  /// Opens the system picker for one audio file. Null when cancelled; throws
  /// [VoiceFileRejected] for a file that is not a recording.
  Future<VoiceFile?> pick();
}

class FileVoiceFilePicker implements VoiceFilePicker {
  const FileVoiceFilePicker();

  @override
  Future<VoiceFile?> pick() async {
    final file = await FilePicker.pickFile(type: FileType.audio);
    if (file == null) return null;
    final extension = file.extension?.toLowerCase();
    if (extension == null || !voiceFileExtensions.contains(extension)) {
      throw const VoiceFileRejected();
    }
    return VoiceFile(
      name: file.name,
      extension: extension,
      sizeBytes: await file.length(),
      uri: file.uri,
      openRead: file.readAsByteStream,
    );
  }
}
