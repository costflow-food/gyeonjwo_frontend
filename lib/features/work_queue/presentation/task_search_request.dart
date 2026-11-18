import "package:flutter_riverpod/flutter_riverpod.dart";

/// 상단 바 검색 버튼(SSOT 3-2)이 Tasks 목록 검색칸에 포커스를 달라고 남기는
/// 요청. 다른 화면에서 누르면 Tasks로 옮긴 뒤 목록이 받아 갑니다.
class TaskSearchRequest extends Notifier<bool> {
  @override
  bool build() => false;

  void request() => state = true;

  /// 목록이 검색칸에 포커스를 준 뒤 부릅니다.
  void handled() => state = false;
}

final taskSearchRequestProvider = NotifierProvider<TaskSearchRequest, bool>(
  TaskSearchRequest.new,
);
