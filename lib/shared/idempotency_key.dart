import "dart:async";
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
/// Concurrent identical actions share one Future, so double-clicks cannot
/// issue duplicate HTTP mutations. A different body for the same action must
/// wait until the first action finishes; it never overwrites the active key.
/// Retrying the same body after an unknown outcome reuses the key.
class IdempotencyKeys {
  final _pending = <String, ({String body, String key})>{};
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

    final previous = _pending[action];
    final key = previous != null && previous.body == fingerprint
        ? previous.key
        : newIdempotencyKey();
    final completer = Completer<T>();
    _inFlight[action] = (body: fingerprint, future: completer.future);
    _pending[action] = (body: fingerprint, key: key);

    Future<void> execute() async {
      try {
        final result = await send(key);
        _pending.remove(action);
        completer.complete(result);
      } catch (error, stackTrace) {
        final code = serverCode(error);
        if (code != null && code != "REQUEST_IN_PROGRESS") {
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
}
