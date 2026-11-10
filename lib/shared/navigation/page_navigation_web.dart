import "package:web/web.dart" as web;

/// Uses `location.assign` instead of `window.open(url, "_self", "noopener")`:
/// recent Chrome ignores the latter without an error, leaving the page stuck.
void navigateCurrentPage(Uri url) => web.window.location.assign(url.toString());
