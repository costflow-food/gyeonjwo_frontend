import "dart:async";
import "dart:convert";
import "dart:math";

import "network/api_request.dart";

final _random = Random.secure();

/// How long a key whose outcome is unknown may be reused. After this, the
/// same action gets a new key, so an old stored response cannot answer a
/// later request.
const pendingKeyLifetime = Duration(minutes: 10);

/// Random 128-bit hex key for one user action. Reuse it only to retry that
/// same action with the same body.
String newIdempotencyKey() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, "0")).join();
}

/// Idempotency keys a repository keeps per user action.
///
/// Concurrent identical actions share one Future, so double-clicks cannot
/// issue duplicate HTTP mutations. A different body for the same action must
/// wait until the first action finishes; it never overwrites the active key.
///
/// The key is kept for a retry of the same body when the outcome is unknown
/// or retryable (`serverCode` returns null: no response, 5xx, `retryable`),
/// and for [_keepCodes]. Any other server rejection releases it. A kept key
/// expires after [lifetime].
class IdempotencyKeys {
  IdempotencyKeys({
    this.lifetime = pendingKeyLifetime,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// The server did not process these; the same key is still safe to send.
  static const _keepCodes = {"REQUEST_IN_PROGRESS", rateLimitedCode};

  final Duration lifetime;
  final DateTime Function() _now;
  final _pending = <String, ({String body, String key, DateTime issuedAt})>{};
  final _inFlight = <String, ({String body, Future<dynamic> future})>{};

  Future<T> run<T>(
    String action,
    Object? body,
    Future<T> Function(String key) send, {
    required String? Function(Object error) serverCode,
  }) {
    final fingerprint = jsonEncode(body);
    final active = _inFlight[action];
    if (active != null) {
      if (active.body != fingerprint) {
        return Future<T>.error(
          StateError("An action is already in progress with different data."),
        );
      }
      return active.future as Future<T>;
    }

    final now = _now();
    final previous = _pending[action];
    final entry =
        previous != null &&
            previous.body == fingerprint &&
            now.difference(previous.issuedAt) < lifetime
        ? previous
        : (body: fingerprint, key: newIdempotencyKey(), issuedAt: now);
    _pending[action] = entry;
    final key = entry.key;
    final completer = Completer<T>();
    _inFlight[action] = (body: fingerprint, future: completer.future);

    Future<void> execute() async {
      try {
        final result = await send(key);
        _pending.remove(action);
        completer.complete(result);
      } catch (error, stackTrace) {
        final code = serverCode(error);
        if (code != null && !_keepCodes.contains(code)) {
          _pending.remove(action);
        }
        completer.completeError(error, stackTrace);
      } finally {
        _inFlight.remove(action);
      }
    }

    // Start the request after the in-flight entry is visible to reentrant calls.
    unawaited(execute());
    return completer.future;
  }

  /// Drops kept keys, e.g. when the record they acted on moved on, so the
  /// next press is a new request rather than a replay.
  void discardWhere(bool Function(String action) test) =>
      _pending.removeWhere((action, _) => test(action));
}
