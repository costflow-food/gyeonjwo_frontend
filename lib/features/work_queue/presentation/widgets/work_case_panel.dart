import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/file_save/file_save.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/widgets/outline_panel.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../review_progress/presentation/review_progress_view.dart";
import "../../data/work_queue_repository_impl.dart";
import "../../domain/work_case.dart";
import "../work_queue_view_model.dart";
import "attachment_viewer.dart";
import "candidate_selection.dart";
import "case_step_status.dart";
import "status_badge.dart";

/// 선택한 업무의 원문(제목·본문·첨부)과, 아직 실행하지 않은 업무의 두 가지 선택.
/// PDF 첨부가 있으면 본문 옆(좁으면 아래)에 뷰어를 띄웁니다.
class WorkCasePanel extends ConsumerStatefulWidget {
  const WorkCasePanel({super.key, required this.workCase});

  final WorkCase workCase;

  @override
  ConsumerState<WorkCasePanel> createState() => _WorkCasePanelState();
}

class _WorkCasePanelState extends ConsumerState<WorkCasePanel> {
  /// 이보다 넓으면 원문과 첨부를 나란히 둡니다.
  static const _sideBySideWidth = 960.0;

  bool _busy = false;
  String? _error;

  /// 사용자가 고른 첨부. 고르기 전에는 첫 PDF를 자동으로 엽니다.
  String? _openAttachmentId;
  bool _viewerClosed = false;

  MailAttachment? _openAttachment(OriginalMail? mail) {
    if (mail == null || _viewerClosed) return null;
    final pdfs = mail.attachments.where((attachment) => attachment.isPdf);
    return pdfs.where((a) => a.id == _openAttachmentId).firstOrNull ??
        pdfs.firstOrNull;
  }

  void _openViewer(MailAttachment attachment) => setState(() {
    _openAttachmentId = attachment.id;
    _viewerClosed = false;
  });

  void _closeViewer() => setState(() => _viewerClosed = true);

  /// 미리 볼 수 없는 첨부(Excel·이미지 등)는 API-26 원본을 내려받습니다.
  Future<void> _download(String mailId, MailAttachment attachment) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final bytes = await ref
          .read(workQueueRepositoryProvider)
          .getAttachmentContent(mailId, attachment.id);
      saveFile(
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
                : "${attachment.filename}을(를) 내려받지 못했어요.",
          ),
        ),
      );
    }
  }

  WorkQueueViewModel get _viewModel =>
      ref.read(workQueueViewModelProvider.notifier);

  Future<void> _acceptIncrease() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "인상을 수용할까요?",
          style: TextStyle(
            fontSize: AppFontSizes.dialogTitleSmall,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          "수용하면 이 업무와 연결된 메일이 견줘에서 삭제되고 되돌릴 수 없어요.\n"
          "견적 수락 메일이나 발주는 보내지 않아요.",
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
      done: "수용했어요. 업무 큐에서 정리했어요.",
    )) {
      router.go("/");
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
            ? "결과를 확인하지 못했어요. 다시 누르면 같은 요청으로 확인해요."
            : failure.message;
      });
      return false;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _busy = false;
        _error = "결과를 확인하지 못했어요. 다시 누르면 같은 요청으로 확인해요.";
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workCase = widget.workCase;
    final mail = ref.watch(originalMailProvider(workCase.initialMailId));
    final loadedMail = mail.asData?.value;
    final openAttachment = _openAttachment(loadedMail);
    final panel = OutlinePanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusBadge(workCase.status, rawCode: workCase.statusCode),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  workCase.itemName == null
                      ? "품목 미확인"
                      : "${workCase.itemName} 품목",
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: context.palette.muted,
                  ),
                ),
              ),
              IconButton(
                tooltip: "닫기",
                onPressed: () => context.go("/"),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          mail.when(
            skipLoadingOnRefresh: false,
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _MailError(
              message: error is WorkQueueFailure
                  ? error.message
                  : "메일 원문을 불러오지 못했어요.",
              onRetry: () =>
                  ref.invalidate(originalMailProvider(workCase.initialMailId)),
            ),
            data: (mail) => _MailContent(
              mail: mail,
              openAttachmentId: openAttachment?.id,
              onOpen: _openViewer,
              onDownload: (attachment) => _download(mail.id, attachment),
            ),
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: context.palette.line),
          const SizedBox(height: 20),
          // Blocked candidates are still shown, read-only, with the reason.
          if (workCase.can(WorkCaseAction.selectCandidates) ||
              (workCase.atCandidates &&
                  workCase.disabledMessage(WorkCaseAction.selectCandidates) !=
                      null))
            CandidateSelection(workCase: workCase)
          else if (workCase.notStarted)
            _Decision(
              workCase: workCase,
              busy: _busy,
              onAccept: _acceptIncrease,
              onStart: _start,
            )
          else
            CaseStepStatus(workCase: workCase),
          if (workCase.hasReviewCard) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                style: WorkspaceButtonStyles.filled(context),
                onPressed: () => context.go("/cases/${workCase.id}/review"),
                icon: const Icon(Icons.fact_check_outlined, size: 16),
                label: const Text("검토 카드 보기"),
              ),
            ),
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
    );
    if (loadedMail == null || openAttachment == null) return panel;

    AttachmentViewer viewer(double height) => AttachmentViewer(
      key: ValueKey(openAttachment.id),
      mailId: loadedMail.id,
      attachment: openAttachment,
      height: height,
      onClose: _closeViewer,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _sideBySideWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [panel, const SizedBox(height: 16), viewer(720)],
          );
        }
        // 화면 높이에 맞춰 원문을 스크롤하지 않아도 PDF 한 페이지가 보이게 합니다.
        final height = (MediaQuery.sizeOf(context).height - 80).clamp(
          480.0,
          1600.0,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: panel),
            const SizedBox(width: 16),
            Expanded(flex: 6, child: viewer(height)),
          ],
        );
      },
    );
  }
}

class _MailContent extends StatelessWidget {
  const _MailContent({
    required this.mail,
    required this.openAttachmentId,
    required this.onOpen,
    required this.onDownload,
  });

  final OriginalMail mail;
  final String? openAttachmentId;
  final ValueChanged<MailAttachment> onOpen;

  /// PDF가 아닌 첨부: 미리 보기 대신 내려받습니다.
  final ValueChanged<MailAttachment> onDownload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectableText(
          mail.subject,
          style: const TextStyle(
            fontSize: AppFontSizes.dialogTitle,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _MetaRow(label: "보낸 사람", value: mail.sender),
        _MetaRow(label: "받는 사람", value: mail.recipients.join(", ")),
        _MetaRow(label: "받은 시각", value: formatSeoulDateTime(mail.receivedAt)),
        const SizedBox(height: 16),
        Divider(height: 1, color: context.palette.line),
        const SizedBox(height: 16),
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
            "첨부파일이 없어요.",
            style: TextStyle(
              fontSize: AppFontSizes.secondary,
              color: context.palette.muted,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final attachment in mail.attachments)
                _AttachmentTile(
                  attachment: attachment,
                  selected: attachment.id == openAttachmentId,
                  onTap: attachment.isPdf
                      ? () => onOpen(attachment)
                      : () => onDownload(attachment),
                ),
            ],
          ),
      ],
    );
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
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppFontSizes.body,
              color: context.palette.muted,
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
  });

  final MailAttachment attachment;
  final bool selected;

  /// PDF는 뷰어로 열고, 다른 형식은 내려받습니다.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final extension = attachment.filename.contains(".")
        ? attachment.filename.split(".").last.toUpperCase()
        : "파일";
    final tile = Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? context.palette.accentText : context.palette.line,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                    fontWeight: FontWeight.w600,
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
      message: attachment.isPdf ? "PDF 미리 보기" : "미리 볼 수 없는 형식이라 내려받아요.",
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

/// 아직 실행하지 않은 업무: 수용하기 / 다른 대안 찾기.
/// 버튼은 서버가 허용한 행동(allowed_actions)일 때만 누를 수 있습니다.
class _Decision extends StatelessWidget {
  const _Decision({
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
    final accept = _Choice(
      button: OutlinedButton(
        onPressed: canAccept && !busy ? onAccept : null,
        style: WorkspaceButtonStyles.outlined(context),
        child: const Text("수용하기"),
      ),
      caption: canAccept
          ? "인상안을 받아들이고 업무를 정리해요. 되돌릴 수 없어요."
          : workCase.disabledMessage(WorkCaseAction.acceptIncrease) ??
                "지금은 수용할 수 없어요.",
    );
    final start = _Choice(
      button: FilledButton.icon(
        onPressed: canStart && !busy ? onStart : null,
        style: WorkspaceButtonStyles.filled(context),
        icon: const Icon(Icons.travel_explore, size: 16),
        label: const Text("다른 대안 찾기"),
      ),
      caption: canStart
          ? "등록된 거래처 자료로 에이전트가 검토를 시작해요."
          : workCase.disabledMessage(WorkCaseAction.start) ??
                "서버에서 검토 실행이 아직 준비되지 않았어요.",
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "원문을 확인한 뒤 어떻게 처리할지 골라 주세요.",
          style: TextStyle(
            fontSize: AppFontSizes.bodyLarge,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 480) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [accept, const SizedBox(height: 12), start],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: accept),
                const SizedBox(width: 12),
                Expanded(child: start),
              ],
            );
          },
        ),
        if (busy) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(minHeight: 2, color: context.palette.accent),
        ],
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.button, required this.caption});

  final Widget button;
  final String caption;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: 44, child: button),
      const SizedBox(height: 6),
      Text(
        caption,
        style: TextStyle(
          fontSize: AppFontSizes.secondary,
          color: context.palette.muted,
          height: 1.5,
        ),
      ),
    ],
  );
}
