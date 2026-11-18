import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../../shared/preferences.dart";

/// 최근 본 업무 id(최근 것이 앞). 상단 바 검색 창의 '최근 본 업무'에 씁니다.
/// 브라우저 저장소에 남겨 새로고침해도 유지합니다.
class RecentTasks extends Notifier<List<String>> {
  static const _key = "recent_task_ids";
  static const limit = 5;

  SharedPreferences? get _preferences {
    try {
      return ref.read(sharedPreferencesProvider);
    } on Object {
      // 저장소를 못 쓰는 환경(테스트 등)은 메모리에만 둡니다.
      return null;
    }
  }

  @override
  List<String> build() => _preferences?.getStringList(_key) ?? const [];

  /// [caseId] 업무를 열었습니다.
  void visit(String? caseId) {
    if (caseId == null || caseId.isEmpty) return;
    if (state.isNotEmpty && state.first == caseId) return;
    state = [
      caseId,
      ...state.where((id) => id != caseId),
    ].take(limit).toList(growable: false);
    _preferences?.setStringList(_key, state);
  }
}

final recentTasksProvider = NotifierProvider<RecentTasks, List<String>>(
  RecentTasks.new,
);
