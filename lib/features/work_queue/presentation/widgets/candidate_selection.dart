import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/app_font_sizes.dart";
import "../../../../shared/widgets/workspace_button_styles.dart";
import "../../../../shared/workspace_colors.dart";
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

  Future<void> _submit(CandidateSet set) async {
    final selected = _selected ?? set.selectedSupplierIds.toSet();
    if (_busy || selected.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref
          .read(workQueueViewModelProvider.notifier)
          .selectCandidates(widget.workCase, set, selected.toList());
      messenger?.showSnackBar(
        SnackBar(content: Text("${selected.length}곳에 보낼 견적 요청 초안을 만들었어요.")),
      );
      if (mounted) setState(() => _busy = false);
    } on WorkQueueFailure catch (failure) {
      if (!mounted) return;
      if (failure.caseChanged) {
        ref.read(workQueueViewModelProvider.notifier).refresh();
      }
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
    final value = ref.watch(caseCandidatesProvider(widget.workCase.id));
    return value.when(
      skipLoadingOnRefresh: false,
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text(
        error is WorkQueueFailure ? error.message : "후보 목록을 불러오지 못했어요.",
        style: const TextStyle(fontSize: AppFontSizes.body, color: muted),
      ),
      data: (set) {
        final selected = _selected ?? set.selectedSupplierIds.toSet();
        final itemName = widget.workCase.itemName;
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
            const Text(
              "에이전트가 이 품목을 취급하는 업체를 찾았어요. 견적을 요청할 업체를 골라 주세요.",
              style: TextStyle(fontSize: AppFontSizes.secondary, color: muted),
            ),
            const SizedBox(height: 12),
            for (final candidate in set.candidates)
              _CandidateTile(
                candidate: candidate,
                selected: selected.contains(candidate.supplierId),
                enabled: !_busy && candidate.selectable,
                onChanged: (value) => setState(() {
                  final next = {...selected};
                  value
                      ? next.add(candidate.supplierId)
                      : next.remove(candidate.supplierId);
                  _selected = next;
                }),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: selected.isEmpty || _busy
                    ? null
                    : () => _submit(set),
                style: WorkspaceButtonStyles.filled,
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
                  selected.isEmpty
                      ? "업체를 골라 주세요"
                      : "선택한 ${selected.length}곳에 견적 요청",
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: AppFontSizes.body,
                  color: accent,
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
        color: blocked ? const Color(0xFFF7F8FA) : Colors.white,
        border: Border.all(color: selected ? accent : line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? () => onChanged(!selected) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                activeColor: accent,
                onChanged: enabled ? (value) => onChanged(value ?? false) : null,
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
                            color: blocked ? muted : ink,
                          ),
                        ),
                        if (candidate.webCandidate)
                          const _Tag("웹 탐색 후보 · 회신 확인 전"),
                        if (candidate.preferenceScore != null)
                          Text(
                            "선호 ${candidate.preferenceScore}점",
                            style: const TextStyle(
                              fontSize: AppFontSizes.caption,
                              color: muted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      candidate.contactEmail ?? "연락처 없음 · 견적 요청 불가",
                      style: const TextStyle(
                        fontSize: AppFontSizes.secondary,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      candidate.handlingEvidence,
                      style: const TextStyle(fontSize: AppFontSizes.body),
                    ),
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
                    if (candidate.failsRequired) ...[
                      const SizedBox(height: 6),
                      const Text(
                        "필수 조건을 충족하지 않아 견적 요청 대상으로 고를 수 없어요.",
                        style: TextStyle(
                          fontSize: AppFontSizes.secondary,
                          color: Color(0xFFBC793C),
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
        const Color(0xFF4B9138),
        const Color(0xFFE7F5E1),
        Icons.check,
      ),
      CheckState.unmet => (
        const Color(0xFFBC793C),
        const Color(0xFFFFF2E2),
        Icons.close,
      ),
      CheckState.unknown => (muted, const Color(0xFFF0F1F4), Icons.help_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
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
      color: const Color(0xFFDCF2FD),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: AppFontSizes.caption,
        color: Color(0xFF347BC8),
      ),
    ),
  );
}
