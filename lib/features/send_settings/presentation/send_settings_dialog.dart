import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/app_font_sizes.dart";
import "../../../shared/widgets/async_content.dart";
import "../../../shared/workspace_colors.dart";
import "../../../shared/widgets/workspace_button_styles.dart";
import "../../mail_draft/domain/mail_draft.dart";
import "../domain/send_settings.dart";
import "send_settings_view_model.dart";
import "widgets/allowed_supplier_list.dart";
import "widgets/apply_scope_section.dart";
import "widgets/mail_style_section.dart";
import "widgets/purpose_approval_row.dart";
import "widgets/send_settings_footer.dart";
import "widgets/send_settings_header.dart";
import "widgets/settings_missing_banner.dart";
import "widgets/settings_section_title.dart";

/// SCR-008 발송·메일 스타일 설정 모달을 엽니다. Returns true after a save.
///
/// Without [caseId] it edits the mailbox default; with it, that case's values.
Future<bool?> showSendSettingsDialog(BuildContext context, {String? caseId}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: SendSettingsDialog(caseId: caseId),
    ),
  );
}

class SendSettingsDialog extends ConsumerStatefulWidget {
  const SendSettingsDialog({super.key, this.caseId, this.embedded = false});
  final String? caseId;

  /// 설정 페이지 탭 안에 바로 표시: 팝업 틀·닫기 없이, 저장해도 화면에 남습니다.
  final bool embedded;

  @override
  ConsumerState<SendSettingsDialog> createState() => _SendSettingsDialogState();
}

class _SendSettingsDialogState extends ConsumerState<SendSettingsDialog> {
  final _signature = TextEditingController();

  // Local edits, seeded from the loaded version.
  String? _mailboxRef;
  int? _loadedVersion;
  Map<DraftPurpose, bool?> _approval = {};
  Set<String> _allowed = {};
  MailTone _tone = MailTone.formal;
  ApplyTo _applyTo = ApplyTo.futureDrafts;
  Set<String> _draftIds = {};
  bool _dirty = false;

  bool _saving = false;
  String? _error;

  String get _scope => sendSettingsScope(widget.caseId);

  // False only during initState, where a rebuild is already coming.
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    // Seed outside build: writing the signature controller during build
    // would rebuild its TextField mid-frame.
    ref.listenManual<AsyncValue<SendSettings>>(
      sendSettingsViewModelProvider(_scope),
      (_, next) {
        final settings = next.asData?.value;
        // Seed only from settled data, never from the stale value shown
        // while a refresh after SETTINGS_CHANGED is still loading.
        if (settings == null || next.isLoading || _loadedVersion != null) {
          return;
        }
        if (_listening) {
          setState(() => _seed(settings));
        } else {
          _seed(settings);
        }
      },
      fireImmediately: true,
    );
    _listening = true;
  }

  @override
  void dispose() {
    _signature.dispose();
    super.dispose();
  }

  void _seed(SendSettings settings) {
    _mailboxRef = settings.mailboxRef;
    _loadedVersion = settings.settingsVersion;
    _approval = {
      for (final approval in settings.approvals)
        approval.purpose: approval.ownValue,
    };
    _allowed = {
      for (final supplier in settings.suppliers)
        if (supplier.allowed) supplier.id,
    };
    _tone = settings.tone;
    _signature.text = settings.signature;
    _applyTo = ApplyTo.futureDrafts;
    _draftIds = {};
    _dirty = false;
  }

  void _edit(VoidCallback change) => setState(() {
    change();
    _dirty = true;
  });

  /// Approval OFF somewhere in the values being saved.
  bool _automatic(SendSettings settings) => settings.approvals.any(
    (approval) =>
        _approval[approval.purpose] == false ||
        (_approval[approval.purpose] == null &&
            settings.isCaseScope &&
            approval.effectiveValue == false),
  );

  Future<void> _save() async {
    final version = _loadedVersion;
    final mailboxRef = _mailboxRef;
    final loaded = ref
        .read(sendSettingsViewModelProvider(_scope))
        .asData
        ?.value;
    if (_saving || version == null || mailboxRef == null || loaded == null) {
      return;
    }
    // Decided before the request, from the values actually sent.
    final missingSuppliers = _automatic(loaded) && _allowed.isEmpty;
    final update = SendSettingsUpdate(
      mailboxRef: mailboxRef,
      expectedSettingsVersion: version,
      approvalByPurpose: Map.unmodifiable(_approval),
      allowedSupplierIds: List.unmodifiable(_allowed),
      tone: _tone,
      signature: _signature.text.trim(),
      applyTo: _applyTo,
      draftIds: _applyTo == ApplyTo.specifiedDrafts
          ? List.unmodifiable(_draftIds)
          : const [],
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(sendSettingsViewModelProvider(_scope).notifier)
          .save(update);
      if (!mounted) return;
      if (widget.embedded) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text("발송 설정을 저장했어요.")));
        // Show the saved version right away.
        setState(() {
          _saving = false;
          _seed(saved);
        });
        return;
      }
      Navigator.of(context).pop(true);
    } on SendSettingsFailure catch (failure) {
      if (!mounted) return;
      if (failure.settingsChanged) {
        // Show the newer version; the listener re-seeds once it settles.
        _loadedVersion = null;
        ref.read(sendSettingsViewModelProvider(_scope).notifier).refresh();
      }
      setState(() {
        _saving = false;
        _error = switch (failure) {
          SendSettingsFailure(unknownOutcome: true) =>
            "저장 결과를 확인하지 못했습니다. 다시 저장하면 같은 요청으로 확인합니다.",
          SendSettingsFailure(settingsChanged: true) =>
            "다른 곳에서 설정이 바뀌어 최신 설정을 불러왔습니다. 확인한 뒤 다시 저장해 주세요.",
          SendSettingsFailure(scopeRequired: true) when missingSuppliers =>
            widget.caseId == null
                ? "승인 OFF(자동 발송)는 허용 업체가 있어야 저장됩니다. "
                      "메일함 기본값은 승인 ON으로 두고, 업무별 설정에서 허용 업체를 고른 뒤 OFF로 바꿔 주세요."
                : "승인 OFF(자동 발송)로 저장하려면 자동 발송 허용 업체를 한 곳 이상 선택해 주세요.",
          _ => failure.message,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = "저장 결과를 확인하지 못했습니다. 다시 저장하면 같은 요청으로 확인합니다.";
      });
    }
  }

  /// Embedded: drop unsaved edits and show the saved values again.
  void _discard() {
    final value = ref.read(sendSettingsViewModelProvider(_scope));
    final settings = value.asData?.value;
    setState(() {
      _error = null;
      if (settings != null && !value.isLoading) {
        _seed(settings);
      } else {
        // The listener seeds once the reload settles.
        _loadedVersion = null;
      }
    });
  }

  Future<void> _close() async {
    if (_saving) return;
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("변경한 설정을 버릴까요?"),
        content: const Text("저장하지 않은 설정은 적용되지 않습니다."),
        actions: [
          TextButton(
            style: WorkspaceButtonStyles.text,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("계속 설정"),
          ),
          FilledButton(
            style: WorkspaceButtonStyles.filled,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("변경사항 버리기"),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = sendSettingsViewModelProvider(_scope);
    final value = ref.watch(provider);
    final settings = value.asData?.value;
    final failure = value.error;
    final content = failure is SendSettingsFailure && !value.isLoading
        ? _loadError(failure, ref.read(provider.notifier).refresh)
        : AsyncContent<SendSettings>(
            value: value,
            onRetry: ref.read(provider.notifier).refresh,
            builder: (settings) =>
                AbsorbPointer(absorbing: _saving, child: _body(settings)),
          );
    final footer = SendSettingsFooter(
      error: _error,
      saving: _saving,
      onCancel: widget.embedded ? _discard : _close,
      onSave: settings == null || _loadedVersion == null ? null : _save,
    );
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Same inset as the footer.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: content,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: line),
          footer,
        ],
      );
    }
    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Dialog(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: line),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SendSettingsHeader(caseId: widget.caseId, onClose: _close),
              const Divider(height: 1, color: line),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: content,
                ),
              ),
              const Divider(height: 1, color: line),
              footer,
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the server's reason, e.g. no connected mailbox.
  Widget _loadError(SendSettingsFailure failure, VoidCallback onRetry) =>
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(failure.message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text("다시 시도")),
          ],
        ),
      );

  Widget _body(SendSettings settings) {
    final automatic = _automatic(settings);
    final suppliers = AllowedSupplierList(
      suppliers: settings.suppliers,
      allowedIds: _allowed,
      onToggle: (id, allowed) =>
          _edit(() => allowed ? _allowed.add(id) : _allowed.remove(id)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!settings.configured) ...[
          SettingsMissingBanner(missingItems: settings.missingItems),
          const SizedBox(height: 20),
        ],
        SettingsSectionTitle(
          "목적별 승인",
          settings.isCaseScope
              ? "이 업무에 적용할 값을 고르거나 메일함 기본값을 따릅니다."
              : "승인 ON은 담당자가 승인한 초안만, OFF는 업무마다 선택한 업체에 자동 발송합니다.",
        ),
        const SizedBox(height: 14),
        for (final approval in settings.approvals)
          PurposeApprovalRow(
            approval: approval,
            value: _approval[approval.purpose],
            caseScope: settings.isCaseScope,
            onChanged: (next) =>
                _edit(() => _approval[approval.purpose] = next),
          ),
        const SizedBox(height: 12),
        // Which suppliers get a request depends on the item, so the mailbox
        // default does not pick them; each case chooses its own recipients.
        if (!settings.isCaseScope)
          const SizedBox.shrink()
        else if (automatic) ...[
          SettingsSectionTitle(
            '자동 발송 허용 업체 · ${_allowed.length}곳',
            '선택한 업체의 등록된 수신자에게만 자동 발송합니다.',
          ),
          const SizedBox(height: 8),
          suppliers,
        ] else
          ExpansionTile(
            iconColor: ink,
            collapsedIconColor: muted,
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: EdgeInsets.zero,
            title: Text(
              '자동 발송 허용 업체 · ${_allowed.length}곳',
              style: const TextStyle(
                fontSize: AppFontSizes.bodyLarge,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            children: [suppliers],
          ),
        ExpansionTile(
          iconColor: ink,
          collapsedIconColor: muted,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: EdgeInsets.zero,
          title: const Text(
            '문안·서명',
            style: TextStyle(
              fontSize: AppFontSizes.bodyLarge,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          subtitle: Text(_tone.label),
          childrenPadding: const EdgeInsets.only(top: 12, bottom: 16),
          children: [
            MailStyleSection(
              tone: _tone,
              signature: _signature,
              onToneChanged: (tone) => _edit(() => _tone = tone),
              onSignatureChanged: (_) => _edit(() {}),
            ),
          ],
        ),
        ExpansionTile(
          iconColor: ink,
          collapsedIconColor: muted,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: EdgeInsets.zero,
          title: const Text(
            '적용 대상',
            style: TextStyle(
              fontSize: AppFontSizes.bodyLarge,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          subtitle: Text(
            _applyTo == ApplyTo.futureDrafts
                ? '앞으로 생성할 초안'
                : '선택한 기존 초안 ${_draftIds.length}건에도 적용',
          ),
          children: [
            ApplyScopeSection(
              applyTo: _applyTo,
              drafts: settings.pendingDrafts,
              selectedDraftIds: _draftIds,
              onApplyToChanged: (applyTo) => _edit(() => _applyTo = applyTo),
              onToggleDraft: (id, selected) => _edit(
                () => selected ? _draftIds.add(id) : _draftIds.remove(id),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
