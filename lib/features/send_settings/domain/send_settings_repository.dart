import "send_settings.dart";

abstract interface class SendSettingsRepository {
  /// API-21. Mailbox default, or the merged settings of one case.
  Future<SendSettings> getSettings({String? caseId});

  /// API-22. Creates a new settings version.
  Future<SendSettings> saveSettings(
    SendSettingsUpdate update, {
    String? caseId,
    required String idempotencyKey,
  });
}
