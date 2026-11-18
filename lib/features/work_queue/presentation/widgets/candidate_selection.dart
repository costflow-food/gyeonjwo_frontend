import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../../../shared/widgets/mobile_scaffold.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
import "../../../mail_draft/presentation/mail_draft_dialog.dart";
import "../../domain/candidate.dart";
import "../../domain/work_case.dart";
import "../work_queue_view_model.dart";
import "case_progress.dart";

class CandidateSelection extends ConsumerStatefulWidget {
  const CandidateSelection({
    super.key,
    required this.workCase,
    this.page = false,
    this.onLater,
  });

  final WorkCase workCase;

  /// 넓은 화면 '나중에': 다음 업무로 넘어갑니다. null이면 두지 않습니다.
  final VoidCallback? onLater;

  /// Phone: a screen of its own with the request button pinned to the bottom.
  final bool page;

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
        SnackBar(content: Text("${selected.length}곳에 보낼 견적 요청 초안을 만들었습니다.")),
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
            ? "결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다."
            : failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "결과를 확인하지 못했습니다. 다시 누르면 같은 요청으로 확인합니다.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.page) return _todo(context);
    Widget? bar;
    final body = _content(context, (submit) => bar = submit);
    return MobilePageScaffold(
      title: "견적 요청 대상 선택",
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: body,
      ),
      bottomBar: bar,
    );
  }

  /// 넓은 화면: '지금 할 일' 상자 안의 체크 목록 (Tasks 시안 '업체 선택').
  /// 줄 = 체크 · 업체 이름 · 조건 n/전체. 처음 체크는 서버에 저장된 선택입니다.
  Widget _todo(BuildContext context) {
    const title = "견적을 요청할 업체를 골라 주세요";
    const tag = "업체 선택 대기";
    final value = ref.watch(caseCandidatesProvider(widget.workCase.id));
    Widget box({
      String? description,
      String? tableLabel,
      Widget? body,
      List<Widget> actions = const [],
      Widget? leading,
      Widget? footer,
    }) => TodoBox(
      title: title,
      tag: tag,
      description: description,
      tableLabel: tableLabel,
      body: body,
      actions: actions,
      leading: leading,
      footer: footer,
    );
    return value.when(
      skipLoadingOnRefresh: false,
      loading: () => box(
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        leading: const SizedBox.shrink(),
      ),
      error: (error, _) {
        if (error is WorkQueueFailure && error.code == "CANDIDATES_NOT_READY") {
          _retryLater();
          return box(description: "에이전트가 견적 요청 후보를 찾고 있습니다.");
        }
        return box(
          description: error is WorkQueueFailure
              ? error.message
              : "후보 목록을 불러오지 못했습니다.",
          actions: [
            LdsButton(
              label: "다시 불러오기",
              variant: LdsButtonVariant.outlined,
              onPressed: () =>
                  ref.invalidate(caseCandidatesProvider(widget.workCase.id)),
            ),
          ],
        );
      },
      data: (set) {
        final selected = _selected ?? set.selectedSupplierIds.toSet();
        final canSelect = set.canSelect;
        final serverBlocked = set.serverBlocked;
        final blockedReason = set.blockedReason;
        final count = set.candidates.length;
        final notes = <Widget>[
          if (set.isStale)
            _Notice(
              icon: Icons.history,
              text: "업무 내용이 바뀌어 아래는 이전 후보입니다. 이 후보로는 견적을 요청할 수 없습니다.",
              action: TextButton(
                onPressed: () =>
                    ref.invalidate(caseCandidatesProvider(widget.workCase.id)),
                style: WorkspaceButtonStyles.text(context),
                child: const Text("다시 불러오기"),
              ),
            ),
          if (set.unknownFields.isNotEmpty)
            _Notice(
              icon: Icons.help_outline,
              text:
                  "확인 못 한 항목: ${set.unknownFields.map(unknownFieldLabel).join(", ")}",
            ),
        ];
        final caption =
            _error ??
            (!canSelect &&
                    blockedReason != null &&
                    !serverBlocked &&
                    !set.isStale
                ? blockedReason
                : null);
        return box(
          description:
              "조건에 맞는 후보 $count곳을 찾았어요. 요청할 업체를 고르면 견적 요청 메일 초안을 만들어요.",
          tableLabel: "찾은 후보 $count곳",
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final note in notes) ...[note, const SizedBox(height: 8)],
              Opacity(
                opacity: serverBlocked ? 0.55 : 1,
                child: _PickList(
                  candidates: set.candidates,
                  selected: selected,
                  enabled: !_busy && canSelect,
                  onChanged: (candidate, value) => setState(() {
                    final next = {...selected};
                    value
                        ? next.add(candidate.supplierId)
                        : next.remove(candidate.supplierId);
                    _selected = next;
                  }),
                ),
              ),
            ],
          ),
          leading: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "${selected.length}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: LdsColors.ink,
                  ),
                ),
                TextSpan(text: " / $count곳 선택"),
              ],
            ),
            style: const TextStyle(
              fontSize: 13,
              letterSpacing: -.3,
              color: LdsColors.muted,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          actions: [
            // 이미 골라 초안이 만들어졌으면 초안 화면(SCR-007)에서 이어 갑니다.
            if (!canSelect && set.selectedSupplierIds.isNotEmpty)
              LdsButton(
                label: "메일 초안 보기",
                variant: LdsButtonVariant.outlined,
                onPressed: () =>
                    showMailDraftDialog(context, caseId: widget.workCase.id),
              ),
            if (widget.onLater case final onLater?)
              LdsButton(
                label: "나중에",
                variant: LdsButtonVariant.ghostNeutral,
                onPressed: onLater,
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 112),
              child: LdsButton(
                label: "견적 요청",
                loading: _busy,
                onPressed: selected.isEmpty || _busy || !canSelect
                    ? null
                    : () => _submit(set),
              ),
            ),
          ],
          footer: caption == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    caption,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      color: _error != null
                          ? LdsColors.errorText
                          : LdsColors.muted,
                    ),
                  ),
                ),
        );
      },
    );
  }

  /// [pinSubmit] takes the request button on a phone page; otherwise the
  /// button stays at the end of the list.
  Widget _content(BuildContext context, void Function(Widget) pinSubmit) {
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
                // Wraps on a narrow phone or with a large system font.
                Flexible(
                  child: Text(
                    "에이전트가 견적 요청 후보를 찾고 있습니다.",
                    style: TextStyle(
                      fontSize: AppFontSizes.body,
                      color: context.palette.muted,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Text(
          error is WorkQueueFailure ? error.message : "후보 목록을 불러오지 못했습니다.",
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
        // 서버 사정으로 막힌 경우: 버튼을 막고 후보를 흐리게 보여줍니다.
        final serverBlocked = set.serverBlocked;
        final submit = FilledButton.icon(
          onPressed: selected.isEmpty || _busy || !canSelect
              ? null
              : () => _submit(set),
          style: widget.page
              ? MobileButtons.filled(context)
              : WorkspaceButtonStyles.filled(context),
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
            serverBlocked
                ? "지금은 요청할 수 없습니다"
                : selected.isEmpty
                ? "업체를 골라 주세요"
                : "선택한 ${selected.length}곳에 견적 요청",
          ),
        );
        if (widget.page) pinSubmit(submit);
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
              "에이전트가 이 품목을 취급하는 업체를 찾았습니다. 견적을 요청할 업체를 골라 주세요.",
              style: TextStyle(
                fontSize: AppFontSizes.secondary,
                color: context.palette.muted,
              ),
            ),
            if (set.isStale) ...[
              const SizedBox(height: 12),
              _Notice(
                icon: Icons.history,
                text: "업무 내용이 바뀌어 아래는 이전 후보입니다. 이 후보로는 견적을 요청할 수 없습니다.",
                action: TextButton(
                  onPressed: () => ref.invalidate(
                    caseCandidatesProvider(widget.workCase.id),
                  ),
                  style: WorkspaceButtonStyles.text(context),
                  child: const Text("다시 불러오기"),
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
                opacity: serverBlocked ? 0.55 : 1,
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
            if (!widget.page) ...[
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: submit),
            ],
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
            // 서버 사정으로 막힌 경우는 안내 없이 버튼만 막고, 과거 후보는 위에서 이미
            // 안내했으므로 아래에 다시 적지 않습니다.
            if (!canSelect &&
                blockedReason != null &&
                !serverBlocked &&
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

/// 업체 선택 체크 목록: 흰 바탕, 1px `#E5E7EA`, 모서리 8, 줄 높이 44.
/// 줄 = 체크(24, 고르면 주황) · 업체 이름(15/600) · 조건 충족 수. 단가는 후보
/// 자료(API-11)에 없어 두지 않습니다. 근거·추천 이유는 줄에 마우스를 올리면
/// 보입니다.
class _PickList extends StatelessWidget {
  const _PickList({
    required this.candidates,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final List<Candidate> candidates;
  final Set<String> selected;
  final bool enabled;
  final void Function(Candidate candidate, bool value) onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: LdsColors.line),
      borderRadius: BorderRadius.circular(LdsRadius.table),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, candidate) in candidates.indexed) ...[
          if (index > 0) const Divider(height: 1, color: LdsColors.lineSoft),
          _pickRow(candidate),
        ],
      ],
    ),
  );

  Widget _pickRow(Candidate candidate) {
    final checked = selected.contains(candidate.supplierId);
    final can = enabled && candidate.selectable;
    final met = candidate.checks
        .where((check) => check.state == CheckState.met)
        .length;
    final notes = [
      if (candidate.webCandidate) "웹 탐색 후보 · 회신 확인 전",
      if (candidate.contactEmail == null) "연락처 없음 · 견적 요청 불가",
      if (candidate.failsRequired) "필수 조건 미충족",
      if (candidate.caution case final caution?) "주의 · $caution",
    ];
    final help = [
      candidate.handlingEvidence,
      if (candidate.reason.isNotEmpty) "추천 이유 · ${candidate.reason}",
    ].where((line) => line.isNotEmpty).join("\n");
    final row = InkWell(
      onTap: can ? () => onChanged(candidate, !checked) : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 24,
                child: Checkbox(
                  value: checked,
                  activeColor: LdsColors.primary,
                  side: const BorderSide(
                    color: LdsColors.borderStrong,
                    width: 2,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: can
                      ? (value) => onChanged(candidate, value ?? false)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.3,
                        color: candidate.selectable
                            ? LdsColors.ink
                            : LdsColors.muted,
                      ),
                    ),
                    if (notes.isNotEmpty)
                      Text(
                        notes.join(" · "),
                        style: const TextStyle(
                          fontSize: 12,
                          color: LdsColors.cautionText,
                        ),
                      ),
                  ],
                ),
              ),
              if (candidate.checks.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text(
                  "조건 $met/${candidate.checks.length}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: LdsColors.muted,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return help.isEmpty
        ? row
        : Tooltip(
            message: help,
            waitDuration: const Duration(milliseconds: 600),
            child: row,
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
                        text: "주의 · $caution · 자동 발송하지 않고 승인을 기다립니다.",
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
                        "필수 조건을 충족하지 않아 견적 요청 대상으로 고를 수 없습니다.",
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
