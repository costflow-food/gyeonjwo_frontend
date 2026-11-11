import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/voice_import/data/voice_file_picker.dart";
import "package:gyeonjwo_frontend/features/voice_import/domain/voice_file.dart";
import "package:gyeonjwo_frontend/features/voice_import/presentation/voice_import_flow.dart";
import "package:gyeonjwo_frontend/features/voice_import/presentation/widgets/call_recording_section.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

/// Answers each pick from [results]: a file, null (cancelled) or an error.
class _Picker implements VoiceFilePicker {
  _Picker(this.results);

  final List<Object?> results;
  int picks = 0;

  @override
  Future<VoiceFile?> pick() async {
    final result = results[picks++];
    if (result is Exception) throw result;
    return result as VoiceFile?;
  }
}

VoiceFile _file(String name, int size) => VoiceFile(
  name: name,
  extension: name.split(".").last,
  sizeBytes: size,
  uri: Uri.parse("content://media/$name"),
);

const _caseTitle = "[달콤농원] 냉동 딸기 적용일 협의 안내";

/// A case screen stand-in with the 통화 녹음 section.
Future<void> _pumpCase(WidgetTester tester, _Picker picker) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [voiceFilePickerProvider.overrideWithValue(picker)],
      child: MaterialApp(
        theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CallRecordingSection(
                onAdd: () =>
                    addCallRecording(context, ref, caseTitle: _caseTitle),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester) async {
  await tester.tap(find.text("통화 녹음 추가"));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("a picked recording opens the confirm screen", (tester) async {
    final picker = _Picker([
      _file("통화 녹음 달콤농원_20261111_1432.m4a", 2516582),
      _file("회의_단가협의.mp3", 13317357),
    ]);
    await _pumpCase(tester, picker);
    await _choose(tester);
    expect(find.text("통화 녹음 추가"), findsOneWidget);
    expect(find.text(_caseTitle), findsOneWidget);
    expect(find.text("통화 녹음 달콤농원_20261111_1432.m4a"), findsOneWidget);
    expect(find.text("M4A · 2.4MB"), findsOneWidget);
    // No upload API yet.
    final upload = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text("업로드 · 준비 중"),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    expect(upload.onPressed, isNull);
    // 다른 파일 replaces it.
    await tester.tap(find.text("다른 파일"));
    await tester.pumpAndSettle();
    expect(find.text("회의_단가협의.mp3"), findsOneWidget);
    expect(find.text("MP3 · 12.7MB"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a file that is not a recording only shows a message", (
    tester,
  ) async {
    await _pumpCase(tester, _Picker([const VoiceFileRejected()]));
    await _choose(tester);
    expect(find.text("오디오 파일만 가져올 수 있습니다."), findsOneWidget);
    expect(find.text(_caseTitle), findsNothing);
  });

  testWidgets("cancelling the picker stays on the case", (tester) async {
    final picker = _Picker([null]);
    await _pumpCase(tester, picker);
    await _choose(tester);
    expect(picker.picks, 1);
    expect(find.text("통화 녹음"), findsOneWidget);
    expect(find.text(_caseTitle), findsNothing);
  });
}
