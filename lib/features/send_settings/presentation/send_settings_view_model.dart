import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/send_settings_repository_impl.dart";
import "../domain/send_settings.dart";
import "../../mail_draft/presentation/mail_draft_view_model.dart";

part "send_settings_view_model.g.dart";

Duration? _noRetry(int retryCount, Object error) => null;

/// Family key for the mailbox default; a case uses its own ID.
const mailboxSettingsScope = "";

String sendSettingsScope(String? caseId) => caseId ?? mailboxSettingsScope;

/// SCR-008 effective settings for the mailbox or one case.
@Riverpod(keepAlive: true, retry: _noRetry)
class SendSettingsViewModel extends _$SendSettingsViewModel {
  String? get _caseId => scope == mailboxSettingsScope ? null : scope;

  @override
  Future<SendSettings> build(String scope) =>
      ref.watch(sendSettingsRepositoryProvider).getSettings(caseId: _caseId);

  void refresh() => ref.invalidateSelf();

  Future<SendSettings> save(
    SendSettingsUpdate update, {
    required String idempotencyKey,
  }) async {
    final saved = await ref
        .read(sendSettingsRepositoryProvider)
        .saveSettings(update, caseId: _caseId, idempotencyKey: idempotencyKey);
    if (ref.mounted) state = AsyncData(saved);
    if (ref.mounted &&
        _caseId != null &&
        update.applyTo == ApplyTo.specifiedDrafts) {
      ref.invalidate(mailDraftViewModelProvider(_caseId!));
    }
    // Case scopes inherit from the mailbox, so stale copies must reload.
    if (ref.mounted) ref.invalidate(sendSettingsViewModelProvider);
    return saved;
  }
}
