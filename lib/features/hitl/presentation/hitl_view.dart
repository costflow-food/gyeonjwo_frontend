import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_paths.dart';
import '../../../shared/lds_colors.dart';
import '../../../shared/widgets/lds/lds.dart';
import '../../../shared/widgets/workspace_shell.dart';
import '../domain/hitl_request.dart';
import 'hitl_view_model.dart';
import 'widgets/hitl_request_detail.dart';
import 'widgets/hitl_request_list.dart';

class HitlView extends ConsumerStatefulWidget {
  const HitlView({super.key, this.requestId});
  final String? requestId;
  @override
  ConsumerState<HitlView> createState() => _HitlViewState();
}

class _HitlViewState extends ConsumerState<HitlView> {
  final _search = TextEditingController();
  HitlStatus? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _select(String id) => context.go(
    Uri(path: AppPaths.hitl, queryParameters: {'request': id}).toString(),
  );

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(hitlViewModelProvider);
    final query = _search.text.trim().toLowerCase();
    final visible = requests
        .where(
          (request) =>
              (_filter == null || request.status == _filter) &&
              '${request.title} ${request.supplier} ${request.item} ${request.id}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    final waiting = requests
        .where((request) => request.status == HitlStatus.waiting)
        .length;
    return WorkspaceShell(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '담당자 검토 요청',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI가 판단을 기다리는 요청을 확인하고 결정하세요. 검토 대기 $waiting건',
                  style: const TextStyle(
                    fontSize: 13,
                    color: LdsColors.muted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '시연 모드 · 합성 요청이며 실제 업무·메일과 연결되지 않습니다. 결정은 새로고침 시 초기화됩니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: LdsColors.label,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: LdsColors.line),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1000;
                final chosen = widget.requestId == null
                    ? (wide ? visible.firstOrNull : null)
                    : requests
                          .where((request) => request.id == widget.requestId)
                          .firstOrNull;
                final list = Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          LdsTextField(
                            controller: _search,
                            hintText: '거래처·품목·요청 검색',
                            prefixIcon: Icons.search,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ChoiceChip(
                                label: Text('전체 ${requests.length}'),
                                selected: _filter == null,
                                onSelected: (_) =>
                                    setState(() => _filter = null),
                              ),
                              for (final status in HitlStatus.values)
                                ChoiceChip(
                                  label: Text(
                                    '${status.label} ${requests.where((r) => r.status == status).length}',
                                  ),
                                  selected: _filter == status,
                                  onSelected: (_) =>
                                      setState(() => _filter = status),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: HitlRequestList(
                        requests: visible,
                        selectedId: chosen?.id,
                        onSelect: _select,
                      ),
                    ),
                  ],
                );
                Widget detail() => chosen == null
                    ? Center(
                        child: Text(
                          widget.requestId == null
                              ? '왼쪽에서 검토할 요청을 선택해 주세요.'
                              : '요청을 찾을 수 없습니다. 목록에서 다시 선택해 주세요.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : HitlRequestDetail(
                        key: ValueKey(chosen.id),
                        request: chosen,
                        onBack: wide ? null : () => context.go(AppPaths.hitl),
                        onDecide: (status, note, value) => ref
                            .read(hitlViewModelProvider.notifier)
                            .decide(chosen.id, status, note, value),
                      );
                if (!wide) {
                  if (widget.requestId == null) return list;
                  if (chosen == null) {
                    return Column(
                      children: [
                        TextButton(
                          onPressed: () => context.go(AppPaths.hitl),
                          child: const Text('요청 목록으로'),
                        ),
                        Expanded(child: detail()),
                      ],
                    );
                  }
                  return detail();
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 340,
                      child: ColoredBox(color: LdsColors.lineSoft, child: list),
                    ),
                    const VerticalDivider(width: 1, color: LdsColors.line),
                    Expanded(child: detail()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
