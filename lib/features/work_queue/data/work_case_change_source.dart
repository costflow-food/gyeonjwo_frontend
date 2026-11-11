import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:supabase_flutter/supabase_flutter.dart";

part "work_case_change_source.g.dart";

/// Supabase Realtime "work_cases changed" signal.
///
/// It carries only the case id on purpose: listeners re-read that case
/// (API-02) or the queue (API-01), so DTOs still come only from the server
/// API. The owner_read RLS policy limits insert/update events to the owner.
abstract interface class WorkCaseChangeSource {
  /// Emits on every change, and once after each (re)connect because changes
  /// may have been missed while disconnected.
  Stream<WorkCaseChange> watch();
}

enum WorkCaseChangeKind { resync, inserted, updated, deleted }

class WorkCaseChange {
  const WorkCaseChange(this.sequence, this.kind, [this.caseId]);

  final int sequence;
  final WorkCaseChangeKind kind;

  /// null for [WorkCaseChangeKind.resync]: anything may have changed.
  final String? caseId;
}

@Riverpod(keepAlive: true)
WorkCaseChangeSource workCaseChangeSource(Ref ref) =>
    SupabaseWorkCaseChangeSource(Supabase.instance.client);

class SupabaseWorkCaseChangeSource implements WorkCaseChangeSource {
  const SupabaseWorkCaseChangeSource(this._client);

  final SupabaseClient _client;

  @override
  Stream<WorkCaseChange> watch() {
    var count = 0;
    RealtimeChannel? channel;
    late final StreamController<WorkCaseChange> controller;
    controller = StreamController<WorkCaseChange>(
      onListen: () {
        channel = _client
            .channel("work-cases-changes")
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: "public",
              table: "work_cases",
              callback: (payload) => controller.add(_change(++count, payload)),
            )
            .subscribe((status, _) {
              if (status == RealtimeSubscribeStatus.subscribed) {
                controller.add(
                  WorkCaseChange(++count, WorkCaseChangeKind.resync),
                );
              }
            });
      },
      onCancel: () async {
        final current = channel;
        channel = null;
        if (current != null) await _client.removeChannel(current);
      },
    );
    return controller.stream;
  }

  /// A delete event carries only the primary key (`id`) in the old record.
  static WorkCaseChange _change(int sequence, PostgresChangePayload payload) {
    final (kind, record) = switch (payload.eventType) {
      PostgresChangeEvent.insert => (
        WorkCaseChangeKind.inserted,
        payload.newRecord,
      ),
      PostgresChangeEvent.delete => (
        WorkCaseChangeKind.deleted,
        payload.oldRecord,
      ),
      _ => (WorkCaseChangeKind.updated, payload.newRecord),
    };
    final id = record["id"];
    return id is String
        ? WorkCaseChange(sequence, kind, id)
        : WorkCaseChange(sequence, WorkCaseChangeKind.resync);
  }
}
