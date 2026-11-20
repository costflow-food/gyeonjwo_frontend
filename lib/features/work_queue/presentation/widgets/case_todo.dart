import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../app/app_paths.dart";
import "../../../../shared/formatters.dart";
import "../../../../shared/lds_colors.dart";
import "../../../../shared/widgets/lds/lds.dart";
import "../../../mail_draft/domain/mail_draft.dart";
import "../../../mail_draft/presentation/mail_draft_dialog.dart";
import "../../../purchase_review/domain/purchase_review.dart";
import "../../../review_progress/presentation/review_progress_view.dart";
import "../../../supplier/presentation/supplier_register_dialog.dart";
import "../../domain/case_stage.dart";
import "../../domain/work_case.dart";
import "../case_todo_data.dart";
import "../work_queue_view_model.dart";
import "candidate_selection.dart";
import "case_progress.dart";
import "case_step_status.dart";

/// 넓은 화면 Tasks 상세의 '지금 할 일' 상자 (Tasks 시안 상태별 문구).
///
/// 서버 단계 코드마다 상황 문장 · 세부 상태 라벨 · 설명 · 표 · 버튼을 고릅니다.
/// 표는 API에 자료가 있을 때만(메일 초안 API-16, 검토 카드 API-12, 받은 메일)
/// 그리고, 없으면 빼고 문장·버튼만 둡니다. 시스템 차례면 버튼 대신 '지금은
/// 하실 일이 없어요.'를 둡니다.
class CaseTodo extends ConsumerStatefulWidget {
  const CaseTodo({
    super.key,
    required this.workCase,
    required this.busy,
    required this.onAccept,
    required this.onStart,
    required this.onShowMail,
    this.onNext,
    this.error,
  });

  final WorkCase workCase;

  /// 수용·검토 시작을 보내는 중(상세가 처리합니다).
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onStart;

  /// '원문에서 확인': 받은 메일 카드를 펼쳐 보여 줍니다.
  final VoidCallback onShowMail;

  /// '나중에'·'검토 보류': 목록의 다음 업무로. null이면 두지 않습니다.
  final VoidCallback? onNext;

  /// 수용·검토 시작이 실패한 이유.
  final String? error;

  @override
  ConsumerState<CaseTodo> createState() => _CaseTodoState();
}

class _CaseTodoState extends ConsumerState<CaseTodo> {
  bool _busy = false;
  String? _error;

  /// API-07 재개(다시 추출 · 다시 시도 · 다시 검토).
  Future<void> _resume() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final viewModel = ref.read(workQueueViewModelProvider.notifier);
    // The panel rebuilds as the step changes; keep a context that stays.
    final navigator = Navigator.of(context, rootNavigator: true).context;
    try {
      await viewModel.resume(widget.workCase);
      if (mounted) setState(() => _busy = false);
      if (navigator.mounted) {
        await showReviewProgressDialog(
          navigator,
          caseId: widget.workCase.id,
          title: widget.workCase.title,
        );
      }
    } on WorkQueueFailure catch (failure) {
      if (!mounted) return;
      // A retryable failure may still have gone through; read it again.
      if (failure.caseChanged || failure.retryable) viewModel.refresh();
      setState(() {
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

  WorkCase get _case => widget.workCase;

  bool get _atCandidates =>
      _case.can(WorkCaseAction.selectCandidates) ||
      (_case.atCandidates &&
          _case.disabledMessage(WorkCaseAction.selectCandidates) != null);

  void _openDrafts() => showMailDraftDialog(context, caseId: _case.id);

  void _openReview() => context.go(AppPaths.review(_case.id));

  /// 주 버튼(주황, 최소 112).
  Widget _main(String label, VoidCallback? onPressed, {bool loading = false}) =>
      ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 112),
        child: LdsButton(label: label, onPressed: onPressed, loading: loading),
      );

  /// 보조 버튼(외곽선, 최소 112).
  Widget _sub(String label, VoidCallback? onPressed) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 112),
    child: LdsButton(
      label: label,
      variant: LdsButtonVariant.outlined,
      onPressed: onPressed,
    ),
  );

  /// 글자 버튼.
  Widget _text(String label, VoidCallback? onPressed) => LdsButton(
    label: label,
    variant: LdsButtonVariant.ghostNeutral,
    onPressed: onPressed,
  );

  /// 재개 버튼: 서버가 열었거나 막힌 이유가 있을 때만.
  Widget? _resumeButton({bool asText = false}) {
    final can = _case.can(WorkCaseAction.resume);
    if (!can && _case.disabledMessage(WorkCaseAction.resume) == null) {
      return null;
    }
    final label = _case.resumeReason.buttonLabel;
    final onPressed = can && !_busy ? _resume : null;
    return asText ? _text(label, onPressed) : _main(label, onPressed);
  }

  /// 버튼 아래 덧말: 막힌 이유 · 오류.
  Widget? _footer({List<String> captions = const []}) {
    final errors = [?widget.error, ?_error];
    if (captions.isEmpty && errors.isEmpty && !_busy) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: LdsColors.primary,
              ),
            ),
          for (final line in captions)
            Text(
              line,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: LdsColors.muted),
            ),
          for (final line in errors)
            Text(
              line,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: LdsColors.errorText),
            ),
        ],
      ),
    );
  }

  List<String> _resumeCaption() {
    if (_case.can(WorkCaseAction.resume)) return const [];
    return [?_case.disabledMessage(WorkCaseAction.resume)];
  }

  @override
  Widget build(BuildContext context) {
    final workCase = _case;
    final step = workCase.processingStep;
    // 멈춘 업무·오류는 API-03으로 사유를 다시 확인합니다.
    final progress = workCase.stopped || step == "FAILED"
        ? ref.watch(caseProgressProvider(workCase.id)).asData?.value
        : null;
    final hold = progress?.hold ?? workCase.hold;
    final stopCode = hold?.code ?? progress?.errorCode;
    final stage = caseStageOf(workCase, stopCode: stopCode);
    if (workCase.archived) return _completed();
    if (_atCandidates) {
      return CandidateSelection(workCase: workCase, onLater: widget.onNext);
    }
    if (workCase.notStarted ||
        step == "PENDING_START" ||
        step == "ACKNOWLEDGED") {
      return _received();
    }
    final reason = stopReasonMessage(hold, progress?.errorCode);
    return switch (step) {
      ProcessingStep.onHold || ProcessingStep.needsInfo =>
        (stage?.index ?? 0) <= 2
            ? _extractionHold(reason, stopCode)
            : _hold(stage!, reason, stopCode),
      "FAILED" => _failed(reason, stopCode),
      "SEND_UNKNOWN" => _sendUnknown(),
      "EXTRACTING" when (stage?.index ?? 2) == 2 => _extracting(),
      "EXTRACTING" => _collecting(
        tag: processingStepLabel(step, inputRevision: workCase.inputRevision),
      ),
      ProcessingStep.selectingCandidates => _findingCandidates(),
      ProcessingStep.candidates when (stage?.index ?? 3) == 4 => const TodoBox(
        title: "견적 요청 메일을 준비하고 있어요",
        tag: "견적 요청 준비 중",
        description: "고른 업체에 보낼 견적 요청 메일 초안을 만들고 있어요.",
      ),
      ProcessingStep.candidates => _findingCandidates(),
      "WAITING_APPROVAL" || "AWAITING_APPROVAL" => _approval(),
      "WAITING_REPLY" => _collecting(),
      "GENERATING_PLANS" ||
      "BUILDING_PLANS" ||
      "BUILDING_COUNTER_OFFER" => _reviewing(),
      "REVIEW_READY" => _pickPlan(),
      _ => TodoBox(
        title: processingStepLabel(step, inputRevision: workCase.inputRevision),
        description: workCase.stepMessage.isEmpty ? null : workCase.stepMessage,
        actions: [if (workCase.hasReviewCard) _main("검토 카드 보기", _openReview)],
      ),
    };
  }

  /// A 접수 대기: 받은 메일 표 + '수용하기'·'검토 시작'(결정 c).
  Widget _received() {
    final workCase = _case;
    final received = formatSeoulDateTime(workCase.receivedAt);
    final canAccept = workCase.can(WorkCaseAction.acceptIncrease);
    final canStart = workCase.can(WorkCaseAction.start);
    final busy = widget.busy;
    return TodoBox(
      title: "메일을 받았어요",
      meta: "대기",
      description: "원문을 확인하면 검토를 시작해요.",
      tableLabel: "받은 메일",
      rows: [
        TodoRow("보낸 사람", workCase.senderName ?? workCase.sender),
        TodoRow(
          "받은 시각",
          received.length > 5 ? received.substring(5) : received,
        ),
        TodoRow(
          "첨부",
          workCase.attachmentCount == 0 ? "없음" : "${workCase.attachmentCount}개",
        ),
      ],
      actions: [
        _sub("수용하기", canAccept && !busy ? widget.onAccept : null),
        _main("검토 시작", canStart && !busy ? widget.onStart : null),
      ],
      footer: _footer(
        captions: [
          if (!canAccept)
            workCase.disabledMessage(WorkCaseAction.acceptIncrease) ??
                "지금은 수용할 수 없습니다.",
          if (!canStart) ?workCase.disabledMessage(WorkCaseAction.start),
        ],
      ),
    );
  }

  /// B 정보 추출 중.
  Widget _extracting() => TodoBox(
    title: "메일에서 요청 내용을 읽고 있어요",
    description: "읽는 대로 아래에 채워져요. 지금은 하실 일이 없어요.",
    tableLabel: "읽은 요청 정보",
    rows: [if (_case.itemName case final item?) TodoRow("품목", item)],
  );

  /// C 추출 중 멈춤(빠진 항목 등): 원문에서 확인 · 다시 추출.
  Widget _extractionHold(String? reason, String? stopCode) => TodoBox(
    title: "메일에서 요청 내용을 읽고 있어요",
    meta: "보류",
    description: reason ?? "읽지 못한 항목이 있어요. 원문을 보고 확인해 주세요.",
    tableLabel: "읽은 요청 정보",
    rows: [if (_case.itemName case final item?) TodoRow("품목", item)],
    actions: [
      _sub("원문에서 확인", widget.onShowMail),
      if (_case.stopped && supplierMissingStopCodes.contains(stopCode))
        _sub("거래처 등록", () => showSupplierRegisterDialog(context)),
      ?_resumeButton(),
    ],
    footer: _footer(captions: _resumeCaption()),
  );

  /// H 보류: 사유 문구 + 기존 동작(거래처 등록 · 다시 추출) + 메일 초안 보기.
  Widget _hold(CaseStage stage, String? reason, String? stopCode) {
    final hasDrafts = caseHasMailDrafts(ref, _case);
    return TodoBox(
      title: stage.index >= 4 ? "회신 내용을 확인해야 해서 멈춰 있어요" : "확인이 필요해서 멈춰 있어요",
      meta: "보류",
      description:
          reason ??
          processingStepLabel(
            _case.processingStep,
            inputRevision: _case.inputRevision,
          ),
      actions: [
        if (hasDrafts) _sub("메일 초안 보기", _openDrafts),
        if (_case.stopped && supplierMissingStopCodes.contains(stopCode))
          _sub("거래처 등록", () => showSupplierRegisterDialog(context)),
        ?_resumeButton(),
      ],
      footer: _footer(captions: _resumeCaption()),
    );
  }

  /// D 후보 찾는 중.
  Widget _findingCandidates() => const TodoBox(
    title: "견적을 요청할 후보 업체를 찾고 있어요",
    description: "등록된 거래처 중 조건에 맞는 업체를 찾고 있어요.",
  );

  /// F 견적 요청 초안 승인.
  Widget _approval() {
    final drafts = ref.watch(caseMailDraftsProvider(_case.id)).asData?.value;
    final pending = drafts
        ?.where((draft) => draft.status == DraftStatus.draft)
        .toList();
    return TodoBox(
      title: "견적 요청 메일 초안을 확인해 주세요",
      tag: "초안 승인 대기",
      meta: pending == null || pending.isEmpty ? null : "초안 ${pending.length}건",
      description: "자동 발송이 꺼져 있어 확인한 초안만 보내요. 내용을 보고 보내 주세요.",
      tableLabel: pending == null ? null : "보낼 초안 ${pending.length}건",
      rows: [
        for (final draft in pending ?? const <MailDraft>[])
          TodoRow(
            (draft.supplierName?.trim().isNotEmpty ?? false)
                ? draft.supplierName!.trim()
                : "수신인",
            draft.recipient,
            note: draft.status.label,
          ),
      ],
      actions: [_main("초안 확인", _openDrafts)],
      footer: _footer(),
    );
  }

  /// G 회신 수집(와 연결된 회신을 읽는 중).
  Widget _collecting({String tag = "견적 수집 중"}) {
    final replies = _case.replySummary;
    final visible = replies != null && replies.visible;
    return TodoBox(
      title: "거래처 회신을 모으고 있어요",
      tag: tag,
      meta: visible ? "${replies.requested}곳 중 ${replies.responded}곳 회신" : null,
      description: visible
          ? "견적 요청 ${replies.requested}건을 보냈어요. 회신이 오면 자동으로 이어서 검토해요."
          : "견적 요청을 보냈어요. 회신이 오면 자동으로 이어서 검토해요.",
      leading: const _Idle(),
      actions: [
        if (caseHasMailDrafts(ref, _case)) _text("메일 초안 보기", _openDrafts),
      ],
    );
  }

  /// I 회신 검토 중(구매안 계산 · 역제안 준비).
  Widget _reviewing() {
    final replies = _case.replySummary;
    final responded = replies != null && replies.visible
        ? replies.responded
        : null;
    return TodoBox(
      title: "회신을 검토하고 있어요",
      tag: _case.processingStep == "BUILDING_COUNTER_OFFER"
          ? "역제안 준비 중"
          : "회신 검토 중",
      meta: responded == null ? null : "회신 $responded곳",
      description: responded == null
          ? "받은 회신으로 구매안을 계산하고, 역제안과 추가 확인이 필요한지 보고 있어요."
          : "회신 $responded곳으로 구매안을 계산하고, 역제안과 추가 확인이 필요한지 보고 있어요.",
    );
  }

  /// J 구매안 선택: 검토 카드의 구매안 비교 표.
  Widget _pickPlan() {
    final card = ref.watch(caseReviewCardProvider(_case.id)).asData?.value;
    final plans = card?.plans ?? const <ResponsePlan>[];
    final lowest = _lowest(plans.where((plan) => plan.valid));
    final cheapest = _lowestAmount(plans);
    return TodoBox(
      title: "구매안을 골라 주세요",
      tag: "구매안 선택 대기",
      meta: plans.isEmpty ? null : "구매안 ${plans.length}개",
      description: lowest != null
          ? "필수 조건을 통과한 안 중 총액이 가장 낮은 안은 「${lowest.typeLabel}」이에요. 자동으로 고르지 않아요."
          : card?.outcome.message ?? "검토 카드에서 구매안을 비교해 골라 주세요. 자동으로 고르지 않아요.",
      tableLabel: "구매안 비교",
      rows: [
        for (final plan in _byAmount(plans))
          TodoRow(
            plan.typeLabel,
            _won(plan.totalAmount),
            note: _diffNote(plan, cheapest),
          ),
      ],
      actions: [
        ?_resumeButton(asText: true),
        if (widget.onNext case final onNext?) _text("검토 보류", onNext),
        _main("검토 카드 보기", _openReview),
      ],
      footer: _footer(captions: _resumeCaption()),
    );
  }

  /// Q 완료(구매안 확정 · 보관).
  Widget _completed() {
    final card = ref.watch(caseReviewCardProvider(_case.id)).asData?.value;
    final decision = card?.decision;
    final plan = card?.plan(decision?.planId);
    final decidedAt = decision?.decidedAt;
    final at = decidedAt == null ? null : formatSeoulDateTime(decidedAt);
    return TodoBox(
      title: "구매안을 확정했어요",
      meta: at == null ? "완료" : "${at.length > 5 ? at.substring(5) : at} 확정",
      description: plan == null
          ? "확정 내용은 검토 카드에서 볼 수 있어요."
          : "「${plan.typeLabel}」으로 확정했어요. 확정 내용은 검토 카드에서 볼 수 있어요.",
      tableLabel: plan == null ? null : "확정 결과",
      rows: [
        if (plan != null) ...[
          TodoRow(
            "확정안",
            plan.typeLabel,
            note: [
              for (final allocation in plan.allocations)
                "${allocation.supplierName} ${formatDecimal(allocation.quantity)}"
                    "${allocation.unit ?? ""}",
            ].join(", "),
          ),
          TodoRow("총액", _won(plan.totalAmount)),
        ],
      ],
      actions: [?_resumeButton(asText: true), _main("검토 카드 보기", _openReview)],
      footer: _footer(captions: _resumeCaption()),
    );
  }

  /// R 처리 오류: 발송 결과 표(초안이 있으면) + 메일 초안 보기 · 다시 시도.
  Widget _failed(String? reason, String? stopCode) {
    final drafts =
        ref.watch(caseMailDraftsProvider(_case.id)).asData?.value ??
        const <MailDraft>[];
    final sendFailed = drafts.any(
      (draft) => draft.status == DraftStatus.failed,
    );
    final results = [
      for (final draft in drafts)
        if (draft.status != DraftStatus.draft &&
            draft.status != DraftStatus.withdrawn)
          draft,
    ];
    return TodoBox(
      title: sendFailed
          ? "메일 발송에 실패했어요"
          : stopCode == "RFQ_PREPARATION_FAILED"
          ? "견적 요청을 준비하지 못했어요"
          : "처리 중 오류가 났어요",
      meta: "오류",
      description: reason ?? _case.resumeReason.help,
      tableLabel: results.isEmpty ? null : "발송 결과",
      rows: [
        for (final draft in results)
          TodoRow(
            (draft.supplierName?.trim().isNotEmpty ?? false)
                ? draft.supplierName!.trim()
                : "수신인",
            draft.recipient,
            note: draft.status.label,
            warn: draft.status == DraftStatus.failed,
          ),
      ],
      actions: [
        if (drafts.isNotEmpty || caseHasMailDrafts(ref, _case))
          _sub("메일 초안 보기", _openDrafts),
        ?_resumeButton(),
      ],
      footer: _footer(captions: _resumeCaption()),
    );
  }

  /// 발송 결과를 모름(SEND_UNKNOWN): 초안 화면에서 결과를 확인합니다.
  Widget _sendUnknown() {
    final drafts =
        ref.watch(caseMailDraftsProvider(_case.id)).asData?.value ??
        const <MailDraft>[];
    return TodoBox(
      title: "메일 발송 결과를 확인해 주세요",
      meta: "오류",
      description: "보낸 메일이 실제로 나갔는지 확인하지 못했어요. 메일 초안에서 결과를 확인해 주세요.",
      tableLabel: drafts.isEmpty ? null : "발송 결과",
      rows: [
        for (final draft in drafts)
          TodoRow(
            (draft.supplierName?.trim().isNotEmpty ?? false)
                ? draft.supplierName!.trim()
                : "수신인",
            draft.recipient,
            note: draft.status.label,
            warn: draft.status == DraftStatus.failed,
          ),
      ],
      actions: [_main("메일 초안 보기", _openDrafts)],
      footer: _footer(),
    );
  }

  static num? _amount(ResponsePlan plan) =>
      plan.totalAmount == null ? null : num.tryParse(plan.totalAmount!);

  static ResponsePlan? _lowest(Iterable<ResponsePlan> plans) {
    ResponsePlan? best;
    for (final plan in plans) {
      final amount = _amount(plan);
      if (amount == null) continue;
      if (best == null || amount < _amount(best)!) best = plan;
    }
    return best;
  }

  static num? _lowestAmount(List<ResponsePlan> plans) {
    final lowest = _lowest(plans);
    return lowest == null ? null : _amount(lowest);
  }

  /// 총액이 낮은 안부터(총액 미확인은 뒤).
  static List<ResponsePlan> _byAmount(List<ResponsePlan> plans) =>
      [...plans]..sort((a, b) {
        final x = _amount(a), y = _amount(b);
        if (x == null) return y == null ? 0 : 1;
        if (y == null) return -1;
        return x.compareTo(y);
      });

  static String _diffNote(ResponsePlan plan, num? cheapest) {
    final amount = _amount(plan);
    if (amount == null || cheapest == null) return "";
    if (amount == cheapest) return "최저 총액";
    return "+${formatNumber((amount - cheapest).round())}원";
  }

  static String _won(String? amount) {
    if (amount == null) return "미확인";
    final value = num.tryParse(amount);
    return value == null ? amount : "${formatNumber(value.round())}원";
  }
}

/// 버튼 줄 왼쪽의 '할 일 없음' 글자.
class _Idle extends StatelessWidget {
  const _Idle();

  @override
  Widget build(BuildContext context) => const Text(
    TodoBox.idleText,
    style: TextStyle(fontSize: 13, letterSpacing: -.3, color: LdsColors.muted),
  );
}
