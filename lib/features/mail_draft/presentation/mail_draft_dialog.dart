import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/widgets/async_content.dart";
import "../../../shared/workspace_colors.dart";
import "../../../shared/widgets/workspace_button_styles.dart";
import "../domain/mail_draft.dart";
import "mail_draft_view_model.dart";
import "widgets/mail_draft_body.dart";
import "widgets/mail_draft_footer.dart";
import "widgets/mail_draft_header.dart";
import "widgets/mail_draft_tabs.dart";
import "widgets/send_policy_banner.dart";

/// SCR-007 메일 초안·발송 모달을 엽니다.
///
/// Opening or closing never sends. With approval OFF the server sends on its
/// own, so this dialog only shows the scope and the result.
/// [dispatchStates] are the API-12 results right after a candidate selection.
Future<void> showMailDraftDialog(
  BuildContext context, {
  required String caseId,
  String? draftId,
  Map<String, DraftDispatchState> dispatchStates = const {},
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: MailDraftDialog(
        caseId: caseId,
        initialDraftId: draftId,
        dispatchStates: dispatchStates,
      ),
    ),
  );
}

class MailDraftDialog extends ConsumerStatefulWidget {
  const MailDraftDialog({
    super.key,
    required this.caseId,
    this.initialDraftId,
    this.dispatchStates = const {},
  });

  final String caseId;
  final String? initialDraftId;

  /// draft_id → API-12 dispatch_state.
  final Map<String, DraftDispatchState> dispatchStates;

  @override
  ConsumerState<MailDraftDialog> createState() => _MailDraftDialogState();
}

class _MailDraftDialogState extends ConsumerState<MailDraftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _recipient = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  final _editReason = TextEditingController();

  late String? _selectedId = widget.initialDraftId;
  bool _editing = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _recipient.dispose();
    _subject.dispose();
    _body.dispose();
    _editReason.dispose();
    super.dispose();
  }

  MailDraft? _selected(List<MailDraft> drafts) =>
      drafts.where((draft) => draft.id == _selectedId).firstOrNull ??
      drafts.firstOrNull;

  bool get _dirty =>
      _editing &&
      (_recipient.text != _original?.recipient ||
          _subject.text != _original?.subject ||
          _body.text != _original?.body);

  MailDraft? _original;

  void _startEdit(MailDraft draft) {
    _original = draft;
    _recipient.text = draft.recipient;
    _subject.text = draft.subject;
    _body.text = draft.body;
    _editReason.clear();
    setState(() {
      _editing = true;
      _error = null;
    });
  }

  void _cancelEdit() => setState(() {
    _editing = false;
    _error = null;
  });

  Future<void> _run(Future<MailDraft> Function() request) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await request();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _editing = false;
        _selectedId = result.id;
      });
    } on MailDraftFailure catch (failure) {
      if (!mounted) return;
      if (failure.draftChanged) {
        ref.read(mailDraftViewModelProvider(widget.caseId).notifier).refresh();
      }
      setState(() {
        _busy = false;
        _error = failure.unknownOutcome
            ? "결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다."
            : failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      // Unknown outcome: the repository keeps the key, so a retry only checks.
      setState(() {
        _busy = false;
        _error = "결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다.";
      });
    }
  }

  void _saveRevision(MailDraft draft) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final input = DraftRevisionInput(
      recipient: _recipient.text.trim(),
      subject: _subject.text.trim(),
      body: _body.text,
      editReason: _editReason.text.trim().isEmpty
          ? null
          : _editReason.text.trim(),
    );
    final viewModel = ref.read(
      mailDraftViewModelProvider(widget.caseId).notifier,
    );
    _run(() => viewModel.revise(draft, input));
  }

  void _approve(MailDraft draft) {
    final viewModel = ref.read(
      mailDraftViewModelProvider(widget.caseId).notifier,
    );
    _run(() => viewModel.approve(draft));
  }

  void _reconcile(MailDraft draft) {
    final viewModel = ref.read(
      mailDraftViewModelProvider(widget.caseId).notifier,
    );
    _run(() => viewModel.reconcile(draft));
  }

  Future<void> _close() async {
    if (_busy) return;
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("수정한 내용을 버릴까요?"),
        content: const Text("저장하지 않은 초안 수정은 사라집니다."),
        actions: [
          TextButton(
            style: WorkspaceButtonStyles.text,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("계속 수정"),
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
    final provider = mailDraftViewModelProvider(widget.caseId);
    final value = ref.watch(provider);
    // Keep showing the last drafts while a send-status poll reloads.
    final drafts = value.value ?? const <MailDraft>[];
    final draft = _selected(drafts);
    return PopScope(
      canPop: !_dirty && !_busy,
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
          constraints: const BoxConstraints(maxWidth: 860),
          child: Form(
            key: _formKey,
            // Rebuild so canPop follows unsaved edits.
            onChanged: () => setState(() {}),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MailDraftHeader(caseId: widget.caseId, onClose: _close),
                const Divider(height: 1, color: line),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: AsyncContent<List<MailDraft>>(
                      value: value.hasValue ? AsyncData(drafts) : value,
                      onRetry: ref.read(provider.notifier).refresh,
                      builder: (drafts) => drafts.isEmpty || draft == null
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text("이 업무에는 아직 메일 초안이 없습니다."),
                              ),
                            )
                          : AbsorbPointer(
                              absorbing: _busy,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Switching tabs while editing would lose edits.
                                  IgnorePointer(
                                    ignoring: _editing,
                                    child: MailDraftTabs(
                                      drafts: drafts,
                                      dispatchStates: widget.dispatchStates,
                                      selectedId: draft.id,
                                      onSelect: (id) => setState(() {
                                        _selectedId = id;
                                        _error = null;
                                      }),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  SendPolicyBanner(
                                    draft: draft,
                                    editing: _editing,
                                    dispatchState:
                                        widget.dispatchStates[draft.id],
                                  ),
                                  const SizedBox(height: 16),
                                  MailDraftBody(
                                    draft: draft,
                                    editing: _editing,
                                    recipient: _recipient,
                                    subject: _subject,
                                    body: _body,
                                    editReason: _editReason,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: line),
                MailDraftFooter(
                  draft: draft,
                  editing: _editing,
                  busy: _busy,
                  error: _error,
                  onEdit: () => _startEdit(draft!),
                  onCancelEdit: _cancelEdit,
                  onSaveRevision: () => _saveRevision(draft!),
                  onApprove: () => _approve(draft!),
                  onReconcile: () => _reconcile(draft!),
                  onClose: _close,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
