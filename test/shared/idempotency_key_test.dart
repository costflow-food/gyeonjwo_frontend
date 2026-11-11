import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/shared/idempotency_key.dart";

void main() {
  group("IdempotencyKeys", () {
    test("coalesces concurrent identical mutations", () async {
      final keys = IdempotencyKeys();
      final gate = Completer<int>();
      var calls = 0;

      Future<int> send(String key) {
        calls++;
        return gate.future;
      }

      final first = keys.run<int>(
        "case:start",
        {"revision": 1},
        send,
        serverCode: (_) => null,
      );
      final second = keys.run<int>(
        "case:start",
        {"revision": 1},
        send,
        serverCode: (_) => null,
      );

      expect(identical(first, second), isTrue);
      expect(calls, 1);
      gate.complete(202);
      expect(await first, 202);
      expect(await second, 202);
    });

    test("rejects a changed body while a mutation is running", () async {
      final keys = IdempotencyKeys();
      final gate = Completer<void>();
      final first = keys.run<void>(
        "case:start",
        {"revision": 1},
        (_) => gate.future,
        serverCode: (_) => null,
      );

      await expectLater(
        keys.run<void>(
          "case:start",
          {"revision": 2},
          (_) async {},
          serverCode: (_) => null,
        ),
        throwsStateError,
      );

      gate.complete();
      await first;
    });

    test("reuses the same key when an uncertain request is retried", () async {
      final keys = IdempotencyKeys();
      final usedKeys = <String>[];

      Future<void> send(String key) async {
        usedKeys.add(key);
        if (usedKeys.length == 1) throw TimeoutException("lost response");
      }

      await expectLater(
        keys.run<void>(
          "case:start",
          {"revision": 1},
          send,
          serverCode: (_) => null,
        ),
        throwsA(isA<TimeoutException>()),
      );
      await keys.run<void>(
        "case:start",
        {"revision": 1},
        send,
        serverCode: (_) => null,
      );

      expect(usedKeys, hasLength(2));
      expect(usedKeys[0], usedKeys[1]);
    });

    test("a definitive server rejection releases the old key", () async {
      final keys = IdempotencyKeys();
      final usedKeys = <String>[];
      var attempts = 0;

      Future<void> send(String key) async {
        usedKeys.add(key);
        if (attempts++ == 0) throw StateError("rejected");
      }

      await expectLater(
        keys.run<void>(
          "case:start",
          {"revision": 1},
          send,
          serverCode: (_) => "REVISION_CONFLICT",
        ),
        throwsStateError,
      );
      await keys.run<void>(
        "case:start",
        {"revision": 1},
        send,
        serverCode: (_) => "REVISION_CONFLICT",
      );

      expect(usedKeys, hasLength(2));
      expect(usedKeys[0], isNot(usedKeys[1]));
    });

    for (final code in ["REQUEST_IN_PROGRESS", "RATE_LIMITED"]) {
      test("$code keeps the key", () async {
        final keys = IdempotencyKeys();
        final usedKeys = <String>[];

        Future<void> send(String key) async {
          usedKeys.add(key);
          if (usedKeys.length == 1) throw StateError(code);
        }

        await expectLater(
          keys.run<void>("a", 1, send, serverCode: (_) => code),
          throwsStateError,
        );
        await keys.run<void>("a", 1, send, serverCode: (_) => code);

        expect(usedKeys[0], usedKeys[1]);
      });
    }

    test("a kept key expires", () async {
      var now = DateTime(2026, 11, 11, 9);
      final keys = IdempotencyKeys(
        lifetime: const Duration(minutes: 10),
        now: () => now,
      );
      final usedKeys = <String>[];

      Future<void> send(String key) async {
        usedKeys.add(key);
        throw TimeoutException("lost response");
      }

      Future<void> press() => expectLater(
        keys.run<void>("a", 1, send, serverCode: (_) => null),
        throwsA(isA<TimeoutException>()),
      );

      await press();
      now = now.add(const Duration(minutes: 9));
      await press();
      now = now.add(const Duration(minutes: 2));
      await press();

      expect(usedKeys[0], usedKeys[1]);
      expect(usedKeys[2], isNot(usedKeys[0]));
    });

    test("discardWhere drops only the matching kept keys", () async {
      final keys = IdempotencyKeys();
      final usedKeys = <String, List<String>>{};

      Future<void> send(String action, String key) async {
        (usedKeys[action] ??= []).add(key);
        if (usedKeys[action]!.length == 1) throw TimeoutException("lost");
      }

      for (final action in ["start:c1", "start:c2"]) {
        await expectLater(
          keys.run<void>(
            action,
            1,
            (key) => send(action, key),
            serverCode: (_) => null,
          ),
          throwsA(isA<TimeoutException>()),
        );
      }
      keys.discardWhere((action) => action.endsWith(":c1"));
      for (final action in ["start:c1", "start:c2"]) {
        await keys.run<void>(
          action,
          1,
          (key) => send(action, key),
          serverCode: (_) => null,
        );
      }

      expect(usedKeys["start:c1"]![0], isNot(usedKeys["start:c1"]![1]));
      expect(usedKeys["start:c2"]![0], usedKeys["start:c2"]![1]);
    });
  });
}
