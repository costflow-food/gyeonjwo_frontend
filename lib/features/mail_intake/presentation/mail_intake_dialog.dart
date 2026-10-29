import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/idempotency_key.dart";
import "../../../shared/widgets/async_content.dart";
import "../../../shared/workspace_colors.dart";
import "../domain/intake_mail.dart";
import "mail_intake_view_model.dart";
import "widgets/intake_mail_detail.dart";
import "widgets/intake_mail_row.dart";
import "widgets/mail_intake_actions.dart";
import "widgets/mail_intake_header.dart";

/// SCR-009 접수·연결 확인 모달을 엽니다.
///
/// Advertising and other non-business mail never reaches the queue; only
/// mails the classifier could not settle appear here.
Future<void> showMailIntakeDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: const MailIntakeDialog(),
    ),
  );
}

class MailIntakeDialog extends ConsumerStatefulWidget {
  const MailIntakeDialog({super.key});

  @override
  ConsumerState<MailIntakeDialog> createState() => _MailIntakeDialogState();
}

class _MailIntakeDialogState extends ConsumerState<MailIntakeDialog> {
  final _listKey = GlobalKey();
  final _detailKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || key.currentContext == null) return;
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  final _reason = TextEditingController();
  String? _selectedMailId;
  String? _selectedCaseId;
  bool _busy = false;
  String? _error;
  (String, String)? _pendingKey;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _selectMail(String mailId) => setState(() {
    _selectedMailId = mailId;
    _selectedCaseId = null;
    _error = null;
    _reason.clear();
  });

  Future<void> _resolve(IntakeMail mail, IntakeResolution resolution) async {
    if (_busy) return;
    final target = resolution == IntakeResolution.linkCase
        ? _selectedCaseId
        : null;
    final reason = _reason.text.trim().isEmpty ? null : _reason.text.trim();
    final body = jsonEncode([mail.mailId, resolution.code, target, reason]);
    if (_pendingKey?.$2 != body) _pendingKey = (newIdempotencyKey(), body);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(mailIntakeViewModelProvider.notifier)
          .resolve(
            mail,
            resolution,
            targetCaseId: target,
            reason: reason,
            idempotencyKey: _pendingKey!.$1,
          );
      if (!mounted) return;
      _pendingKey = null;
      final message = switch (resolution) {
        IntakeResolution.nonBusiness => "비업무로 확인했습니다.",
        IntakeResolution.createCase => "새 업무로 접수했습니다. 업무 큐에서 대기 상태로 확인할 수 있어요.",
        IntakeResolution.linkCase => "선택한 업무에 연결했습니다.",
      };
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));
      setState(() {
        _busy = false;
        _selectedMailId = null;
        _selectedCaseId = null;
        _reason.clear();
      });
    } on IntakeFailure catch (failure) {
      if (!mounted) return;
      _pendingKey = null;
      setState(() {
        _busy = false;
        _error = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "처리 결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(mailIntakeViewModelProvider);
    final viewModel = ref.read(mailIntakeViewModelProvider.notifier);
    final page = value.asData?.value;
    final mails = page?.items ?? const <IntakeMail>[];
    final mail =
        mails.where((item) => item.mailId == _selectedMailId).firstOrNull ??
        mails.firstOrNull;
    return Dialog(
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
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MailIntakeHeader(
              totalPending: page?.totalPending,
              onRefresh: viewModel.refresh,
              onClose: () => Navigator.of(context).pop(),
            ),
            const Divider(height: 1, color: line),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AsyncContent<IntakePage>(
                  value: value,
                  onRetry: viewModel.refresh,
                  builder: (page) => page.items.isEmpty || mail == null
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text("확인할 메일이 없습니다.")),
                        )
                      : AbsorbPointer(
                          absorbing: _busy,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final list = Column(
                                key: _listKey,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final item in page.items)
                                    IntakeMailRow(
                                      mail: item,
                                      selected: item.mailId == mail.mailId,
                                      onTap: () {
                                        _selectMail(item.mailId);
                                        if (constraints.maxWidth < 680) {
                                          _scrollTo(_detailKey);
                                        }
                                      },
                                    ),
                                ],
                              );
                              final detail = IntakeMailDetail(
                                key: ValueKey(mail.mailId),
                                mail: mail,
                                selectedCaseId: _selectedCaseId,
                                onSelectCase: (caseId) =>
                                    setState(() => _selectedCaseId = caseId),
                                reason: _reason,
                              );
                              if (constraints.maxWidth < 680) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    list,
                                    const SizedBox(height: 20),
                                    Column(
                                      key: _detailKey,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: () =>
                                                _scrollTo(_listKey),
                                            icon: const Icon(
                                              Icons.arrow_back,
                                              size: 16,
                                            ),
                                            label: const Text('목록으로'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: ink,
                                            ),
                                          ),
                                        ),
                                        detail,
                                      ],
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 2, child: list),
                                  const SizedBox(width: 20),
                                  Expanded(flex: 3, child: detail),
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ),
            ),
            const Divider(height: 1, color: line),
            MailIntakeActions(
              enabled: mail != null,
              canLink:
                  mail != null &&
                  mail.candidates.any((c) => c.caseId == _selectedCaseId),
              busy: _busy,
              error: _error,
              onResolve: (resolution) => _resolve(mail!, resolution),
            ),
          ],
        ),
      ),
    );
  }
}
