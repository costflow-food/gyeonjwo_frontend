import "dart:typed_data";

Future<void> saveFile(
  Uint8List bytes, {
  required String filename,
  String? mimeType,
}) async => throw UnsupportedError("파일 저장은 이 기기에서 지원하지 않습니다.");
