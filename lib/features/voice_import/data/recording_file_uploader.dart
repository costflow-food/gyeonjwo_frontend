import "dart:async";

import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/network/api_client.dart";

final recordingFileUploaderProvider = Provider<RecordingFileUploader>(
  (ref) => DioRecordingFileUploader(ref.watch(apiClientProvider)),
);

/// The file did not reach the storage.
class RecordingUploadFailed implements Exception {
  const RecordingUploadFailed({this.statusCode, this.unreadable = false});

  /// The storage's answer. Null when there was none: no connection, a
  /// stalled upload, or a file that could not be read.
  final int? statusCode;

  /// The picked file itself could not be read (its cached copy is gone).
  final bool unreadable;

  @override
  String toString() => "RecordingUploadFailed(${statusCode ?? "-"})";
}

/// Sends a recording's bytes to the signed upload URL the server issued.
abstract interface class RecordingFileUploader {
  /// [open] is called once; it must yield exactly [length] bytes.
  /// Throws [RecordingUploadFailed].
  Future<void> upload({
    required String url,
    required String contentType,
    required int length,
    required Stream<List<int>> Function() open,
    void Function(int sent, int total)? onProgress,
  });
}

class DioRecordingFileUploader implements RecordingFileUploader {
  DioRecordingFileUploader(
    this._dio, {
    this.stallTimeout = const Duration(seconds: 60),
    this.answerTimeout = const Duration(minutes: 2),
  });

  final Dio _dio;

  /// How long the upload may make no progress before it is given up.
  final Duration stallTimeout;

  /// How long the storage may take to answer once the last bytes are read.
  final Duration answerTimeout;

  @override
  Future<void> upload({
    required String url,
    required String contentType,
    required int length,
    required Stream<List<int>> Function() open,
    void Function(int sent, int total)? onProgress,
  }) async {
    // A recording can take minutes on a phone network, so there is no cap on
    // the whole send; a stalled connection is cut instead.
    final cancel = CancelToken();
    Timer? stall;
    void watch([Duration extra = Duration.zero]) {
      stall?.cancel();
      stall = Timer(stallTimeout + extra, cancel.cancel);
    }

    var unreadable = false;

    watch();
    try {
      // The signed URL is absolute and carries its own token: no app
      // Authorization header, and the body is the raw file.
      await _dio.put<Object?>(
        url,
        // A read error reaches dio like a dropped connection: mark it here.
        data: open().handleError((Object error, StackTrace stackTrace) {
          unreadable = true;
          Error.throwWithStackTrace(error, stackTrace);
        }),
        cancelToken: cancel,
        onSendProgress: (sent, total) {
          // The last chunk is reported when it is read, not when it is on
          // the wire: the limit then also covers the flush and the answer.
          watch(sent >= total ? answerTimeout : Duration.zero);
          onProgress?.call(sent, total);
        },
        options: Options(
          contentType: contentType,
          headers: {Headers.contentLengthHeader: length},
          sendTimeout: Duration.zero,
          receiveTimeout: answerTimeout,
          responseType: ResponseType.plain,
        ),
      );
    } on DioException catch (error) {
      // Not rethrown: its request URL holds the upload token.
      throw RecordingUploadFailed(
        statusCode: error.response?.statusCode,
        unreadable: unreadable,
      );
    } finally {
      stall?.cancel();
    }
  }
}
