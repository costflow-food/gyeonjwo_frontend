import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/widgets/outline_panel.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../domain/work_case.dart";
import "../work_queue_view_model.dart";
import "candidate_selection.dart";
import "status_badge.dart";

/// 선택한 업무의 원문(제목·본문·첨부)과, 아직 실행하지 않은 업무의 두 가지 선택.
class WorkCasePanel extends ConsumerStatefulWidget {
  const WorkCasePanel({super.key, required this.workCase});

  final WorkCase workCase;

  @override
  ConsumerState<WorkCasePanel> createState() => _WorkCasePanelState();
}

class _WorkCasePanelState extends ConsumerState<WorkCasePanel> {
  bool _busy = false;
  String? _error;

  WorkQueueViewModel get _viewModel =>
      ref.read(workQueueViewModelProvider.notifier);

  Future<void> _acceptIncrease() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "인상을 수긍할까요?",
          style: TextStyle(
            fontSize: AppFontSizes.dialogTitleSmall,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          "수긍하면 이 업무와 연결된 메일이 견줘에서 삭제되고 되돌릴 수 없어요.\n"
          "견적 수락 메일이나 발주는 보내지 않아요.",
          style: TextStyle(fontSize: AppFontSizes.body, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: WorkspaceButtonStyles.text,
            child: const Text("취소"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: WorkspaceButtonStyles.filled,
            child: const Text("수긍하기"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => _viewModel.acceptIncrease(widget.workCase),
      done: "수긍했어요. 업무 큐에서 정리했어요.",
    );
  }

  Future<void> _start() => _run(
    () => _viewModel.start(widget.workCase),
    done: "검토를 시작했어요. 요청 정보 추출이 끝나면 다음 단계로 넘어가요.",
  );

  Future<void> _run(
    Future<void> Function() request, {
    required String done,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await request();
      messenger?.showSnackBar(SnackBar(content: Text(done)));
      if (mounted) setState(() => _busy = false);
    } on WorkQueueFailure catch (failure) {
      if (!mounted) return;
      if (failure.caseChanged) _viewModel.refresh();
      setState(() {
        _busy = false;
        _error = failure.unknownOutcome
            ? "결과를 확인하지 못했어요. 다시 누르면 같은 요청으로 확인해요."
            : failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "결과를 확인하지 못했어요. 다시 누르면 같은 요청으로 확인해요.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final workCase = widget.workCase;
    final mail = ref.watch(originalMailProvider(workCase.initialMailId));
    return OutlinePanel(
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
                  style: const TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: muted,
                  ),
                ),
              ),
              IconButton(
                tooltip: "닫기",
                onPressed: () => _viewModel.select(null),
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
            data: (mail) => _MailContent(mail: mail),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: line),
          const SizedBox(height: 20),
          if (workCase.can(WorkCaseAction.selectCandidates))
            CandidateSelection(workCase: workCase)
          else if (workCase.notStarted)
            _Decision(
              workCase: workCase,
              busy: _busy,
              onAccept: _acceptIncrease,
              onStart: _start,
            )
          else
            _CurrentStep(workCase: workCase),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: AppFontSizes.body,
                color: accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MailContent extends StatelessWidget {
  const _MailContent({required this.mail});

  final OriginalMail mail;

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
        const Divider(height: 1, color: line),
        const SizedBox(height: 16),
        SelectableText(
          mail.bodyText.isEmpty ? "(본문 없음)" : mail.bodyText,
          style: TextStyle(
            fontSize: AppFontSizes.bodyLarge,
            height: 1.8,
            color: mail.bodyText.isEmpty ? muted : ink,
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
          const Text(
            "첨부파일이 없어요.",
            style: TextStyle(fontSize: AppFontSizes.secondary, color: muted),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final attachment in mail.attachments)
                _AttachmentTile(attachment: attachment),
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
            style: const TextStyle(fontSize: AppFontSizes.body, color: muted),
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
  const _AttachmentTile({required this.attachment});

  final MailAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final extension = attachment.filename.contains(".")
        ? attachment.filename.split(".").last.toUpperCase()
        : "파일";
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.mimeType == "application/pdf"
                ? Icons.picture_as_pdf_outlined
                : Icons.insert_drive_file_outlined,
            size: 20,
            color: muted,
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
                  style: const TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          style: WorkspaceButtonStyles.outlined,
          child: const Text("다시 시도"),
        ),
      ],
    ),
  );
}

/// 아직 실행하지 않은 업무: 수긍하기 / 다른 대안 찾기.
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
        style: WorkspaceButtonStyles.outlined,
        child: const Text("수긍하기"),
      ),
      caption: canAccept
          ? "인상안을 받아들이고 업무를 정리해요. 되돌릴 수 없어요."
          : workCase.disabledMessage(WorkCaseAction.acceptIncrease) ??
                "지금은 수긍할 수 없어요.",
    );
    final start = _Choice(
      button: FilledButton.icon(
        onPressed: canStart && !busy ? onStart : null,
        style: WorkspaceButtonStyles.filled,
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
          const LinearProgressIndicator(minHeight: 2, color: accent),
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
        style: const TextStyle(
          fontSize: AppFontSizes.secondary,
          color: muted,
          height: 1.5,
        ),
      ),
    ],
  );
}

/// 이미 실행한 업무: 버튼 없이 서버가 알려 준 현재 단계만 보여 줍니다.
class _CurrentStep extends StatelessWidget {
  const _CurrentStep({required this.workCase});

  final WorkCase workCase;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 18, color: muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            workCase.stepMessage.isEmpty
                ? "검토가 진행되고 있어요."
                : workCase.stepMessage,
            style: const TextStyle(fontSize: AppFontSizes.body),
          ),
        ),
      ],
    ),
  );
}
