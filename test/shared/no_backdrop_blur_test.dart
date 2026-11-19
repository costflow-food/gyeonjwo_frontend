import "dart:io";

import "package:flutter_test/flutter_test.dart";

/// 팝업 뒤 전체 화면 흐림(BackdropFilter)은 웹(CanvasKit)에서 열리는 애니메이션의
/// 매 프레임마다 화면 전체를 다시 읽어 흐리게 하므로 쓰지 않습니다.
/// 팝업 뒤는 [LdsDialog.barrierColor]로 어둡게만 합니다.
void main() {
  test("no full-screen backdrop blur in the app", () {
    final offenders = [
      for (final file in Directory("lib").listSync(recursive: true))
        if (file is File &&
            file.path.endsWith(".dart") &&
            file.readAsStringSync().contains("BackdropFilter("))
          file.path,
    ];
    expect(offenders, isEmpty);
  });
}
