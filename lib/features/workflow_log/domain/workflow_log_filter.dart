import "workflow_log.dart";

enum LogPeriod {
  all("전체", null),
  today("오늘", Duration(days: 1)),
  week("최근 7일", Duration(days: 7)),
  month("최근 30일", Duration(days: 30));

  const LogPeriod(this.label, this.window);
  final String label;
  final Duration? window;
}

/// API-28 search conditions. Changing any of them restarts from page one.
class WorkflowLogFilter {
  const WorkflowLogFilter({
    this.caseQuery = "",
    this.period = LogPeriod.all,
    this.actor,
    this.eventType,
    this.outcome,
    this.sendPolicy,
  });

  final String caseQuery;
  final LogPeriod period;
  final LogActor? actor;
  final LogEventType? eventType;
  final LogOutcome? outcome;
  final SendPolicy? sendPolicy;

  bool get isEmpty =>
      caseQuery.isEmpty &&
      period == LogPeriod.all &&
      actor == null &&
      eventType == null &&
      outcome == null &&
      sendPolicy == null;

  WorkflowLogFilter copyWith({
    String? caseQuery,
    LogPeriod? period,
    LogActor? Function()? actor,
    LogEventType? Function()? eventType,
    LogOutcome? Function()? outcome,
    SendPolicy? Function()? sendPolicy,
  }) {
    return WorkflowLogFilter(
      caseQuery: caseQuery ?? this.caseQuery,
      period: period ?? this.period,
      actor: actor == null ? this.actor : actor(),
      eventType: eventType == null ? this.eventType : eventType(),
      outcome: outcome == null ? this.outcome : outcome(),
      sendPolicy: sendPolicy == null ? this.sendPolicy : sendPolicy(),
    );
  }

  /// Query parameters in the 08 snake_case form.
  Map<String, String> toQuery({DateTime? now}) {
    final window = period.window;
    return {
      if (caseQuery.isNotEmpty) "q": caseQuery,
      if (window != null)
        "from": (now ?? DateTime.now()).toUtc().subtract(window).toIso8601String(),
      if (actor != null) "agent_role": actor!.code,
      if (eventType != null) "event_type": eventType!.code,
      if (outcome != null) "outcome": outcome!.code,
      if (sendPolicy != null) "send_policy": sendPolicy!.code,
    };
  }
}
