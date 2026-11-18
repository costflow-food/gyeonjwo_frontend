import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../../shared/preferences.dart";
import "../../workflow_log/data/workflow_log_repository_impl.dart";
import "../../workflow_log/domain/workflow_log.dart";
import "../../workflow_log/domain/workflow_log_filter.dart";

/// 알림 종류. 알림 전용 API가 없어 실행 로그(API-28)에서 골라 만듭니다.
enum AppNotificationKind {
  mailReceived("새 메일이 접수됐어요"),
  needsAttention("확인이 필요해서 멈춘 업무가 있어요"),
  reviewReady("검토 카드가 준비됐어요"),
  sendFailed("메일 발송에 실패했어요"),
  reviewFailed("검토 실행에 실패했어요");

  const AppNotificationKind(this.title);
  final String title;

  static AppNotificationKind? of(WorkflowLogEntry entry) {
    final failed = entry.outcome == LogOutcome.failure;
    return switch (entry.eventType) {
      LogEventType.mailReceived => mailReceived,
      LogEventType.hold || LogEventType.approvalRequired => needsAttention,
      LogEventType.reviewCreated => reviewReady,
      LogEventType.graphFailed => reviewFailed,
      LogEventType.sendUnknown || LogEventType.failed => sendFailed,
      LogEventType.sendResult when failed => sendFailed,
      _ => null,
    };
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.detail,
    required this.createdAt,
    this.caseId,
  });

  final String id;
  final AppNotificationKind kind;

  /// '[업무 이름] 요약' 한 줄.
  final String detail;
  final DateTime createdAt;
  final String? caseId;
}

class NotificationsState {
  const NotificationsState({required this.items, required this.readBefore});

  final List<AppNotification> items;

  /// 이 시각까지의 알림은 읽음.
  final DateTime readBefore;

  bool isRead(AppNotification item) => !item.createdAt.isAfter(readBefore);
  bool get hasUnread => items.any((item) => !isRead(item));
}

/// 상단 바 알림: 최근 실행 로그에서 알림거리만 모읍니다. 1분마다 새로 읽습니다.
class NotificationsViewModel extends AsyncNotifier<NotificationsState> {
  static const _readKey = "notifications_read_before";
  static const limit = 10;
  static const _pages = 3;
  static const _poll = Duration(minutes: 1);

  SharedPreferences? get _preferences {
    try {
      return ref.read(sharedPreferencesProvider);
    } on Object {
      return null;
    }
  }

  DateTime _readBefore() {
    final saved = _preferences?.getString(_readKey);
    return (saved == null ? null : DateTime.tryParse(saved)) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  @override
  Future<NotificationsState> build() async {
    final timer = Timer(_poll, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
    final repository = ref.watch(workflowLogRepositoryProvider);
    final items = <AppNotification>[];
    String? cursor;
    for (var page = 0; page < _pages && items.length < limit; page++) {
      final result = await repository.getLogs(
        const WorkflowLogFilter(),
        cursor: cursor,
      );
      for (final entry in result.items) {
        final kind = AppNotificationKind.of(entry);
        final at = DateTime.tryParse(entry.createdAt);
        if (kind == null || at == null) continue;
        items.add(
          AppNotification(
            id: entry.id,
            kind: kind,
            detail: [
              if (entry.caseTitle case final title?) "[$title]",
              if (entry.summary.isNotEmpty) entry.summary,
            ].join(" "),
            createdAt: at,
            caseId: entry.caseId,
          ),
        );
        if (items.length >= limit) break;
      }
      cursor = result.nextCursor;
      if (cursor == null) break;
    }
    return NotificationsState(
      items: List.unmodifiable(items),
      readBefore: _readBefore(),
    );
  }

  void refresh() => ref.invalidateSelf();

  /// '모두 읽음'.
  void markAllRead() {
    final current = state.value;
    if (current == null) return;
    final now = DateTime.now().toUtc();
    _preferences?.setString(_readKey, now.toIso8601String());
    state = AsyncData(
      NotificationsState(items: current.items, readBefore: now),
    );
  }
}

final notificationsViewModelProvider =
    AsyncNotifierProvider<NotificationsViewModel, NotificationsState>(
      NotificationsViewModel.new,
    );
