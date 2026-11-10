import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/widgets/async_content.dart";
import "../../../shared/widgets/workspace_button_styles.dart";
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
Future<void> showMailIntakeDialog(BuildContext context, {String? mailId}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .30),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: MailIntakeDialog(initialMailId: mailId),
    ),
  );
}

class MailIntakeDialog extends ConsumerStatefulWidget {
  const MailIntakeDialog({super.key, this.initialMailId});

  /// The mail picked in the sidebar; opens with it selected.
  final String? initialMailId;

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
  late String? _selectedMailId = widget.initialMailId;
  String? _selectedCaseId;
  bool _busy = false;
  String? _error;

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

  /// 회신으로 보이는 메일을 새 업무로 만들면 원래 업무와 Work ID가 갈라지고,
  /// 나중에 원래 업무에 다시 연결할 수 없습니다(E2E S5-11). 한 번 더 묻습니다.
  Future<bool> _confirmCreateFromReply() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("회신 메일을 새 업무로 만들까요?"),
        content: const Text(
          "이 메일은 보낸 견적 요청이나 추가 확인에 대한 회신일 수 있어요. "
          "새 업무로 접수하면 원래 업무와 따로 진행되고, 나중에 원래 업무에 연결할 수 없어요.\n\n"
          "공급사가 보낸 새 인상 안내라면 새 업무로 접수해 주세요.",
        ),
        actions: [
          TextButton(
            style: WorkspaceButtonStyles.text(context),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("취소"),
          ),
          FilledButton(
            style: WorkspaceButtonStyles.filled(context),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("새 업무로 접수"),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _resolve(IntakeMail mail, IntakeResolution resolution) async {
    if (_busy) return;
    if (resolution == IntakeResolution.createCase &&
        mail.looksLikeReply &&
        !await _confirmCreateFromReply()) {
      return;
    }
    if (!mounted || _busy) return;
    final target = resolution == IntakeResolution.linkCase
        ? _selectedCaseId
        : null;
    final reason = _reason.text.trim().isEmpty ? null : _reason.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(mailIntakeViewModelProvider.notifier)
          .resolve(mail, resolution, targetCaseId: target, reason: reason);
      if (!mounted) return;
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
      setState(() {
        _busy = false;
        _error = failure.unknownOutcome
            ? "처리 결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다."
            : failure.message;
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
      backgroundColor: context.palette.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.line),
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
            Divider(height: 1, color: context.palette.line),
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
                                              foregroundColor:
                                                  context.palette.ink,
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
            Divider(height: 1, color: context.palette.line),
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
