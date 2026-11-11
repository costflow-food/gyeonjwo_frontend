import "dart:typed_data";

import "package:file_picker/file_picker.dart";

/// Opens the system "save as" dialog. Cancelling it is not an error.
Future<void> saveFile(
  Uint8List bytes, {
  required String filename,
  String? mimeType,
}) => FilePicker.saveFile(
  fileName: filename,
  bytes: bytes,
  mimeType: mimeType ?? "application/octet-stream",
);
