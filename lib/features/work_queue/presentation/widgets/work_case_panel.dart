import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/file_save/file_save.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/widgets/mobile_scaffold.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/app_icons.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/task_group.dart";
import "../../../review_progress/presentation/review_progress_view.dart";
import "../../../voice_import/data/recording_supplier_source.dart";
import "../../../voice_import/presentation/voice_import_flow.dart";
import "../../../voice_import/presentation/widgets/call_recording_section.dart";
import "../../data/work_queue_repository_impl.dart";
import "../../domain/work_case.dart";
import "../work_queue_view_model.dart";
import "attachment_viewer.dart";
import "candidate_selection.dart";
import "case_progress.dart";
import "case_step_status.dart";
import "case_todo.dart";
import "task_row.dart";
import "status_badge.dart";
import "../../../../app/app_paths.dart";

class WorkCasePanel extends ConsumerStatefulWidget {
  const WorkCasePanel({super.key, required this.workCase, this.onNext});

  final WorkCase workCase;

  /// 목록의 다음 업무를 엽니다('나중에'·'검토 보류'). null이면 두지 않습니다.
  final VoidCallback? onNext;

  @override
  ConsumerState<WorkCasePanel> createState() => _WorkCasePanelState();
}

class _WorkCasePanelState extends ConsumerState<WorkCasePanel> {
  bool _busy = false;
  String? _error;

  /// 받은 메일 카드를 펼쳤는지. null이면 접수 대기 업무만 펼칩니다.
  bool? _mailOpen;

  /// 아래로 펼친 첨부 PDF. 처음에는 모두 접혀 있습니다.
  String? _expandedAttachmentId;

  final _mailCard = GlobalKey(debugLabel: "받은 메일");

  void _toggleAttachment(MailAttachment attachment) => setState(
    () => _expandedAttachmentId = _expandedAttachmentId == attachment.id
        ? null
        : attachment.id,
  );

  /// '원문에서 확인': 받은 메일 카드를 펼치고 그 자리로 갑니다.
  void _showMail() {
    setState(() => _mailOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _mailCard.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  /// Attachments being downloaded; a second tap on one is ignored.
  final _downloading = <String>{};

  /// 미리 볼 수 없는 첨부(Excel·이미지 등)는 API-26 원본을 내려받습니다.
  Future<void> _download(String mailId, MailAttachment attachment) async {
    if (!mounted || !_downloading.add(attachment.id)) return;
    setState(() {});
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final bytes = await ref
          .read(workQueueRepositoryProvider)
          .getAttachmentContent(mailId, attachment.id);
      await saveFile(
        bytes,
        filename: attachment.filename,
        mimeType: attachment.mimeType,
      );
    } catch (error) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            error is WorkQueueFailure
                ? error.message
                : "${attachment.filename}을(를) 내려받지 못했습니다.",
          ),
        ),
      );
    } finally {
      _downloading.remove(attachment.id);
      if (mounted) setState(() {});
    }
  }

  WorkQueueViewModel get _viewModel =>
      ref.read(workQueueViewModelProvider.notifier);

  Future<void> _acceptIncrease() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "인상을 수용하시겠습니까?",
          style: TextStyle(
            fontSize: AppFontSizes.dialogTitleSmall,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          "수용하면 이 업무와 연결된 메일이 Thoner에서 삭제되고 되돌릴 수 없습니다.\n"
          "견적 수락 메일이나 발주는 보내지 않습니다.",
          style: TextStyle(fontSize: AppFontSizes.body, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: WorkspaceButtonStyles.text(context),
            child: const Text("취소"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: WorkspaceButtonStyles.filled(context),
            child: const Text("수용하기"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // The case is deleted, so leave its address.
    final router = GoRouter.of(context);
    if (await _run(
      () => _viewModel.acceptIncrease(widget.workCase),
      done: "수용했습니다. 업무 큐에서 정리했습니다.",
    )) {
      router.go(AppPaths.tasks);
    }
  }

  Future<void> _start() async {
    // The panel rebuilds as the step changes; keep a context that stays.
    final navigator = Navigator.of(context, rootNavigator: true).context;
    if (await _run(() => _viewModel.start(widget.workCase)) &&
        navigator.mounted) {
      await showReviewProgressDialog(
        navigator,
        caseId: widget.workCase.id,
        title: widget.workCase.title,
      );
    }
  }

  /// true when the request was accepted.
  Future<bool> _run(Future<void> Function() request, {String? done}) async {
    if (_busy) return false;
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await request();
      if (done != null) messenger?.showSnackBar(SnackBar(content: Text(done)));
      if (mounted) setState(() => _busy = false);
      return true;
    } on WorkQueueFailure catch (failure) {
      if (!mounted) return false;
      // A retryable failure may still have gone through; read it again.
      if (failure.caseChanged || failure.retryable) _viewModel.refresh();
      setState(() {
        _busy = false;
        _error = failure.unknownOutcome
            ? "결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다."
            : failure.message;
      });
      return false;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _busy = false;
        _error = "결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다.";
      });
      return false;
    }
  }

  void _openAttachmentPage(String mailId, MailAttachment attachment) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AttachmentPage(
            mailId: mailId,
            attachment: attachment,
            onDownload: () => _download(mailId, attachment),
          ),
        ),
      );

  bool get _atCandidates {
    final workCase = widget.workCase;
    // Blocked candidates are still shown, read-only, with the reason.
    return workCase.can(WorkCaseAction.selectCandidates) ||
        (workCase.atCandidates &&
            workCase.disabledMessage(WorkCaseAction.selectCandidates) != null);
  }

  /// Phone: a screen of its own with the decision pinned to the bottom.
  Widget _page(BuildContext context, AsyncValue<OriginalMail> mail) {
    final workCase = widget.workCase;
    final atCandidates = _atCandidates;
    final notStarted = !atCandidates && workCase.notStarted;
    final mailContent = mail.when(
      skipLoadingOnRefresh: false,
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _MailError(
        message: error is WorkQueueFailure
            ? error.message
            : "메일 원문을 불러오지 못했습니다.",
        onRetry: () =>
            ref.invalidate(originalMailProvider(workCase.initialMailId)),
      ),
      data: (mail) => _MailContent(
        mail: mail,
        compact: true,
        openAttachmentId: null,
        downloadingIds: _downloading,
        onOpen: (attachment) => _openAttachmentPage(mail.id, attachment),
        onDownload: (attachment) => _download(mail.id, attachment),
      ),
    );
    final recordings = recordingSupplierQueryOf(workCase);
    // The queue's reply summary answers it. A case read on its own has none,
    // so there the section waits for the suppliers themselves.
    final showRecordings =
        recordings != null &&
        (workCase.replySummary != null ||
            (ref.watch(recordingSuppliersProvider(recordings)).value ??
                    const [])
                .isNotEmpty);
    final Widget? bar;
    if (notStarted) {
      bar = _DecisionBar(
        workCase: workCase,
        busy: _busy,
        onAccept: _acceptIncrease,
        onStart: _start,
      );
    } else if (atCandidates) {
      bar = FilledButton.icon(
        style: MobileButtons.filled(context),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _CandidatesPage(initial: workCase),
          ),
        ),
        icon: const Icon(Icons.checklist, size: 18),
        label: const Text("견적 요청 대상 고르기"),
      );
    } else if (workCase.hasReviewCard) {
      bar = FilledButton.icon(
        style: MobileButtons.filled(context),
        onPressed: () => context.go(AppPaths.review(workCase.id)),
        icon: const Icon(Icons.fact_check_outlined, size: 18),
        label: const Text("검토 카드 보기"),
      );
    } else {
      bar = null;
    }
    return MobilePageScaffold(
      onBack: () {
        ref.read(workQueueViewModelProvider.notifier).select(null);
        context.go(AppPaths.tasks);
      },
      titleWidget: Row(
        children: [
          StatusBadge(workCase.status, rawCode: workCase.statusCode),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              workCase.itemName == null ? "품목 미확인" : "${workCase.itemName} 품목",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppFontSizes.secondary,
                color: context.palette.muted,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        // Without a bottom bar the list runs under the system navigation.
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          24 + (bar == null ? MediaQuery.paddingOf(context).bottom : 0),
        ),
        children: [
          CaseProgressSteps(workCase: workCase),
          const SizedBox(height: 20),
          mailContent,
          // A call is a supplier's reply, so only once requests went out.
          if (recordings != null && showRecordings) ...[
            const SizedBox(height: 20),
            CallRecordingSection(
              suppliers: recordings,
              onAdd: () => addCallRecording(
                context,
                ref,
                // The mail subject names the case best; the list title can be
                // just the sender's address.
                caseTitle:
                    mail.value?.subject ??
                    (workCase.itemName == null
                        ? workCase.title
                        : "${workCase.title} · ${workCase.itemName} 품목"),
                suppliers: recordings,
              ),
            ),
          ],
          if (notStarted || atCandidates) ...[
            const SizedBox(height: 20),
            _Hint(
              atCandidates
                  ? "에이전트가 이 품목을 취급하는 업체를 찾았습니다. 견적을 요청할 업체를 골라 주세요."
                  : "원문을 확인한 뒤 어떻게 처리할지 골라 주세요.",
            ),
          ] else ...[
            const SizedBox(height: 20),
            CaseStepStatus(workCase: workCase),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: AppFontSizes.body,
                color: danger,
              ),
            ),
          ],
        ],
      ),
      bottomBar: bar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final workCase = widget.workCase;
    final mail = ref.watch(originalMailProvider(workCase.initialMailId));
    if (isCompactLayout(context)) return _page(context, mail);
    final loadedMail = mail.asData?.value;
    // 멈춘 업무·오류는 API-03 사유로 멈춘 단계를 더 정확히 압니다.
    final progress = workCase.stopped || workCase.processingStep == "FAILED"
        ? ref.watch(caseProgressProvider(workCase.id)).asData?.value
        : null;
    final stopCode =
        progress?.hold?.code ?? workCase.hold?.code ?? progress?.errorCode;
    final first = workCase.notStarted;
    final mailOpen = _mailOpen ?? first;
    // 머리 · 진행 상황(단계 바 + 지금 할 일) · 받은 메일 · 근거 자료
    // (Tasks 시안, SSOT 7.5). 첨부 PDF는 옆에 두지 않고 카드 안 아래로
    // 펼칩니다(7.18).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailHeader(workCase: workCase, subject: loadedMail?.subject),
        const SizedBox(height: 16),
        CaseSectionCard(
          title: "진행 상황",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              CaseProgressSteps(workCase: workCase, stopCode: stopCode),
              const SizedBox(height: 16),
              CaseTodo(
                workCase: workCase,
                busy: _busy,
                error: _error,
                onAccept: _acceptIncrease,
                onStart: _start,
                onShowMail: _showMail,
                onNext: widget.onNext,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CaseSectionCard(
          key: _mailCard,
          title: first ? "받은 메일" : "받은 메일 · 근거 자료",
          trailing: first ? "읽고 검토를 시작하세요" : "처음 받은 요청 내용이에요",
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: mail.when(
              skipLoadingOnRefresh: false,
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _MailError(
                message: error is WorkQueueFailure
                    ? error.message
                    : "메일 원문을 불러오지 못했습니다.",
                onRetry: () => ref.invalidate(
                  originalMailProvider(workCase.initialMailId),
                ),
              ),
              data: (mail) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MailCard(
                    workCase: workCase,
                    mail: mail,
                    open: mailOpen,
                    onToggle: () => setState(() => _mailOpen = !mailOpen),
                  ),
                  if (mail.attachments.isNotEmpty)
                    _Attachments(
                      mail: mail,
                      expandedId: _expandedAttachmentId,
                      downloadingIds: _downloading,
                      onToggle: _toggleAttachment,
                      onDownload: (attachment) =>
                          _download(mail.id, attachment),
                      onEnlarge: (attachment) =>
                          _openAttachmentPage(mail.id, attachment),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MailContent extends StatelessWidget {
  const _MailContent({
    required this.mail,
    required this.openAttachmentId,
    required this.downloadingIds,
    required this.onOpen,
    required this.onDownload,
    this.compact = false,
  });

  /// Phone: smaller title, folded body, attachments in one sliding row.
  final bool compact;

  final OriginalMail mail;
  final String? openAttachmentId;
  final Set<String> downloadingIds;
  final ValueChanged<MailAttachment> onOpen;

  final ValueChanged<MailAttachment> onDownload;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      for (final attachment in mail.attachments)
        _AttachmentTile(
          attachment: attachment,
          selected: attachment.id == openAttachmentId,
          busy: downloadingIds.contains(attachment.id),
          maxWidth: compact ? 220 : 280,
          onTap: attachment.isPdf
              ? () => onOpen(attachment)
              : () => onDownload(attachment),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectableText(
          mail.subject,
          style: TextStyle(
            fontSize: compact
                ? AppFontSizes.cardTitle
                : AppFontSizes.dialogTitle,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        _MetaRow(label: "보낸 사람", value: mail.sender),
        _MetaRow(label: "받는 사람", value: mail.recipients.join(", ")),
        _MetaRow(label: "받은 시각", value: formatSeoulDateTime(mail.receivedAt)),
        const SizedBox(height: 16),
        Divider(height: 1, color: context.palette.line),
        const SizedBox(height: 16),
        if (compact && mail.bodyText.isNotEmpty)
          _FoldedBody(text: mail.bodyText)
        else
          SelectableText(
            mail.bodyText.isEmpty ? "(본문 없음)" : mail.bodyText,
            style: TextStyle(
              fontSize: AppFontSizes.bodyLarge,
              height: 1.8,
              color: mail.bodyText.isEmpty
                  ? context.palette.muted
                  : context.palette.ink,
            ),
          ),
        const SizedBox(height: 20),
        Text(
          "첨부파일 ${mail.attachments.length}",
          style: const TextStyle(
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (mail.attachments.isEmpty)
          Text(
            "첨부파일이 없습니다.",
            style: TextStyle(
              fontSize: AppFontSizes.secondary,
              color: context.palette.muted,
            ),
          )
        else if (compact)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tile in tiles) ...[tile, const SizedBox(width: 8)],
              ],
            ),
          )
        else
          Wrap(spacing: 8, runSpacing: 8, children: tiles),
      ],
    );
  }
}

/// Phone: a long body opens on demand.
class _FoldedBody extends StatefulWidget {
  const _FoldedBody({required this.text});

  final String text;

  @override
  State<_FoldedBody> createState() => _FoldedBodyState();
}

class _FoldedBodyState extends State<_FoldedBody> {
  static const _lines = 8;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: AppFontSizes.body,
      height: 1.8,
      color: context.palette.ink,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _lines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final long = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_open || !long)
              SelectableText(widget.text, style: style)
            else
              Text(
                widget.text,
                maxLines: _lines,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            if (long)
              TextButton(
                onPressed: () => setState(() => _open = !_open),
                style: WorkspaceButtonStyles.text(context).copyWith(
                  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                ),
                child: Text(_open ? "본문 접기" : "본문 전체 보기"),
              ),
          ],
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: context.palette.blush,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: AppFontSizes.secondary, height: 1.6),
    ),
  );
}

/// Phone: 수용하기 / 검토 시작 pinned to the bottom.
class _DecisionBar extends StatelessWidget {
  const _DecisionBar({
    required this.workCase,
    required this.busy,
    required this.onAccept,
    required this.onStart,
  });

  final WorkCase workCase;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final canAccept = workCase.can(WorkCaseAction.acceptIncrease);
    final canStart = workCase.can(WorkCaseAction.start);
    final caption = canStart
        ? "검토 시작: 등록된 거래처 자료로 에이전트가 검토를 시작합니다."
        : workCase.disabledMessage(WorkCaseAction.start);
    final acceptBlocked = canAccept
        ? null
        : workCase.disabledMessage(WorkCaseAction.acceptIncrease) ??
              "지금은 수용할 수 없습니다.";
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (busy) ...[
          LinearProgressIndicator(minHeight: 2, color: context.palette.accent),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: canAccept && !busy ? onAccept : null,
                style: MobileButtons.outlined(context),
                child: const Text("수용하기"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: canStart && !busy ? onStart : null,
                style: MobileButtons.filled(context),
                icon: const Icon(Icons.travel_explore, size: 18),
                label: const Text("검토 시작"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final line in [?acceptBlocked, ?caption])
          Text(
            line,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSizes.caption,
              color: context.palette.muted,
              height: 1.5,
            ),
          ),
      ],
    );
  }
}

/// Phone: the candidate list as its own screen, following the live case.
class _CandidatesPage extends ConsumerWidget {
  const _CandidatesPage({required this.initial});

  final WorkCase initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listed = ref
        .watch(workQueueViewModelProvider)
        .value
        ?.items
        .where((item) => item.id == initial.id)
        .firstOrNull;
    final workCase =
        listed ?? ref.watch(caseDetailProvider(initial.id)).value ?? initial;
    return CandidateSelection(workCase: workCase, page: true);
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          // At least the usual column; wider when a large system font needs
          // it, so the label stays whole on one line.
          constraints: const BoxConstraints(minWidth: 64),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              label,
              softWrap: false,
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: context.palette.muted,
              ),
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontSize: AppFontSizes.body),
          ),
        ),
      ],
    ),
  );
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.selected,
    required this.onTap,
    this.busy = false,
    this.maxWidth = 280,
  });

  /// Being downloaded.
  final bool busy;

  final double maxWidth;

  final MailAttachment attachment;
  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final extension = attachment.filename.contains(".")
        ? attachment.filename.split(".").last.toUpperCase()
        : "파일";
    final tile = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? context.palette.accentText : context.palette.line,
        ),
        borderRadius: BorderRadius.circular(LdsRadius.table),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            SizedBox.square(
              dimension: 20,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.palette.accent,
                ),
              ),
            )
          else
            Icon(
              attachment.isPdf
                  ? Icons.picture_as_pdf_outlined
                  : Icons.download_outlined,
              size: 20,
              color: selected
                  ? context.palette.accentText
                  : context.palette.muted,
            ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$extension · ${_size(attachment.sizeBytes)}",
                  style: TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: context.palette.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final action = attachment.isPdf ? "열기" : "내려받기";
    return Tooltip(
      message: attachment.isPdf ? "PDF 미리 보기" : "미리 볼 수 없는 형식이라 내려받습니다.",
      child: Semantics(
        button: true,
        selected: selected,
        label: "${attachment.filename} $action",
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(onTap: onTap, child: tile),
        ),
      ),
    );
  }

  static String _size(int bytes) {
    if (bytes < 1024) return "${bytes}B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).round()}KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB";
  }
}

class _MailError extends StatelessWidget {
  const _MailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Text(message, style: const TextStyle(fontSize: AppFontSizes.body)),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          style: WorkspaceButtonStyles.outlined(context),
          child: const Text("다시 시도"),
        ),
      ],
    ),
  );
}

/// Tasks 상세 머리 (Tasks 시안): 메일 제목(21/600) 아래
/// `[상태 라벨]  [가게 아이콘] 거래처명  접수 yyyy.MM.dd HH:mm`(13 `#6B7583`).
/// 품목 줄과 오른쪽 버튼은 두지 않습니다(메일 초안은 '지금 할 일' 상자,
/// 원문은 '받은 메일' 카드).
class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.workCase, required this.subject});

  final WorkCase workCase;

  /// 메일 제목. 원문을 불러오기 전에는 null.
  final String? subject;

  @override
  Widget build(BuildContext context) {
    final label = taskLabelOf(workCase);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            subject ?? "메일을 불러오는 중입니다",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: subject == null ? LdsColors.muted : LdsColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LdsTag(label.text, tone: taskLabelTone(label)),
              // 거래처: 앞에 가게 아이콘(사이드바 Suppliers와 같은 선 아이콘).
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIconView(
                    AppIcon.suppliers,
                    size: 16,
                    color: LdsColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Flexible(child: _metaText(caseSupplierName(workCase))),
                ],
              ),
              _metaText("접수 ${formatSeoulDateTime(workCase.receivedAt)}"),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _metaText(String text) => Text(
  text,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    fontSize: 13,
    letterSpacing: -.3,
    color: LdsColors.muted,
  ),
);

/// 사람이 읽는 거래처 이름: 등록 거래처(목록 title)가 먼저, 없으면 보낸
/// 사람 이름·주소.
String caseSupplierName(WorkCase workCase) => workCase.title.contains("@")
    ? workCase.senderName ?? workCase.sender
    : workCase.title;

/// 받은 메일 카드(Gmail형): 첫 글자 원 · 거래처명과 '담당자 · 주소' · 받은
/// 시각 · 접기 꺾쇠 · 제목 · 본문(접으면 한 줄 요약).
class _MailCard extends StatelessWidget {
  const _MailCard({
    required this.workCase,
    required this.mail,
    required this.open,
    required this.onToggle,
  });

  final WorkCase workCase;
  final OriginalMail mail;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final name = caseSupplierName(workCase);
    final address =
        RegExp(r"<([^>]+)>").firstMatch(mail.sender)?.group(1) ??
        (mail.sender.contains("@") ? mail.sender.trim() : "");
    final who = mail.sender.replaceAll(RegExp(r"\s*<[^>]*>\s*$"), "").trim();
    final person = who.isNotEmpty && who != address
        ? who
        : workCase.senderName ?? "";
    final sub = [
      if (person.isNotEmpty && person != name) person,
      if (address.isNotEmpty && address != name) address,
    ].join(" · ");
    final received = formatSeoulDateTime(mail.receivedAt);
    final body = mail.bodyText.trim();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: LdsColors.line),
        borderRadius: BorderRadius.circular(LdsRadius.panel),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: LdsColors.lineSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        name.isEmpty ? "?" : name.characters.first,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: LdsColors.label,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: LdsColors.ink,
                            ),
                          ),
                          if (sub.isNotEmpty)
                            Text(
                              sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: LdsColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      received.length > 5 ? received.substring(5) : received,
                      style: const TextStyle(
                        fontSize: 13,
                        color: LdsColors.muted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      open
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: LdsColors.muted,
                      semanticLabel: open ? "메일 접기" : "메일 펼치기",
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SelectableText(
              mail.subject,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.5,
                letterSpacing: -.3,
                color: LdsColors.ink,
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 18),
              child: SelectableText(
                body.isEmpty ? "(본문 없음)" : body,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  letterSpacing: -.3,
                  color: body.isEmpty ? LdsColors.muted : LdsColors.title,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
              child: Text(
                body.isEmpty ? "(본문 없음)" : body.replaceAll(RegExp(r"\s+"), " "),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  letterSpacing: -.3,
                  color: LdsColors.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// '첨부파일 N' + 첨부 카드(320, 모서리 16). PDF 카드를 누르면 바로 아래에
/// 미리보기가 상세 폭 전체로 펼쳐지고, 다시 누르거나 ×를 누르면 접힙니다.
/// 미리 볼 수 없는 형식은 내려받습니다.
class _Attachments extends StatelessWidget {
  const _Attachments({
    required this.mail,
    required this.expandedId,
    required this.downloadingIds,
    required this.onToggle,
    required this.onDownload,
    required this.onEnlarge,
  });

  static const previewHeight = 640.0;

  final OriginalMail mail;
  final String? expandedId;
  final Set<String> downloadingIds;
  final ValueChanged<MailAttachment> onToggle;
  final ValueChanged<MailAttachment> onDownload;
  final ValueChanged<MailAttachment> onEnlarge;

  @override
  Widget build(BuildContext context) {
    final expanded = mail.attachments
        .where((attachment) => attachment.id == expandedId && attachment.isPdf)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          "첨부파일 ${mail.attachments.length}",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LdsColors.label,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final attachment in mail.attachments)
              AttachmentCard(
                attachment: attachment,
                expanded: attachment.id == expanded?.id,
                busy: downloadingIds.contains(attachment.id),
                onTap: attachment.isPdf
                    ? () => onToggle(attachment)
                    : () => onDownload(attachment),
              ),
          ],
        ),
        if (expanded != null) ...[
          const SizedBox(height: 12),
          AttachmentViewer(
            key: ValueKey(expanded.id),
            mailId: mail.id,
            attachment: expanded,
            height: previewHeight,
            onClose: () => onToggle(expanded),
            onEnlarge: () => onEnlarge(expanded),
          ),
        ],
      ],
    );
  }
}

/// 첨부 카드: 아이콘 24 · 파일 이름(15/500) · '형식 · 크기'(13).
class AttachmentCard extends StatelessWidget {
  const AttachmentCard({
    super.key,
    required this.attachment,
    required this.expanded,
    required this.onTap,
    this.busy = false,
  });

  final MailAttachment attachment;
  final bool expanded;
  final bool busy;
  final VoidCallback onTap;

  static String kindOf(MailAttachment attachment) {
    final name = attachment.filename.toLowerCase();
    if (attachment.isPdf) return "PDF";
    if (name.endsWith(".xlsx") || name.endsWith(".xls")) return "엑셀";
    return name.contains(".") ? name.split(".").last.toUpperCase() : "파일";
  }

  @override
  Widget build(BuildContext context) {
    final name = attachment.filename.toLowerCase();
    final icon = attachment.isPdf
        ? Icons.picture_as_pdf_outlined
        : name.endsWith(".xlsx") || name.endsWith(".xls")
        ? Icons.table_chart_outlined
        : Icons.insert_drive_file_outlined;
    final color = expanded ? LdsColors.primary : LdsColors.label;
    return Semantics(
      button: true,
      expanded: attachment.isPdf ? expanded : null,
      label:
          "${attachment.filename} ${attachment.isPdf ? (expanded ? "미리보기 접기" : "미리보기 펼치기") : "내려받기"}",
      excludeSemantics: true,
      child: Tooltip(
        message: attachment.isPdf ? "PDF 미리보기" : "미리 볼 수 없는 형식이라 내려받습니다.",
        waitDuration: const Duration(milliseconds: 600),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: expanded ? LdsColors.primary : LdsColors.borderStrong,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 320,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (busy)
                      const SizedBox.square(
                        dimension: 24,
                        child: Padding(
                          padding: EdgeInsets.all(3),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      Icon(icon, size: 24, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attachment.filename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.6,
                              letterSpacing: -.3,
                              color: LdsColors.ink,
                            ),
                          ),
                          Text(
                            "${kindOf(attachment)} · "
                            "${_AttachmentTile._size(attachment.sizeBytes)}",
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: LdsColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
