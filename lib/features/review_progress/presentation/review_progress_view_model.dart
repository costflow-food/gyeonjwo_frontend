import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

const reviewSteps = [
  '요청 정보와 필수 조건 확인',
  '구매 근거와 DB 후보 비교',
  '계약 조건과 비용 영향 정리',
  '검토카드 준비',
];

final reviewProgressProvider =
    NotifierProvider<ReviewProgressViewModel, Map<String, int>>(
      ReviewProgressViewModel.new,
    );

/// Local preview only. Keep progress outside the dialog so closing it does
/// not cancel a request. Replace the timer with server progress later.
class ReviewProgressViewModel extends Notifier<Map<String, int>> {
  final _timers = <String, Timer>{};

  @override
  Map<String, int> build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
    });
    return {};
  }

  void start(String requestId) {
    if (state.containsKey(requestId)) return;
    _run(requestId);
  }

  void _run(String requestId) {
    state = {...state, requestId: 0};
    _timers[requestId] = Timer.periodic(const Duration(seconds: 2), (timer) {
      final next = state[requestId]! + 1;
      state = {...state, requestId: next};
      if (next >= reviewSteps.length) {
        timer.cancel();
        _timers.remove(requestId);
      }
    });
  }
}
