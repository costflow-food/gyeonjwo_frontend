import "dart:async";

import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:supabase_flutter/supabase_flutter.dart";

part "work_case_change_source.g.dart";

/// Supabase Realtime "work_cases changed" signal.
///
/// It carries no data on purpose: listeners re-read the queue through
/// API-01, so mail bodies and DTOs still come only from the server API.
/// The owner_read RLS policy limits insert/update events to the owner.
abstract interface class WorkCaseChangeSource {
  /// Emits an increasing number on every change, and once after each
  /// (re)connect because changes may have been missed while disconnected.
  Stream<int> watch();
}

@Riverpod(keepAlive: true)
WorkCaseChangeSource workCaseChangeSource(Ref ref) =>
    SupabaseWorkCaseChangeSource(Supabase.instance.client);

class SupabaseWorkCaseChangeSource implements WorkCaseChangeSource {
  const SupabaseWorkCaseChangeSource(this._client);

  final SupabaseClient _client;

  @override
  Stream<int> watch() {
    var count = 0;
    RealtimeChannel? channel;
    late final StreamController<int> controller;
    controller = StreamController<int>(
      onListen: () {
        channel = _client
            .channel("work-cases-changes")
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: "public",
              table: "work_cases",
              // The row payload is ignored; data comes from the API.
              callback: (_) => controller.add(++count),
            )
            .subscribe((status, _) {
              if (status == RealtimeSubscribeStatus.subscribed) {
                controller.add(++count);
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
}
