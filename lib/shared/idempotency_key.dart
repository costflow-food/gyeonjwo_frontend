import "dart:convert";
import "dart:math";

final _random = Random.secure();

/// Random 128-bit hex key for one user action. Reuse it only to retry that
/// same action with the same body.
String newIdempotencyKey() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, "0")).join();
}

/// Idempotency keys a repository keeps per user action.
///
/// Retrying the same body reuses the key, so a retry after a lost response
/// cannot act twice. Success or a definite server answer frees the key;
/// `REQUEST_IN_PROGRESS` keeps it so the retry only checks the first request.
class IdempotencyKeys {
  final _pending = <String, ({String body, String key})>{};

  Future<T> run<T>(
    String action,
    Object? body,
    Future<T> Function(String key) send, {
    required String? Function(Object error) serverCode,
  }) async {
    final fingerprint = jsonEncode(body);
    final previous = _pending[action];
    final key = previous != null && previous.body == fingerprint
        ? previous.key
        : newIdempotencyKey();
    _pending[action] = (body: fingerprint, key: key);
    try {
      final result = await send(key);
      _pending.remove(action);
      return result;
    } catch (error) {
      final code = serverCode(error);
      if (code != null && code != "REQUEST_IN_PROGRESS") {
        _pending.remove(action);
      }
      rethrow;
    }
  }
}
