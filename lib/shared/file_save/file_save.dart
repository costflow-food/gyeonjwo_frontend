/// Saves bytes as a file the browser downloads. Web only; elsewhere it throws
/// [UnsupportedError] (the app targets Chrome).
library;

export "file_save_stub.dart" if (dart.library.js_interop) "file_save_web.dart";
