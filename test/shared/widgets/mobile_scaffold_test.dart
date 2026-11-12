import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/shared/widgets/mobile_scaffold.dart";

void main() {
  test("a phone stays upright in either orientation", () {
    expect(allowedOrientations(const Size(360, 800)), const [
      DeviceOrientation.portraitUp,
    ]);
    // Already sideways: still a phone, so it turns back upright.
    expect(allowedOrientations(const Size(800, 360)), const [
      DeviceOrientation.portraitUp,
    ]);
  });

  test("a tablet keeps every orientation", () {
    expect(allowedOrientations(const Size(600, 960)), isEmpty);
    expect(allowedOrientations(const Size(1280, 800)), isEmpty);
  });
}
