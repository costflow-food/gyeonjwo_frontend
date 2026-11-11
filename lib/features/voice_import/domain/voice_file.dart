/// 휴대폰에서 고른 녹음 파일.
class VoiceFile {
  const VoiceFile({
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.uri,
    required this.openRead,
  });

  final String name;

  /// Lower case, without the dot: "m4a".
  final String extension;
  final int? sizeBytes;
  final Uri uri;

  /// A new stream of the file's bytes on each call, so an upload can be
  /// retried. Exactly [sizeBytes] bytes.
  final Stream<List<int>> Function() openRead;
}

/// 녹음 파일로 받는 확장자. 통화 녹음(m4a·amr·3gp)과 일반 음성 형식.
const voiceFileExtensions = {
  "m4a",
  "mp3",
  "wav",
  "aac",
  "amr",
  "3gp",
  "ogg",
  "opus",
  "flac",
};

/// The picked file is not a recording [voiceFileExtensions] accepts.
class VoiceFileRejected implements Exception {
  const VoiceFileRejected();
}
