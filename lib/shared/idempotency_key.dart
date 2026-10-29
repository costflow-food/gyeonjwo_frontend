import "dart:math";

final _random = Random.secure();

/// Random 128-bit hex key for one user action. Reuse it only to retry that
/// same action with the same body.
String newIdempotencyKey() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, "0")).join();
}
