import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

part "preferences.g.dart";

/// 앱 시작 때 읽어 둔 브라우저 저장소. `main`에서 값을 넣습니다.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError("main에서 SharedPreferences를 넣어 주세요.");
