import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/mail_draft/data/mail_draft_preview_data.dart';
import '../features/send_settings/data/send_settings_preview_data.dart';
import 'formatters.dart';

part 'preview_workspace.g.dart';

@Riverpod(keepAlive: true)
PreviewWorkspace previewWorkspace(Ref ref) => PreviewWorkspace();

/// Session-only data shared by the preview API implementations.
/// Real API implementations do not use this store.
class PreviewWorkspace {
  final Map<String, dynamic> mailbox = _copy(sendSettingsPreviewMailbox);
  final Map<String, dynamic> cases = _copy(sendSettingsPreviewCases);
  final Map<String, List<Map<String, dynamic>>> drafts = {
    for (final entry in mailDraftPreviewDrafts.entries)
      entry.key: [
        for (final draft in entry.value)
          {..._copy(draft), 'case_id': entry.key},
      ],
  };
  final sendingSince = <String, DateTime>{};
  final requests = <Map<String, dynamic>>[];
  final documents = <String, Map<String, dynamic>>{};
  int draftSequence = 0;

  int settingsVersion(String? caseId) {
    final current = cases[caseId] as Map?;
    return (mailbox['version'] as int) * 100 +
        ((current?['version'] as int?) ?? 0);
  }

  Map<String, dynamic> sendScope(String? caseId) {
    final current = cases[caseId] as Map?;
    return {
      for (final key in ['allowed_supplier_ids', 'tone', 'signature'])
        key: current != null && current.containsKey(key)
            ? current[key]
            : mailbox[key],
    };
  }

  bool? approvalFor(String? caseId, String purpose, [Map? override]) {
    final base = (mailbox['approval'] as Map)[purpose] as bool?;
    if (caseId == null) {
      if (override != null) return override[purpose] as bool?;
      return base;
    }
    final own = override ?? (cases[caseId] as Map?)?['approval'] as Map?;
    return (own?[purpose] as bool?) ?? base;
  }

  /// Copies the effective policy onto one newly created or selected draft.
  void applyDraftPolicy(Map<String, dynamic> draft) {
    final caseId = draft['case_id'] as String;
    final scope = sendScope(caseId);
    final approval = approvalFor(caseId, draft['purpose'] as String);
    draft['approval_required'] = approval ?? true;
    draft['settings_configured'] = [
      'RFQ',
      'CLARIFICATION',
      'COUNTER_OFFER',
    ].every((purpose) => approvalFor(caseId, purpose) != null);
    draft['auto_send_allowed'] =
        (scope['allowed_supplier_ids'] as List).contains(
          draft['supplier_id'],
        ) &&
        sendSettingsPreviewSuppliers.any(
          (supplier) =>
              supplier['supplier_id'] == draft['supplier_id'] &&
              supplier['email'] == draft['recipient'],
        );
    draft['settings_version'] = settingsVersion(caseId);
  }

  String createRequest(Map<String, dynamic> mail) {
    final id = 'REQ-PREVIEW-${mail['mail_id']}';
    if (requests.any((request) => request['id'] == id)) return id;
    final received = formatSeoulDateTime(mail['received_at'] as String);
    requests.insert(0, {
      'id': id,
      'title': mail['subject'],
      'supplier': mail['sender'],
      'attachments': (mail['attachments'] as List).length,
      'status': '검토 대기',
      'date': received.split(' ').first,
      'time': received.split(' ').last,
      'action': '실행',
    });
    documents[id] = {
      'title': mail['subject'],
      'sender': mail['sender'],
      'recipient': '구매담당자 (합성)',
      'receivedAt': received,
      'documentType': '접수 확인 메일',
      'paragraphs': [mail['body_text']],
      'highlights': <String>[],
      'attachments': mail['attachments'],
    };
    return id;
  }

  static Map<String, dynamic> _copy(Object value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}
