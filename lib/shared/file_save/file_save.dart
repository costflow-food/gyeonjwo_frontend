/// Saves bytes as a file: a browser download on web, the system "save as"
/// dialog in the Android app.
library;

export "file_save_stub.dart"
    if (dart.library.js_interop) "file_save_web.dart"
    if (dart.library.io) "file_save_io.dart";
