import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../mail_draft/presentation/mail_draft_dialog.dart";
import "../../domain/candidate.dart";
import "../../domain/work_case.dart";
import "../work_queue_view_model.dart";

/// 09 SCR-002 후보·요청: 에이전트가 고른 후보 중 견적을 요청할 업체를 고릅니다.
/// 필수 조건을 어긴 후보와 연락처가 없는 후보는 고를 수 없습니다.
class CandidateSelection extends ConsumerStatefulWidget {
  const CandidateSelection({super.key, required this.workCase});

  final WorkCase workCase;

  @override
  ConsumerState<CandidateSelection> createState() => _CandidateSelectionState();
}

class _CandidateSelectionState extends ConsumerState<CandidateSelection> {
  Set<String>? _selected;
  bool _busy = false;
  String? _error;
  Timer? _retry;

  @override
  void didUpdateWidget(CandidateSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 후보 찾기가 끝나 업무 단계나 가능한 작업이 바뀌면 후보 목록을 다시 읽습니다.
    final before = oldWidget.workCase, after = widget.workCase;
    if (before.processingStep != after.processingStep ||
        before.can(WorkCaseAction.selectCandidates) !=
            after.can(WorkCaseAction.selectCandidates)) {
      _retry?.cancel();
      // Not while the tree is building: the panel may be removing this widget.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(caseCandidatesProvider(widget.workCase.id));
      });
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  /// 후보를 아직 찾는 중(CANDIDATES_NOT_READY)이면 3초 뒤 다시 조회합니다.
  void _retryLater() {
    if (_retry?.isActive ?? false) return;
    _retry = Timer(const Duration(seconds: 3), () {
      if (mounted) ref.invalidate(caseCandidatesProvider(widget.workCase.id));
    });
  }

  Future<void> _submit(CandidateSet set) async {
    final selected = _selected ?? set.selectedSupplierIds.toSet();
    if (_busy || selected.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.maybeOf(context);
    // The list reloads after the selection and may remove this widget, so
    // open the draft screen from the navigator, which stays mounted.
    final navigatorContext = Navigator.of(context, rootNavigator: true).context;
    try {
      final drafts = await ref
          .read(workQueueViewModelProvider.notifier)
          .selectCandidates(widget.workCase, set, selected.toList());
      messenger?.showSnackBar(
        SnackBar(content: Text("${selected.length}곳에 보낼 견적 요청 초안을 만들었어요.")),
      );
      if (mounted) setState(() => _busy = false);
      if (drafts.isNotEmpty && navigatorContext.mounted) {
        // Open on the supplier that needs the buyer first.
        final first =
            ([...drafts]..sort(
                  (a, b) => (a.dispatchState?.priority ?? 9).compareTo(
                    b.dispatchState?.priority ?? 9,
                  ),
                ))
                .first;
        await showMailDraftDialog(
          navigatorContext,
          caseId: widget.workCase.id,
          draftId: first.draftId,
          dispatchStates: {
            for (final draft in drafts) draft.draftId: ?draft.dispatchState,
          },
        );
      }
    } on WorkQueueFailure catch (failure) {
      if (!mounted) return;
      // A retryable failure may still have gone through; read it again.
      if (failure.caseChanged || failure.retryable) {
        ref.read(workQueueViewModelProvider.notifier).refresh();
      }
      // A 409/422 about the set: re-read API-11 and drop the old picks.
      if (failure.candidatesChanged) {
        ref.invalidate(caseCandidatesProvider(widget.workCase.id));
      }
      setState(() {
        if (failure.candidatesChanged) _selected = null;
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
    final value = ref.watch(caseCandidatesProvider(widget.workCase.id));
    return value.when(
      skipLoadingOnRefresh: false,
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) {
        if (error is WorkQueueFailure && error.code == "CANDIDATES_NOT_READY") {
          _retryLater();
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  "에이전트가 견적 요청 후보를 찾고 있어요.",
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: context.palette.muted,
                  ),
                ),
              ],
            ),
          );
        }
        return Text(
          error is WorkQueueFailure ? error.message : "후보 목록을 불러오지 못했어요.",
          style: TextStyle(
            fontSize: AppFontSizes.body,
            color: context.palette.muted,
          ),
        );
      },
      data: (set) {
        final selected = _selected ?? set.selectedSupplierIds.toSet();
        final itemName = widget.workCase.itemName;
        final canSelect = set.canSelect;
        final blockedReason = set.blockedReason;
        // 서버 사정으로 막힌 경우: 목록 위에서 먼저 알리고 후보를 흐리게 보여줍니다.
        final serverNotice = set.serverBlockedNotice;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              itemName == null ? "견적 요청 대상 선택" : "$itemName 견적 요청 대상 선택",
              style: const TextStyle(
                fontSize: AppFontSizes.bodyLarge,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "에이전트가 이 품목을 취급하는 업체를 찾았어요. 견적을 요청할 업체를 골라 주세요.",
              style: TextStyle(
                fontSize: AppFontSizes.secondary,
                color: context.palette.muted,
              ),
            ),
            if (set.isStale) ...[
              const SizedBox(height: 12),
              _Notice(
                icon: Icons.history,
                text: "업무 내용이 바뀌어 아래는 이전 후보예요. 이 후보로는 견적을 요청할 수 없어요.",
                action: TextButton(
                  onPressed: () => ref.invalidate(
                    caseCandidatesProvider(widget.workCase.id),
                  ),
                  style: WorkspaceButtonStyles.text(context),
                  child: const Text("다시 불러오기"),
                ),
              ),
            ],
            if (serverNotice != null) ...[
              const SizedBox(height: 12),
              _Notice(
                icon: Icons.info_outline,
                color: const Color(0xFF8A6516),
                text: serverNotice,
                action: TextButton(
                  onPressed: () => ref.invalidate(
                    caseCandidatesProvider(widget.workCase.id),
                  ),
                  style: WorkspaceButtonStyles.text(context),
                  child: const Text("다시 확인"),
                ),
              ),
            ],
            if (set.unknownFields.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Notice(
                icon: Icons.help_outline,
                text:
                    "확인 못 한 항목: ${set.unknownFields.map(unknownFieldLabel).join(", ")}",
              ),
            ],
            const SizedBox(height: 12),
            for (final candidate in set.candidates)
              Opacity(
                // 지금은 어떤 후보도 고를 수 없으면 목록 전체를 흐리게 보입니다.
                opacity: serverNotice != null ? 0.55 : 1,
                child: _CandidateTile(
                  candidate: candidate,
                  selected: selected.contains(candidate.supplierId),
                  enabled: !_busy && canSelect && candidate.selectable,
                  onChanged: (value) => setState(() {
                    final next = {...selected};
                    value
                        ? next.add(candidate.supplierId)
                        : next.remove(candidate.supplierId);
                    _selected = next;
                  }),
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: selected.isEmpty || _busy || !canSelect
                    ? null
                    : () => _submit(set),
                style: WorkspaceButtonStyles.filled(context),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined, size: 16),
                label: Text(
                  serverNotice != null
                      ? "지금은 요청할 수 없어요"
                      : selected.isEmpty
                      ? "업체를 골라 주세요"
                      : "선택한 ${selected.length}곳에 견적 요청",
                ),
              ),
            ),
            // Already chosen: the drafts carry on in SCR-007.
            if (!canSelect && set.selectedSupplierIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      showMailDraftDialog(context, caseId: widget.workCase.id),
                  style: WorkspaceButtonStyles.outlined(context),
                  icon: const Icon(Icons.mail_outline, size: 16),
                  label: const Text("메일 초안 보기"),
                ),
              ),
            ],
            // 위에서 이미 안내한 경우(서버 사정·과거 후보)는 아래에 다시 적지 않습니다.
            if (!canSelect &&
                blockedReason != null &&
                serverNotice == null &&
                !set.isStale &&
                _error == null) ...[
              const SizedBox(height: 8),
              Text(
                blockedReason,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: AppFontSizes.secondary,
                  color: context.palette.muted,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: AppFontSizes.body,
                  color: danger,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final Candidate candidate;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final blocked = !candidate.selectable;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: blocked ? context.palette.panel : context.palette.surface,
        border: Border.all(
          color: selected ? context.palette.accentText : context.palette.line,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? () => onChanged(!selected) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                activeColor: context.palette.accent,
                checkColor: context.palette.onAccent,
                onChanged: enabled
                    ? (value) => onChanged(value ?? false)
                    : null,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          candidate.name,
                          style: TextStyle(
                            fontSize: AppFontSizes.bodyLarge,
                            fontWeight: FontWeight.w700,
                            color: blocked
                                ? context.palette.muted
                                : context.palette.ink,
                          ),
                        ),
                        if (candidate.webCandidate)
                          const _Tag("웹 탐색 후보 · 회신 확인 전"),
                        if (candidate.preferenceScore != null)
                          Text(
                            "선호 ${candidate.preferenceScore}점",
                            style: TextStyle(
                              fontSize: AppFontSizes.caption,
                              color: context.palette.muted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      candidate.contactEmail ?? "연락처 없음 · 견적 요청 불가",
                      style: TextStyle(
                        fontSize: AppFontSizes.secondary,
                        color: context.palette.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      candidate.handlingEvidence,
                      style: const TextStyle(fontSize: AppFontSizes.body),
                    ),
                    if (candidate.reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "추천 이유 · ${candidate.reason}",
                        style: TextStyle(
                          fontSize: AppFontSizes.secondary,
                          color: context.palette.muted,
                        ),
                      ),
                    ],
                    if (candidate.checks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final check in candidate.checks)
                            _CheckChip(check: check),
                        ],
                      ),
                    ],
                    if (candidate.caution case final caution?) ...[
                      const SizedBox(height: 8),
                      _Notice(
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFF8A6516),
                        text: "주의 · $caution · 자동 발송하지 않고 승인을 기다려요.",
                      ),
                    ],
                    if (candidate.unknownFields.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        "확인 못 한 항목 · ${candidate.unknownFields.map(unknownFieldLabel).join(", ")}",
                        style: TextStyle(
                          fontSize: AppFontSizes.secondary,
                          color: context.palette.muted,
                        ),
                      ),
                    ],
                    if (candidate.failsRequired) ...[
                      const SizedBox(height: 6),
                      const Text(
                        "필수 조건을 충족하지 않아 견적 요청 대상으로 고를 수 없어요.",
                        style: TextStyle(
                          fontSize: AppFontSizes.secondary,
                          color: Color(0xFF8A6516),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckChip extends StatelessWidget {
  const _CheckChip({required this.check});

  final CandidateCheck check;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (check.state) {
      CheckState.met => (
        const Color(0xFF00754A),
        const Color(0xFFE2F4EA),
        Icons.check,
      ),
      CheckState.unmet => (
        const Color(0xFF8A6516),
        const Color(0xFFF6EEDC),
        Icons.close,
      ),
      CheckState.unknown => (
        context.palette.muted,
        context.palette.line,
        Icons.help_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            "${check.required ? "" : "선호 · "}${check.label} ${check.state.label}",
            style: TextStyle(fontSize: AppFontSizes.caption, color: color),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFE6EEF6),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: AppFontSizes.caption,
        color: Color(0xFF2F5E8C),
      ),
    ),
  );
}

/// One-line notice inside the candidate list.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    this.color,
    this.action,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: context.palette.panel,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 15, color: color ?? context.palette.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppFontSizes.secondary,
              color: color ?? context.palette.muted,
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}
