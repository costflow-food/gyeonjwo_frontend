import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hitl_preview_data.dart';
import '../domain/hitl_request.dart';

/// 시연 결정만 보관합니다. API 호출·메일 발송·실제 업무 상태 변경은 없습니다.
class HitlViewModel extends Notifier<List<HitlRequest>> {
  @override
  List<HitlRequest> build() => List.unmodifiable(hitlPreviewRequests);

  bool decide(String id, HitlStatus next, String note, String value) {
    final found = state.where((request) => request.id == id).firstOrNull;
    if (found == null || !found.status.actionable || value.trim().isEmpty) {
      return false;
    }
    if ((next == HitlStatus.held || next == HitlStatus.returned) &&
        note.trim().isEmpty) {
      return false;
    }
    if (next == HitlStatus.waiting) return false;
    state = List.unmodifiable([
      for (final request in state)
        if (request.id == id)
          request.decide(next, note.trim(), value.trim())
        else
          request,
    ]);
    return true;
  }
}

final hitlViewModelProvider =
    NotifierProvider<HitlViewModel, List<HitlRequest>>(HitlViewModel.new);
