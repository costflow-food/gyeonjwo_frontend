import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../app/app_paths.dart";
import "../../../shared/formatters.dart";
import "../../../shared/lds_colors.dart";
import "../../../shared/widgets/lds/lds.dart";
import "../domain/task_group.dart";
import "../domain/work_case.dart";
import "recent_tasks.dart";
import "work_queue_view_model.dart";

/// 상단 바 검색 창: 검색칸 + 최근 본 업무(입력 전) / 검색 결과(입력 후).
/// Enter = 첫 결과 열기, Esc = 닫기.
Future<void> showTaskSearchDialog(BuildContext context) => showGeneralDialog(
  context: context,
  barrierDismissible: true,
  barrierLabel: "검색 닫기",
  barrierColor: LdsColors.overlay,
  transitionDuration: const Duration(milliseconds: 120),
  pageBuilder: (context, _, _) => const _TaskSearchDialog(),
  transitionBuilder: (context, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
);

class _TaskSearchDialog extends ConsumerStatefulWidget {
  const _TaskSearchDialog();

  static const width = 480.0;
  static const resultLimit = 8;

  @override
  ConsumerState<_TaskSearchDialog> createState() => _TaskSearchDialogState();
}

class _TaskSearchDialogState extends ConsumerState<_TaskSearchDialog> {
  final _controller = TextEditingController();
  String _query = "";

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 제목 · 품목 · 거래처(이름·주소)에서 찾습니다.
  static bool _matches(WorkCase workCase, String query) {
    final needle = query.toLowerCase();
    return [
      workCase.title,
      workCase.itemName,
      workCase.senderName,
      workCase.sender,
    ].any((text) => text != null && text.toLowerCase().contains(needle));
  }

  void _open(WorkCase workCase) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(AppPaths.task(workCase.id));
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(workQueueViewModelProvider);
    final cases = queue.value?.items ?? const <WorkCase>[];
    final byId = {for (final workCase in cases) workCase.id: workCase};
    final searching = _query.isNotEmpty;
    final results = searching
        ? cases
              .where((workCase) => _matches(workCase, _query))
              .take(_TaskSearchDialog.resultLimit)
              .toList()
        : [for (final id in ref.watch(recentTasksProvider)) ?byId[id]];
    final empty = queue.isLoading && cases.isEmpty
        ? "업무를 불러오는 중이에요"
        : searching
        ? "'$_query'에 맞는 업무가 없어요"
        : "최근 본 업무가 없어요";

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _TaskSearchDialog.width,
            ),
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LdsRadius.dialog),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: _SearchField(
                      controller: _controller,
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                      onSubmitted: (_) {
                        if (results.isNotEmpty) _open(results.first);
                      },
                      onClear: () => setState(() {
                        _controller.clear();
                        _query = "";
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Text.rich(
                      TextSpan(
                        text: searching ? "검색 결과 " : "최근 본 업무 ",
                        children: [
                          TextSpan(
                            text: "${results.length}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              color: LdsColors.outline,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: LdsColors.label,
                      ),
                    ),
                  ),
                  if (results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      child: Text(
                        empty,
                        style: const TextStyle(
                          fontSize: 13,
                          color: LdsColors.muted,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                        children: [
                          for (final workCase in results)
                            _ResultRow(
                              workCase: workCase,
                              onTap: () => _open(workCase),
                            ),
                        ],
                      ),
                    ),
                  const Divider(height: 1, color: LdsColors.line),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      "Enter 첫 결과 열기     Esc 닫기",
                      style: TextStyle(fontSize: 12, color: LdsColors.outline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(LdsRadius.button),
      borderSide: const BorderSide(color: LdsColors.borderStrong),
    );
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 15, color: LdsColors.ink),
      decoration: InputDecoration(
        isDense: true,
        hintText: "업무, 거래처, 메일 검색",
        hintStyle: const TextStyle(fontSize: 15, color: LdsColors.outline),
        prefixIcon: const Icon(Icons.search, size: 20, color: LdsColors.label),
        suffixIcon: IconButton(
          tooltip: "검색어 지우기",
          icon: const Icon(Icons.close, size: 18, color: LdsColors.title),
          onPressed: onClear,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: LdsColors.title),
        ),
      ),
    );
  }
}

/// 문서 아이콘 + 제목 / '접수 yyyy.MM.dd HH:mm' + 상태 태그.
class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.workCase, required this.onTap});

  final WorkCase workCase;
  final VoidCallback onTap;

  (String, LdsTagTone) get _status {
    if (workCase.onHold) return ("보류", LdsTagTone.warning);
    return switch (taskGroupOf(workCase)) {
      TaskGroup.confirm => ("확인 필요", LdsTagTone.enabled),
      TaskGroup.running => ("진행 중", LdsTagTone.progressing),
      TaskGroup.complete => ("완료", LdsTagTone.success),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (label, tone) = _status;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: LdsColors.canvas,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: LdsColors.lineSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 18,
                color: LdsColors.label,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workCase.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: LdsColors.ink),
                  ),
                  Text(
                    "접수 ${formatSeoulDateTime(workCase.receivedAt)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: LdsColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            LdsTag(label, tone: tone),
          ],
        ),
      ),
    );
  }
}
