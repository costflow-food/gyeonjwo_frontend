import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/voice_import/data/call_recording_data_source.dart";
import "package:gyeonjwo_frontend/features/voice_import/data/call_recording_repository_impl.dart";
import "package:gyeonjwo_frontend/features/voice_import/data/recording_file_uploader.dart";
import "package:gyeonjwo_frontend/features/voice_import/domain/call_recording.dart";
import "package:gyeonjwo_frontend/features/voice_import/domain/call_recording_repository.dart";
import "package:gyeonjwo_frontend/features/voice_import/domain/voice_file.dart";
import "package:gyeonjwo_frontend/shared/network/api_request.dart";

const _url =
    "https://storage.example.invalid/storage/v1/object/upload/sign/call-recordings/o/c1/r1.m4a?token=secret";

Map<String, dynamic> _row(
  String status, {
  bool upload = false,
  String? failureReason,
}) => {
  "data": {
    "recording_id": "r1",
    "case_id": "c1",
    "supplier_id": "s1",
    "file_name": "통화.m4a",
    "extension": "m4a",
    "content_type": "audio/mp4",
    "size_bytes": 3,
    "status": status,
    "failure_reason": failureReason,
    "created_at": "2026-11-11T05:40:00Z",
    "uploaded_at": status == "UPLOADED" ? "2026-11-11T05:41:00Z" : null,
    "upload": ?(upload
        ? {
            "method": "PUT",
            "url": _url,
            "token": "secret",
            "path": "o/c1/r1.m4a",
            "content_type": "audio/mp4",
            "expires_at": "2026-11-11T07:40:00Z",
          }
        : null),
  },
};

/// The API's answers, in order, per call. An [ApiException] is thrown.
class _Api implements CallRecordingDataSource {
  final creates = <Object>[];
  final completes = <Object>[];
  final keys = <String>[];
  final bodies = <Map<String, Object?>>[];
  final log = <String>[];

  /// Thrown by the list read, if set.
  ApiException? listError;

  @override
  Future<Map<String, dynamic>> createRecording(
    String caseId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    log.add("create");
    keys.add(idempotencyKey);
    bodies.add(body);
    return _next(creates);
  }

  @override
  Future<Map<String, dynamic>> completeRecording(
    String caseId,
    String recordingId,
  ) async {
    log.add("complete:$recordingId");
    return _next(completes);
  }

  @override
  Future<Map<String, dynamic>> fetchRecordings(String caseId) async {
    if (listError case final error?) throw error;
    if (!deletable) return _list;
    return {
      "data": {...(_list["data"] as Map<String, dynamic>), "deletable": true},
    };
  }

  /// Whether the list says the server can delete.
  bool deletable = false;

  final deletes = <String>[];

  /// Thrown by the next delete, if set.
  ApiException? deleteError;

  @override
  Future<void> deleteRecording(String caseId, String recordingId) async {
    deletes.add("$caseId/$recordingId");
    if (deleteError case final error?) throw error;
  }

  static final _list = <String, dynamic>{
    "data": {
      "items": [
        _row("UPLOADED")["data"],
        _row("FAILED", failureReason: "EXPIRED")["data"],
        <String, dynamic>{
          ...(_row("UPLOADING")["data"] as Map<String, dynamic>),
          "status": "ARCHIVED",
        },
      ],
      "limits": {"max_per_case": 2, "max_bytes": 52428800},
    },
  };

  static Map<String, dynamic> _next(List<Object> answers) {
    final answer = answers.removeAt(0);
    if (answer is ApiException) throw answer;
    return answer as Map<String, dynamic>;
  }
}

/// Records each PUT; fails with the next of [failures], if any.
class _Storage implements RecordingFileUploader {
  final puts =
      <({String url, String contentType, int length, List<int> bytes})>[];
  final failures = <RecordingUploadFailed>[];

  @override
  Future<void> upload({
    required String url,
    required String contentType,
    required int length,
    required Stream<List<int>> Function() open,
    void Function(int sent, int total)? onProgress,
  }) async {
    final bytes = [await for (final chunk in open()) ...chunk];
    puts.add((
      url: url,
      contentType: contentType,
      length: length,
      bytes: bytes,
    ));
    if (failures.isNotEmpty) throw failures.removeAt(0);
    onProgress?.call(length, length);
  }
}

VoiceFile _file({String name = "통화.m4a", int? size = 3}) => VoiceFile(
  name: name,
  extension: "m4a",
  sizeBytes: size,
  uri: Uri.parse("file:///cache/file_picker/$name"),
  openRead: () => Stream.fromIterable(const [
    [1, 2],
    [3],
  ]),
);

Future<CallRecordingFailure> _failure(Future<Object?> future) async {
  try {
    await future;
  } on CallRecordingFailure catch (failure) {
    return failure;
  }
  fail("expected a CallRecordingFailure");
}

/// Answers every request from [reply] after reading the whole request body.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);

  final FutureOr<ResponseBody> Function(RequestOptions options, List<int> body)
  reply;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = <int>[
      if (requestStream != null)
        await for (final chunk in requestStream) ...chunk,
    ];
    return reply(options, body);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, int status) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Dio _dio(
  FutureOr<ResponseBody> Function(RequestOptions options, List<int> body) reply,
) => Dio(
  BaseOptions(
    baseUrl: "https://api.example.invalid",
    contentType: Headers.jsonContentType,
    sendTimeout: const Duration(seconds: 15),
  ),
)..httpClientAdapter = _Adapter(reply);

Future<String?> _token({bool forceRefresh = false}) async => "app-token";

void main() {
  late _Api api;
  late _Storage storage;
  late CallRecordingRepository repository;
  late DateTime now;

  setUp(() {
    api = _Api();
    storage = _Storage();
    now = DateTime.utc(2026, 11, 11, 5);
    repository = CallRecordingRepositoryImpl(api, storage, now: () => now);
  });

  Future<CallRecording> upload({VoiceFile? file, String supplierId = "s1"}) =>
      repository.upload(
        caseId: "c1",
        supplierId: supplierId,
        file: file ?? _file(),
      );

  group("upload", () {
    test("asks for a slot, sends the file, then confirms", () async {
      api.creates.add(_row("UPLOADING", upload: true));
      api.completes.add(_row("UPLOADED"));
      final steps = <RecordingUploadStep>[];
      final progress = <(int, int)>[];
      final recording = await repository.upload(
        caseId: "c1",
        supplierId: "s1",
        file: _file(),
        onStep: steps.add,
        onProgress: (sent, total) => progress.add((sent, total)),
      );
      expect(recording.status, CallRecordingStatus.uploaded);
      expect(api.log, ["create", "complete:r1"]);
      expect(api.bodies.single, {
        "supplier_id": "s1",
        "file_name": "통화.m4a",
        "extension": "m4a",
        "size_bytes": 3,
      });
      // The server's URL and type go to the storage untouched, with the
      // file's own bytes and length.
      final put = storage.puts.single;
      expect((put.url, put.contentType, put.length), (_url, "audio/mp4", 3));
      expect(put.bytes, [1, 2, 3]);
      expect(steps, RecordingUploadStep.values);
      expect(progress, [(3, 3)]);
    });

    test("a broken upload is retried as the same recording", () async {
      api.creates.addAll([
        _row("UPLOADING", upload: true),
        _row("UPLOADING", upload: true),
      ]);
      api.completes.add(_row("UPLOADED"));
      storage.failures.add(const RecordingUploadFailed());
      final failure = await _failure(upload());
      expect((failure.code, failure.retryable), ("UPLOAD_INTERRUPTED", true));
      // Nothing to confirm yet.
      expect(api.log, ["create"]);

      await upload();
      // Same key: the server continues the first recording instead of
      // starting a second one.
      expect(api.keys[1], api.keys[0]);
      expect(storage.puts, hasLength(2));
      expect(api.log, ["create", "create", "complete:r1"]);
    });

    test("a refused upload is still checked: the file may be there", () async {
      api.creates.add(_row("UPLOADING", upload: true));
      api.completes.add(_row("UPLOADED"));
      // The storage does not overwrite: an earlier try got through.
      storage.failures.add(const RecordingUploadFailed(statusCode: 400));
      expect((await upload()).status, CallRecordingStatus.uploaded);
      expect(api.log, ["create", "complete:r1"]);
    });

    test("a file that never arrived keeps the recording for a retry", () async {
      api.creates.addAll([
        _row("UPLOADING", upload: true),
        _row("UPLOADING", upload: true),
      ]);
      api.completes.addAll([
        const ApiException(
          409,
          "CALL_RECORDING_UPLOAD_INCOMPLETE",
          "파일 업로드가 아직 끝나지 않았습니다.",
        ),
        _row("UPLOADED"),
      ]);
      storage.failures.add(const RecordingUploadFailed(statusCode: 403));
      final failure = await _failure(upload());
      expect(failure.code, "CALL_RECORDING_UPLOAD_INCOMPLETE");
      expect(failure.retryable, isTrue);
      await upload();
      expect(api.keys[1], api.keys[0]);
    });

    test("a recording finished earlier is returned without sending", () async {
      api.creates.add(_row("UPLOADED"));
      expect((await upload()).status, CallRecordingStatus.uploaded);
      expect(storage.puts, isEmpty);
      expect(api.log, ["create"]);
    });

    test("a dead recording is given up: the next press starts anew", () async {
      api.creates.addAll([
        _row("FAILED", failureReason: "EXPIRED"),
        _row("UPLOADING", upload: true),
      ]);
      api.completes.add(_row("UPLOADED"));
      final failure = await _failure(upload());
      expect(
        (failure.code, failure.retryable),
        ("CALL_RECORDING_FAILED", false),
      );
      expect(storage.puts, isEmpty);
      await upload();
      expect(api.keys[1], isNot(api.keys[0]));
    });

    test("past the upload window the server decides", () async {
      // No upload URL any more; the file may or may not be there.
      api.creates.addAll([_row("UPLOADING"), _row("UPLOADING", upload: true)]);
      api.completes.addAll([
        const ApiException(
          410,
          "CALL_RECORDING_UPLOAD_EXPIRED",
          "업로드 가능 시간이 지났습니다. 다시 추가해 주세요.",
        ),
        _row("UPLOADED"),
      ]);
      final failure = await _failure(upload());
      expect(failure.code, "CALL_RECORDING_UPLOAD_EXPIRED");
      expect(failure.message, "업로드 가능 시간이 지났습니다. 다시 추가해 주세요.");
      expect(storage.puts, isEmpty);
      // Definitely refused: a new recording next time.
      await upload();
      expect(api.keys[1], isNot(api.keys[0]));
    });

    test("an unanswered request keeps its key; a refusal drops it", () async {
      api.creates.addAll([
        const ApiException(
          0,
          "NETWORK_UNAVAILABLE",
          "서버에 연결하지 못했습니다.",
          retryable: true,
          unknownOutcome: true,
        ),
        const ApiException(
          422,
          "CALL_RECORDING_SUPPLIER_NOT_ALLOWED",
          "견적을 요청한 거래처만 고를 수 있습니다.",
        ),
        const ApiException(
          503,
          "CALL_RECORDING_UNAVAILABLE",
          "통화 녹음 기능을 사용할 수 없습니다.",
        ),
      ]);
      final lost = await _failure(upload());
      expect((lost.unknownOutcome, lost.retryable), (true, true));
      final refused = await _failure(upload());
      expect(api.keys[1], api.keys[0]);
      expect(refused.suppliersChanged, isTrue);
      final closed = await _failure(upload());
      expect(api.keys[2], isNot(api.keys[1]));
      expect(closed.unavailable, isTrue);
    });

    test("the key outlives a slow upload and a late retry", () async {
      api.creates.addAll([
        _row("UPLOADING", upload: true),
        _row("UPLOADING", upload: true),
        _row("UPLOADING", upload: true),
      ]);
      storage.failures.addAll(const [
        RecordingUploadFailed(),
        RecordingUploadFailed(),
        RecordingUploadFailed(),
      ]);
      await _failure(upload());
      // Well past the usual ten minutes, still inside the upload window.
      now = now.add(const Duration(minutes: 90));
      await _failure(upload());
      expect(api.keys[1], api.keys[0]);
      // Past the window the server has given the recording up anyway.
      now = now.add(const Duration(hours: 3));
      await _failure(upload());
      expect(api.keys[2], isNot(api.keys[0]));
    });

    test("trying another file does not forget the first one", () async {
      api.creates.addAll([
        _row("UPLOADING", upload: true),
        _row("UPLOADING", upload: true),
        _row("UPLOADING", upload: true),
      ]);
      api.completes.addAll([_row("UPLOADED"), _row("UPLOADED")]);
      storage.failures.add(const RecordingUploadFailed());
      await _failure(upload());
      await upload(file: _file(name: "다른 통화.m4a"));
      // Back to the first file: its recording continues.
      await upload();
      expect(api.keys[2], api.keys[0]);
      expect(api.keys[1], isNot(api.keys[0]));
    });

    test("a file that cannot be read asks for the file again", () async {
      api.creates.addAll([
        _row("UPLOADING", upload: true),
        _row("UPLOADING", upload: true),
      ]);
      api.completes.add(_row("UPLOADED"));
      storage.failures.add(const RecordingUploadFailed(unreadable: true));
      final failure = await _failure(upload());
      expect(failure.code, "FILE_UNREADABLE");
      expect(failure.message, "파일을 읽지 못했습니다. 파일을 다시 골라 주세요.");
      // Nothing to confirm; the same file picked again continues it.
      expect(api.log, ["create"]);
      await upload();
      expect(api.keys[1], api.keys[0]);
    });

    test("another file or supplier is another recording", () async {
      api.creates.addAll([
        _row("UPLOADING", upload: true),
        _row("UPLOADING", upload: true),
        _row("UPLOADING", upload: true),
      ]);
      api.completes.addAll([_row("UPLOADED"), _row("UPLOADED")]);
      storage.failures.add(const RecordingUploadFailed());
      await _failure(upload());
      await upload(file: _file(name: "다른 통화.m4a"));
      await upload(supplierId: "s2");
      expect(api.keys.toSet(), hasLength(3));
    });

    test("a file of unknown size is not sent", () async {
      final failure = await _failure(upload(file: _file(size: null)));
      expect(failure.code, "FILE_SIZE_UNKNOWN");
      expect(api.log, isEmpty);
    });

    test("an answer in an unknown shape is not shown raw", () async {
      api.creates.add({
        "data": {"recording_id": 1},
      });
      final failure = await _failure(upload());
      expect((failure.code, failure.retryable), ("INVALID_RESPONSE", false));
    });
  });

  test("the list carries the limits; failed recordings do not count", () async {
    final list = await repository.getRecordings("c1");
    expect(
      [for (final item in list.items) item.statusLabel],
      [
        "업로드됨",
        "기한 만료",
        // A status this app does not know yet.
        "확인 필요",
      ],
    );
    expect((list.maxPerCase, list.maxBytes), (2, 52428800));
    // UPLOADED + the unknown one; the failed one is free.
    expect(list.limitReached, isTrue);
    expect(
      CallRecordingList(
        items: [list.items[0], list.items[1]],
        maxPerCase: 2,
        maxBytes: 1,
      ).limitReached,
      isFalse,
    );
  });

  test("a server without the list reads as not available", () async {
    // What the data source makes of a missing route.
    api.listError = const ApiException(
      404,
      "CALL_RECORDING_UNAVAILABLE",
      "통화 녹음 기능을 사용할 수 없습니다.",
    );
    final failure = await _failure(repository.getRecordings("c1"));
    expect(failure.unavailable, isTrue);
  });

  group("API requests", () {
    test("a slot request carries the key, the token and the body", () async {
      late RequestOptions sent;
      late List<int> sentBody;
      final source = ApiCallRecordingDataSource(
        _dio((options, body) {
          sent = options;
          sentBody = body;
          return _json(_row("UPLOADING", upload: true), 201);
        }),
        _token,
      );
      final body = {"supplier_id": "s1", "file_name": "통화.m4a"};
      final response = await source.createRecording(
        "c1",
        body,
        idempotencyKey: "key-1",
      );
      expect((response["data"] as Map)["recording_id"], "r1");
      expect(sent.method, "POST");
      expect(sent.path, "/api/v1/work-cases/c1/call-recordings");
      expect(sent.headers["Idempotency-Key"], "key-1");
      expect(sent.headers["Authorization"], "Bearer app-token");
      expect(jsonDecode(utf8.decode(sentBody)), body);
    });

    test(
      "confirming and listing use their own routes, without a key",
      () async {
        final requests = <String>[];
        final source = ApiCallRecordingDataSource(
          _dio((options, body) {
            requests.add("${options.method} ${options.path}");
            expect(options.headers.containsKey("Idempotency-Key"), isFalse);
            return _json(_row("UPLOADED"), 200);
          }),
          _token,
        );
        await source.completeRecording("c1", "r1");
        await source.fetchRecordings("c1");
        expect(requests, [
          "POST /api/v1/work-cases/c1/call-recordings/r1/complete",
          "GET /api/v1/work-cases/c1/call-recordings",
        ]);
      },
    );

    test("a server without the routes reads as not available", () async {
      Future<ApiException> answer(int status, String code) async {
        final source = ApiCallRecordingDataSource(
          _dio(
            (options, body) => _json({
              "error": {"code": code, "message": "서버 문구"},
            }, status),
          ),
          _token,
        );
        try {
          await source.fetchRecordings("c1");
        } on ApiException catch (error) {
          return error;
        }
        fail("expected an ApiException");
      }

      // An unknown route: the feature is not deployed.
      expect(
        (await answer(404, "RESOURCE_NOT_FOUND")).code,
        "CALL_RECORDING_UNAVAILABLE",
      );
      // A missing case is a different thing and keeps its own code.
      expect(
        (await answer(404, "CALL_RECORDING_CASE_NOT_FOUND")).code,
        "CALL_RECORDING_CASE_NOT_FOUND",
      );
      final closed = await answer(503, "CALL_RECORDING_UNAVAILABLE");
      expect(closed.code, "CALL_RECORDING_UNAVAILABLE");
    });
  });

  group("delete", () {
    test(
      "goes to the recording's own route and needs no answer body",
      () async {
        final requests = <String>[];
        final source = ApiCallRecordingDataSource(
          _dio((options, body) {
            requests.add("${options.method} ${options.path}");
            expect(options.headers.containsKey("Idempotency-Key"), isFalse);
            expect(options.headers["Authorization"], "Bearer app-token");
            return ResponseBody.fromString("", 204);
          }),
          _token,
        );
        await source.deleteRecording("c1", "r1");
        expect(requests, ["DELETE /api/v1/work-cases/c1/call-recordings/r1"]);
      },
    );

    test("a refusal keeps the server's code and message", () async {
      final source = ApiCallRecordingDataSource(
        _dio(
          (options, body) => _json({
            "error": {
              "code": "CALL_RECORDING_DELETE_NOT_ALLOWED",
              "message": "지금은 이 녹음을 삭제할 수 없습니다.",
            },
          }, 409),
        ),
        _token,
      );
      final failure = await _failure(
        CallRecordingRepositoryImpl(
          source,
          storage,
        ).deleteRecording("c1", "r1"),
      );
      expect(failure.code, "CALL_RECORDING_DELETE_NOT_ALLOWED");
      expect(failure.message, "지금은 이 녹음을 삭제할 수 없습니다.");
    });

    test("a server without the route reads as not available", () async {
      final source = ApiCallRecordingDataSource(
        _dio(
          (options, body) => _json({
            "error": {"code": "HTTP_404", "message": "Not Found"},
          }, 404),
        ),
        _token,
      );
      final failure = await _failure(
        CallRecordingRepositoryImpl(
          source,
          storage,
        ).deleteRecording("c1", "r1"),
      );
      expect(failure.unavailable, isTrue);
    });

    test("the repository passes the case and the recording on", () async {
      await repository.deleteRecording("c1", "r9");
      expect(api.deletes, ["c1/r9"]);
    });

    test("the list says whether deleting is offered", () async {
      expect((await repository.getRecordings("c1")).deletable, isFalse);
      api.deletable = true;
      expect((await repository.getRecordings("c1")).deletable, isTrue);
    });
  });

  group("file upload", () {
    Stream<List<int>> bytes() => Stream.fromIterable(const [
      [1, 2, 3],
      [4, 5],
    ]);

    test(
      "PUTs the raw bytes to the signed URL, without the app token",
      () async {
        late RequestOptions sent;
        late List<int> sentBody;
        final uploader = DioRecordingFileUploader(
          _dio((options, body) {
            sent = options;
            sentBody = body;
            return ResponseBody.fromString('{"Key":"x"}', 200);
          }),
        );
        final progress = <(int, int)>[];
        await uploader.upload(
          url: _url,
          contentType: "audio/mp4",
          length: 5,
          open: bytes,
          onProgress: (sent, total) => progress.add((sent, total)),
        );
        expect(sent.method, "PUT");
        // The absolute URL wins over the API base URL.
        expect(sent.uri.toString(), _url);
        expect(sent.headers[Headers.contentTypeHeader], "audio/mp4");
        expect(sent.headers[Headers.contentLengthHeader], 5);
        expect(sent.headers.keys.map((key) => key.toLowerCase()), [
          "content-type",
          "content-length",
        ]);
        // A long file must not hit the API's 15 s send limit.
        expect(sent.sendTimeout, Duration.zero);
        expect(sentBody, [1, 2, 3, 4, 5]);
        expect(progress.last, (5, 5));
      },
    );

    test("a refusal reports the status and never the signed URL", () async {
      final uploader = DioRecordingFileUploader(
        _dio(
          (options, body) =>
              _json({"statusCode": "409", "error": "Duplicate"}, 400),
        ),
      );
      try {
        await uploader.upload(
          url: _url,
          contentType: "audio/mp4",
          length: 5,
          open: bytes,
        );
        fail("expected a failure");
      } on RecordingUploadFailed catch (failure) {
        expect(failure.statusCode, 400);
        expect(failure.toString(), isNot(contains("secret")));
      }
    });

    test(
      "no answer and an unreadable file are failures without a status",
      () async {
        final offline = DioRecordingFileUploader(
          _dio(
            (options, body) => throw DioException.connectionError(
              requestOptions: options,
              reason: "offline",
            ),
          ),
        );
        final upload = offline.upload(
          url: _url,
          contentType: "audio/mp4",
          length: 5,
          open: bytes,
        );
        await expectLater(
          upload,
          throwsA(
            isA<RecordingUploadFailed>().having(
              (failure) => failure.statusCode,
              "statusCode",
              isNull,
            ),
          ),
        );

        final gone = DioRecordingFileUploader(
          _dio((options, body) => ResponseBody.fromString("", 200)),
        );
        await expectLater(
          gone.upload(
            url: _url,
            contentType: "audio/mp4",
            length: 5,
            open: () => Stream.error(StateError("file removed")),
          ),
          throwsA(
            isA<RecordingUploadFailed>().having(
              (failure) => failure.unreadable,
              "unreadable",
              isTrue,
            ),
          ),
        );
      },
    );

    test("a slow upload that keeps moving outlives the stall limit", () async {
      final uploader = DioRecordingFileUploader(
        _dio((options, body) => ResponseBody.fromString("", 200)),
        stallTimeout: const Duration(milliseconds: 200),
      );
      // Six chunks 50 ms apart: 300 ms in all, never 200 ms idle.
      Stream<List<int>> slow() async* {
        for (var i = 0; i < 6; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          yield [i];
        }
      }

      final progress = <(int, int)>[];
      await uploader.upload(
        url: _url,
        contentType: "audio/mp4",
        length: 6,
        open: slow,
        onProgress: (sent, total) => progress.add((sent, total)),
      );
      expect(progress.last, (6, 6));
    });

    test("an upload that stalls midway is given up", () async {
      final uploader = DioRecordingFileUploader(
        _dio((options, body) => ResponseBody.fromString("", 200)),
        stallTimeout: const Duration(milliseconds: 20),
      );
      // Two of five bytes, then silence.
      final source = StreamController<List<int>>()..add([1, 2]);
      await expectLater(
        uploader.upload(
          url: _url,
          contentType: "audio/mp4",
          length: 5,
          open: () => source.stream,
        ),
        throwsA(isA<RecordingUploadFailed>()),
      );
    });

    test("no answer after the last byte is given up too", () async {
      final never = Completer<ResponseBody>();
      final uploader = DioRecordingFileUploader(
        _dio((options, body) => never.future),
        stallTimeout: const Duration(milliseconds: 20),
        answerTimeout: const Duration(milliseconds: 20),
      );
      final progress = <(int, int)>[];
      await expectLater(
        uploader.upload(
          url: _url,
          contentType: "audio/mp4",
          length: 5,
          open: bytes,
          onProgress: (sent, total) => progress.add((sent, total)),
        ),
        throwsA(isA<RecordingUploadFailed>()),
      );
      // Every byte was read; only the answer never came.
      expect(progress.last, (5, 5));
    });

    test("an upload that stops moving is given up", () async {
      final never = Completer<ResponseBody>();
      final uploader = DioRecordingFileUploader(
        _dio((options, body) => never.future),
        stallTimeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        uploader.upload(
          url: _url,
          contentType: "audio/mp4",
          length: 5,
          // Opens, sends nothing, never ends.
          open: () => StreamController<List<int>>().stream,
        ),
        throwsA(isA<RecordingUploadFailed>()),
      );
    });
  });
}
