/// Moves the current browser tab to another URL. Web only; elsewhere it throws
/// [UnsupportedError] (the app targets Chrome).
library;

export "page_navigation_stub.dart"
    if (dart.library.js_interop) "page_navigation_web.dart";
