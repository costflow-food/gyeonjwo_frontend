import "dart:convert";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_data_source.dart";
import "package:gyeonjwo_frontend/features/work_queue/data/work_queue_repository_impl.dart";
import "package:gyeonjwo_frontend/features/work_queue/domain/work_case.dart";
import "package:gyeonjwo_frontend/shared/network/api_request.dart";

DioException _http(
  int status, [
  Object? data,
  Map<String, List<String>> headers = const {},
]) {
  final options = RequestOptions(path: "/x");
  return DioException(
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: data,
      headers: Headers.fromMap(headers),
    ),
  );
}

Map<String, Object?> _error(String code, {bool? retryable}) => {
  "error": {"code": code, "message": "서버 문구", "retryable": ?retryable},
};

Future<String?> _token({bool forceRefresh = false}) async => "token";

void main() {
  group("apiExceptionFrom", () {
    test("no response keeps the key and the outcome is unknown", () {
      final error = apiExceptionFrom(
        DioException(requestOptions: RequestOptions(path: "/x")),
      );
      expect(error.retryable, isTrue);
      expect(error.unknownOutcome, isTrue);
    });

    test("5xx is retryable and unknown unless the server says otherwise", () {
      final plain = apiExceptionFrom(
        _http(503, _error("PROCESSING_UNAVAILABLE")),
      );
      expect(plain.retryable, isTrue);
      expect(plain.unknownOutcome, isTrue);
      expect(plain.code, "PROCESSING_UNAVAILABLE");

      final settled = apiExceptionFrom(
        _http(
          503,
          _error("EXTRACTION_CONFIGURATION_REQUIRED", retryable: false),
        ),
      );
      expect(settled.retryable, isTrue);
      expect(settled.unknownOutcome, isFalse);
      expect(settled.message, "서버 문구");

      final noBody = apiExceptionFrom(_http(502, "<html>"));
      expect(noBody.code, "HTTP_502");
      expect(noBody.unknownOutcome, isTrue);
    });

    test("a 4xx with retryable: true keeps the key", () {
      final error = apiExceptionFrom(
        _http(409, _error("ANALYSIS_BUSY", retryable: true)),
      );
      expect(error.retryable, isTrue);
      expect(error.unknownOutcome, isFalse);
    });

    test("other 4xx is a definite rejection", () {
      final error = apiExceptionFrom(_http(409, _error("REVISION_CONFLICT")));
      expect(error.retryable, isFalse);
      expect(error.unknownOutcome, isFalse);
    });

    test("429 has its own code, message and wait", () {
      final error = apiExceptionFrom(
        _http(429, _error("RATE_LIMITED", retryable: true), {
          "retry-after": ["3"],
        }),
      );
      expect(error.code, rateLimitedCode);
      expect(error.message, "요청이 많습니다. 잠시 후 다시 해 주세요.");
      expect(error.retryAfter, const Duration(seconds: 3));
      expect(error.retryable, isFalse);
    });

    test("byte error bodies are decoded", () {
      final bytes = utf8.encode(
        '{"error":{"code":"RESOURCE_NOT_FOUND","message":"없음"}}',
      );
      expect(apiExceptionFrom(_http(404, bytes)).code, "RESOURCE_NOT_FOUND");
    });
  });

  group("sendApiRequest", () {
    test("waits out Retry-After once, with the same key", () async {
      final keys = <String?>[];
      final waits = <Duration>[];
      final body = await sendApiRequest<Map<String, dynamic>>(
        _token,
        (headers) async {
          keys.add(headers["Idempotency-Key"]);
          if (keys.length == 1) {
            throw _http(429, null, {
              "retry-after": ["2"],
            });
          }
          return Response(
            requestOptions: RequestOptions(path: "/x"),
            data: {"data": 1},
          );
        },
        idempotencyKey: "k1",
        wait: (delay) async => waits.add(delay),
      );
      expect(body, {"data": 1});
      expect(waits, [const Duration(seconds: 2)]);
      expect(keys, ["k1", "k1"]);
    });

    test("does not wait past the limit, and retries only once", () async {
      var calls = 0;
      Future<Response<Map<String, dynamic>>> limited(_) async {
        calls++;
        throw _http(429, null, {
          "retry-after": ["1"],
        });
      }

      await expectLater(
        sendApiRequest(_token, limited, wait: (_) async {}),
        throwsA(
          isA<ApiException>().having((e) => e.code, "code", "RATE_LIMITED"),
        ),
      );
      expect(calls, 2);

      calls = 0;
      await expectLater(
        sendApiRequest(_token, (_) async {
          calls++;
          throw _http(429, null, {
            "retry-after": ["60"],
          });
        }, wait: (_) async => fail("should not wait")),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 1);
    });
  });

  group("WorkQueueRepositoryImpl", () {
    test("a 503 that was processed succeeds on the next press", () async {
      final source = _FakeWorkQueue()
        ..failNextStartWith = _http(503, _error("PROCESSING_UNAVAILABLE"));
      final repository = WorkQueueRepositoryImpl(source);
      final workCase = (await repository.getCases()).items.single;

      await expectLater(
        repository.start(workCase),
        throwsA(
          isA<WorkQueueFailure>()
              .having((f) => f.retryable, "retryable", isTrue)
              .having((f) => f.unknownOutcome, "unknownOutcome", isTrue),
        ),
      );
      await repository.start(workCase);

      // The server stored the first result under this key and replays it.
      expect(source.startKeys, hasLength(2));
      expect(source.startKeys[0], source.startKeys[1]);
    });

    test("a stage change drops the case's kept key", () async {
      final source = _FakeWorkQueue()..failNextStartWith = _http(503);
      final repository = WorkQueueRepositoryImpl(source);
      final workCase = (await repository.getCases()).items.single;

      await expectLater(
        repository.start(workCase),
        throwsA(isA<WorkQueueFailure>()),
      );
      source.step = "EXTRACTING";
      await repository.getCases();
      source.step = "RECEIVED";
      await repository.getCases();
      await repository.start(workCase);

      expect(source.startKeys[0], isNot(source.startKeys[1]));
    });

    test("a definite rejection releases the key", () async {
      final source = _FakeWorkQueue()
        ..failNextStartWith = _http(409, _error("REVISION_CONFLICT"));
      final repository = WorkQueueRepositoryImpl(source);
      final workCase = (await repository.getCases()).items.single;

      await expectLater(
        repository.start(workCase),
        throwsA(isA<WorkQueueFailure>()),
      );
      await repository.start(workCase);

      expect(source.startKeys[0], isNot(source.startKeys[1]));
    });
  });
}

/// Builds responses through [sendApiRequest] so the real error mapping runs.
class _FakeWorkQueue implements WorkQueueDataSource {
  String step = "RECEIVED";
  DioException? failNextStartWith;
  final startKeys = <String>[];

  Future<Map<String, dynamic>> _reply(Map<String, dynamic> body) =>
      sendApiRequest(
        _token,
        (_) async => Response(
          requestOptions: RequestOptions(path: "/x"),
          data: body,
        ),
      );

  @override
  Future<Map<String, dynamic>> fetchCases({
    String? status,
    String query = "",
    String? cursor,
    int? limit,
  }) => _reply({
    "data": {
      "items": [
        {
          "case_id": "c1",
          "initial_mail_id": "m1",
          "title": "견적",
          "sender": "a@example.invalid",
          "received_at": "2026-11-11T09:00:00+09:00",
          "status": "Waiting",
          "processing_step": step,
          "input_revision": 1,
        },
      ],
      "counts": {"Waiting": 1, "total": 1},
      "next_cursor": null,
    },
  });

  @override
  Future<Map<String, dynamic>> start(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => sendApiRequest(_token, (headers) async {
    startKeys.add(headers["Idempotency-Key"]!);
    final failure = failNextStartWith;
    failNextStartWith = null;
    if (failure != null) throw failure;
    return Response(
      requestOptions: RequestOptions(path: "/x"),
      data: <String, dynamic>{"data": <String, dynamic>{}},
    );
  }, idempotencyKey: idempotencyKey);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
