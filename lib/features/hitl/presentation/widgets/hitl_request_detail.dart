import 'package:flutter/material.dart';

import '../../../../shared/lds_colors.dart';
import '../../../../shared/widgets/lds/lds.dart';
import '../../domain/hitl_request.dart';

class HitlRequestDetail extends StatefulWidget {
  const HitlRequestDetail({
    super.key,
    required this.request,
    required this.onDecide,
    this.onBack,
  });
  final HitlRequest request;
  final bool Function(HitlStatus, String, String) onDecide;
  final VoidCallback? onBack;

  @override
  State<HitlRequestDetail> createState() => _HitlRequestDetailState();
}

class _HitlRequestDetailState extends State<HitlRequestDetail> {
  late final TextEditingController _value;
  late final TextEditingController _note;
  String? _error;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _value = TextEditingController(text: widget.request.value);
    _note = TextEditingController(text: widget.request.note);
  }

  @override
  void dispose() {
    _value.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _decide(HitlStatus next) async {
    if (_confirming) return;
    if (_value.text.trim().isEmpty ||
        ((next == HitlStatus.held || next == HitlStatus.returned) &&
            _note.text.trim().isEmpty)) {
      setState(
        () => _error = _value.text.trim().isEmpty
            ? '확인한 값을 입력해 주세요.'
            : '보류 또는 수정 요청의 사유를 입력해 주세요.',
      );
      return;
    }
    setState(() {
      _confirming = true;
      _error = null;
    });
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => LdsDialog(
        title: '${next.label} 처리할까요?',
        subtitle: widget.request.title,
        actions: [
          LdsButton(
            label: '취소',
            variant: LdsButtonVariant.outlinedNeutral,
            onPressed: () => Navigator.pop(context, false),
          ),
          LdsButton(
            label: '${next.label} 기록',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '시연 요청에만 결정이 기록됩니다. 실제 메일 발송이나 업무 처리는 실행되지 않습니다.',
              style: TextStyle(height: 1.7),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.request.valueLabel}\n${_value.text}',
              style: const TextStyle(height: 1.7),
            ),
            if (_note.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('검토 의견\n${_note.text}', style: const TextStyle(height: 1.7)),
            ],
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (accepted == true) {
      final saved = widget.onDecide(next, _note.text, _value.text);
      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시연 검토 결과를 기록했습니다. 실제 업무는 실행되지 않았습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final editable = request.status.actionable;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('요청 목록으로'),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                request.id,
                style: const TextStyle(color: LdsColors.muted, fontSize: 12),
              ),
              Text(
                request.kind.label,
                style: const TextStyle(color: LdsColors.label, fontSize: 12),
              ),
              Text(
                request.status.label,
                style: const TextStyle(
                  color: LdsColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${request.supplier} · ${request.item} · 합성 시연 요청',
            style: const TextStyle(color: LdsColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _Section(
            title: '왜 확인이 필요한가요?',
            child: Text(request.reason, style: const TextStyle(height: 1.7)),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'AI 제안',
            child: Text(request.proposal, style: const TextStyle(height: 1.7)),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '판단 근거',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in request.facts.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        SizedBox(
                          width: 108,
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: LdsColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => LdsDialog(
                        title: '원문·근거 보기',
                        subtitle: '합성 시연 자료',
                        child: SelectableText(
                          request.source,
                          style: const TextStyle(height: 1.8),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text('시연 원문 보기'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '담당자 확인',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LdsTextField(
                  controller: _value,
                  label: request.valueLabel,
                  maxLines: request.kind == HitlKind.send ? 5 : 2,
                  enabled: editable,
                ),
                const SizedBox(height: 16),
                LdsTextField(
                  controller: _note,
                  label: '검토 의견',
                  hintText: '보류·수정 요청 시 사유를 남겨 주세요.',
                  maxLines: 3,
                  enabled: editable,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: LdsColors.error),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '승인 후 다음 단계',
            child: Text(request.effect, style: const TextStyle(height: 1.7)),
          ),
          const SizedBox(height: 24),
          if (editable)
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                LdsButton(
                  label: '보류',
                  variant: LdsButtonVariant.outlinedNeutral,
                  onPressed: _confirming
                      ? null
                      : () => _decide(HitlStatus.held),
                ),
                LdsButton(
                  label: '수정 요청',
                  variant: LdsButtonVariant.outlinedNeutral,
                  onPressed: _confirming
                      ? null
                      : () => _decide(HitlStatus.returned),
                ),
                LdsButton(
                  label: '승인',
                  onPressed: _confirming
                      ? null
                      : () => _decide(HitlStatus.approved),
                ),
              ],
            )
          else
            const Text(
              '검토 결과가 기록된 요청입니다. 아래 이력에서 확인할 수 있습니다.',
              style: TextStyle(color: LdsColors.muted, height: 1.7),
            ),
          const SizedBox(height: 24),
          _Section(
            title: '처리 이력',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final event in request.history)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• $event',
                      style: const TextStyle(fontSize: 13, height: 1.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => LdsPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}
