import "dart:convert";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/preview_workspace.dart";
import "send_settings_preview_data.dart";

part "send_settings_data_source.g.dart";

@Riverpod(keepAlive: true)
SendSettingsDataSource sendSettingsDataSource(Ref ref) {
  return PreviewSendSettingsDataSource(
    workspace: ref.watch(previewWorkspaceProvider),
  );
}

/// API-21 `GET /mail-send-settings` and API-22 `PUT /mail-send-settings`.
abstract interface class SendSettingsDataSource {
  Future<Map<String, dynamic>> fetchSettings({String? caseId});

  Future<Map<String, dynamic>> saveSettings(
    Map<String, Object?> body, {
    required String idempotencyKey,
  });
}

class SendSettingsApiException implements Exception {
  const SendSettingsApiException(this.statusCode, this.code, this.message);
  final int statusCode;
  final String code;
  final String message;
}

/// Merges mailbox and case values the way the proposed 08 contract does:
/// a purpose's case value wins, otherwise the mailbox value applies.
class PreviewSendSettingsDataSource implements SendSettingsDataSource {
  PreviewSendSettingsDataSource({
    this.latency = const Duration(milliseconds: 250),
    PreviewWorkspace? workspace,
  }) : _workspace = workspace ?? PreviewWorkspace();

  static const _purposes = ["RFQ", "CLARIFICATION", "COUNTER_OFFER"];
  static const _purposeLabels = {
    "RFQ": "견적 요청",
    "CLARIFICATION": "추가 확인",
    "COUNTER_OFFER": "역제안",
  };

  final Duration latency;
  final PreviewWorkspace _workspace;
  Map<String, dynamic> get _mailbox => _workspace.mailbox;
  Map<String, dynamic> get _cases => _workspace.cases;
  final Map<String, (String, Map<String, dynamic>)> _results = {};

  @override
  Future<Map<String, dynamic>> fetchSettings({String? caseId}) async {
    await Future<void>.delayed(latency);
    return _response(caseId);
  }

  @override
  Future<Map<String, dynamic>> saveSettings(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final hash = jsonEncode(body);
    final previous = _results[idempotencyKey];
    if (previous != null) {
      if (previous.$1 != hash) {
        throw const SendSettingsApiException(
          409,
          "IDEMPOTENCY_KEY_REUSED",
          "이미 다른 내용으로 접수된 요청입니다.",
        );
      }
      return previous.$2;
    }
    final caseId = body["case_id"] as String?;
    if (body["expected_settings_version"] != _version(caseId)) {
      throw const SendSettingsApiException(
        409,
        "SETTINGS_CHANGED",
        "다른 곳에서 설정이 바뀌었습니다. 최신 설정을 확인한 뒤 다시 저장해 주세요.",
      );
    }
    final approval = Map<String, Object?>.from(
      body["approval_required_by_purpose"] as Map,
    );
    final allowed = (body["allowed_supplier_ids"] as List).cast<String>();
    final effective = {
      for (final purpose in _purposes)
        purpose: _effective(caseId, purpose, approval),
    };
    if (effective.values.contains(false) && allowed.isEmpty) {
      throw const SendSettingsApiException(
        422,
        "SEND_SCOPE_REQUIRED",
        "자동 발송(승인 OFF)을 쓰려면 허용 업체를 한 곳 이상 선택해 주세요.",
      );
    }
    final applyExisting = body['apply_to'] == 'SPECIFIED_DRAFTS';
    final draftIds = (body['draft_ids'] as List).cast<String>().toSet();
    if (applyExisting && (caseId == null || draftIds.isEmpty)) {
      throw const SendSettingsApiException(
        422,
        "SEND_SCOPE_REQUIRED",
        "기존 초안에 적용하려면 적용할 초안을 선택해 주세요.",
      );
    }
    final targets = <Map<String, dynamic>>[];
    if (applyExisting) {
      for (final id in draftIds) {
        final draft =
            (_workspace.drafts[caseId] ?? const <Map<String, dynamic>>[])
                .where((entry) => entry['draft_id'] == id)
                .firstOrNull;
        if (draft == null || draft['status'] != 'DRAFT') {
          throw const SendSettingsApiException(
            409,
            'DRAFT_CHANGED',
            '초안 상태가 바뀌었습니다. 현재 적용 가능한 초안을 다시 확인해 주세요.',
          );
        }
        targets.add(draft);
      }
    }
    final style = body["style"] as Map;
    if (caseId == null) {
      _mailbox['allowed_supplier_ids'] = allowed;
      _mailbox['tone'] = style['tone'];
      _mailbox['signature'] = style['signature'];
      _mailbox["approval"] = approval;
      _mailbox["version"] = (_mailbox["version"] as int) + 1;
    } else {
      final current = _cases[caseId] as Map<String, dynamic>?;
      _cases[caseId] = {
        ...?current,
        "version": ((current?["version"] as int?) ?? 0) + 1,
        "approval": approval,
        'allowed_supplier_ids': allowed,
        'tone': style['tone'],
        'signature': style['signature'],
      };
    }
    for (final draft in targets) {
      _workspace.applyDraftPolicy(draft);
      if (draft['approval_required'] == false &&
          draft['settings_configured'] == true &&
          draft['auto_send_allowed'] == true) {
        draft['status'] = 'SENDING';
        _workspace.sendingSince[draft['draft_id'] as String] = DateTime.now();
      }
    }
    final response = _response(caseId);
    _results[idempotencyKey] = (hash, response);
    return response;
  }

  int _version(String? caseId) => _workspace.settingsVersion(caseId);

  bool? _effective(
    String? caseId,
    String purpose, [
    Map<String, Object?>? override,
  ]) {
    return _workspace.approvalFor(caseId, purpose, override);
  }

  Map<String, dynamic> _response(String? caseId) {
    final caseApproval =
        (_cases[caseId] as Map<String, dynamic>?)?["approval"] as Map?;
    final caseVersion = (_cases[caseId] as Map<String, dynamic>?)?["version"];
    final scope = _workspace.sendScope(caseId);
    final allowed = (scope['allowed_supplier_ids'] as List).cast<String>();
    final settings = <String, Object?>{};
    final missing = <String>[];
    for (final purpose in _purposes) {
      final own = caseId == null
          ? (_mailbox["approval"] as Map)[purpose] as bool?
          : caseApproval?[purpose] as bool?;
      final effective = _effective(caseId, purpose);
      final fromCase = caseId != null && own != null;
      settings[purpose] = {
        "approval_required": own,
        "effective_approval_required": effective,
        "source": effective == null ? null : (fromCase ? "CASE" : "MAILBOX"),
        "source_version": effective == null
            ? null
            : (fromCase ? caseVersion : _mailbox["version"]),
      };
      if (effective == null) missing.add("${_purposeLabels[purpose]} 승인 여부");
    }
    return _copy({
      "data": {
        "mailbox_ref": _mailbox["mailbox_ref"],
        "case_id": caseId,
        "configured": missing.isEmpty,
        "settings_version": _version(caseId),
        "missing_items": missing,
        "effective_settings": settings,
        "allowed_suppliers": [
          for (final supplier in sendSettingsPreviewSuppliers)
            {...supplier, "allowed": allowed.contains(supplier["supplier_id"])},
        ],
        "style": {"tone": scope['tone'], "signature": scope['signature']},
        "pending_drafts": caseId == null
            ? const []
            : [
                for (final draft
                    in _workspace.drafts[caseId] ??
                        const <Map<String, dynamic>>[])
                  {
                    for (final key in [
                      'draft_id',
                      'purpose',
                      'supplier_name',
                      'recipient',
                      'status',
                    ])
                      key: draft[key],
                  },
              ],
      },
      "meta": {"request_id": "req-preview-send-settings"},
    });
  }

  // A fresh JSON object, like a decoded HTTP response.
  static Map<String, dynamic> _copy(Object value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}
