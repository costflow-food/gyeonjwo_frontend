/// 휴대폰에서 고른 녹음 파일. 업로드 API가 정해지면 [uri]로 내용을 읽습니다.
class VoiceFile {
  const VoiceFile({
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.uri,
  });

  final String name;

  /// Lower case, without the dot: "m4a".
  final String extension;
  final int? sizeBytes;
  final Uri uri;
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
