import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/mail_draft/data/mail_draft_preview_data.dart';
import '../features/send_settings/data/send_settings_preview_data.dart';
import '../features/work_queue/data/work_queue_preview_data.dart';

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

  /// API-01 rows and API-25 mails for the preview work queue.
  final List<Map<String, dynamic>> queueCases = [
    for (final item in workQueuePreviewCases) _copy(item),
  ];
  final Map<String, Map<String, dynamic>> mails = {
    for (final entry in workQueuePreviewMails.entries)
      entry.key: _copy(entry.value),
  };
  final Map<String, Map<String, dynamic>> candidateSets = {
    for (final entry in workQueuePreviewCandidateSets.entries)
      entry.key: _copy(entry.value),
  };
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

  /// SCR-009 "새 업무로 접수": a Waiting case that has not been extracted yet.
  String createRequest(Map<String, dynamic> mail) {
    final mailId = mail['mail_id'] as String;
    final id = 'case-preview-$mailId';
    if (queueCases.any((item) => item['case_id'] == id)) return id;
    final attachments = [
      for (final (index, name) in (mail['attachments'] as List).indexed)
        {
          'attachment_id': '$mailId-attachment-$index',
          'filename': name,
          'mime_type': 'application/octet-stream',
          'size_bytes': 0,
        },
    ];
    queueCases.insert(0, {
      'case_id': id,
      'initial_mail_id': mailId,
      'item_name': null,
      'title': mail['subject'],
      'sender': mail['sender'],
      'sender_name': null,
      'received_at': mail['received_at'],
      'status': 'Waiting',
      'processing_step': 'PENDING_START',
      'step_detail': {'code': 'PENDING_START', 'message': '원문 확인 후 검토 시작'},
      'input_revision': 1,
      'attachment_count': attachments.length,
      'allowed_actions': ['VIEW_ORIGINAL', 'START', 'ACCEPT_INCREASE'],
      'disabled_actions': [],
    });
    mails[mailId] = {
      'mail_id': mailId,
      'subject': mail['subject'],
      'sender': mail['sender'],
      'recipients': ['buyer@costflow.example'],
      'received_at': mail['received_at'],
      'body_text': mail['body_text'],
      'attachments': attachments,
    };
    return id;
  }

  static Map<String, dynamic> _copy(Object value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}
