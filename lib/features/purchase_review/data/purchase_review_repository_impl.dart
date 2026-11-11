import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/idempotency_key.dart";
import "../../../shared/network/api_request.dart";
import "../domain/purchase_review.dart";
import "../domain/purchase_review_repository.dart";
import "purchase_review_data_source.dart";

part "purchase_review_repository_impl.g.dart";

@Riverpod(keepAlive: true)
PurchaseReviewRepository purchaseReviewRepository(Ref ref) =>
    PurchaseReviewRepositoryImpl(ref.watch(purchaseReviewDataSourceProvider));

class PurchaseReviewRepositoryImpl implements PurchaseReviewRepository {
  PurchaseReviewRepositoryImpl(this._dataSource);

  final PurchaseReviewDataSource _dataSource;
  final _keys = IdempotencyKeys();

  @override
  Future<PurchaseReview> getReview(String caseId) => _guard(() async {
    final responses = await Future.wait([
      _dataSource.fetchReviewCard(caseId),
      _dataSource.fetchQuotes(caseId),
    ]);
    final card = _card(responses[0]["data"] as Map<String, dynamic>);
    if (card.caseId != caseId) throw const FormatException();
    final quotes = (responses[1]["data"] as Map<String, dynamic>)["items"] as List;
    return PurchaseReview(
      card: card,
      quotes: [for (final item in quotes) _quote(item as Map<String, dynamic>)],
    );
  });

  @override
  Future<List<QuoteVersion>> getQuotes(String caseId) => _guard(() async {
    final response = await _dataSource.fetchQuotes(caseId);
    final quotes = (response["data"] as Map<String, dynamic>)["items"] as List;
    return [for (final item in quotes) _quote(item as Map<String, dynamic>)];
  });

  @override
  Future<void> selectPlan(ReviewCard card, ResponsePlan plan) => _decide(card, {
    "decision": ReviewAction.selectPlan,
    "plan_id": plan.planId,
  });

  @override
  Future<void> hold(ReviewCard card, String note) =>
      _decide(card, {"decision": ReviewAction.hold, "note": note});

  @override
  Future<void> confirmReview(ReviewCard card) =>
      _decide(card, {"decision": ReviewAction.confirmReview});

  /// 같은 판단을 다시 보내면 같은 키로 처음 접수 결과를 확인합니다.
  Future<void> _decide(ReviewCard card, Map<String, Object?> decision) {
    final body = <String, Object?>{
      ...decision,
      "expected_revision": card.inputRevision,
      "review_revision": card.reviewRevision,
    };
    return _keys.run(
      "decision:${card.caseId}:${decision["decision"]}",
      body,
      (key) => _guard(
        () => _dataSource.submitDecision(card.caseId, body, idempotencyKey: key),
      ),
      serverCode: (error) => error is PurchaseReviewFailure && !error.retryable
          ? error.code
          : null,
    );
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException catch (error) {
      throw PurchaseReviewFailure(
        error.code,
        error.message,
        unknownOutcome: error.unknownOutcome,
        retryable: error.retryable,
      );
    } on PurchaseReviewFailure {
      rethrow;
    } catch (_) {
      // A shape this screen cannot read; never show half a card.
      throw const PurchaseReviewFailure(
        "INVALID_RESPONSE",
        "서버 응답을 확인하지 못했습니다.",
      );
    }
  }

  /// 서버 Decimal. 문자열이 계약이지만 숫자로 와도 그대로 읽습니다.
  static String? _decimal(Object? json) => switch (json) {
    null => null,
    String value => value,
    num value => value.toString(),
    _ => throw const FormatException(),
  };

  static List<String> _strings(Object? json) =>
      json is List ? [for (final item in json) item as String] : const [];

  static ReviewCard _card(Map<String, dynamic> json) {
    final counter = json["counter_offer"];
    final decision = json["decision"];
    return ReviewCard(
      caseId: json["case_id"] as String,
      reviewRevision: json["review_revision"] as int,
      inputRevision: json["input_revision"] as int,
      isStale: json["is_stale"] as bool? ?? false,
      outcome: ReviewOutcome.from(json["review_outcome"] as String?),
      createdAt: json["created_at"] as String?,
      sourceQuoteIds: _strings(json["source_quote_ids"]),
      plans: [
        for (final item in json["plans"] as List? ?? const [])
          _plan(item as Map<String, dynamic>),
      ],
      counterOffer: counter is Map<String, dynamic> ? _counter(counter) : null,
      questions: [
        for (final item in json["questions"] as List? ?? const [])
          _question(item as Map<String, dynamic>),
      ],
      unresolved: _strings(json["unresolved"]),
      decision: decision is Map<String, dynamic>
          ? ReviewDecision(
              decision: decision["decision"] as String,
              planId: decision["plan_id"] as String?,
              note: decision["note"] as String?,
              decidedAt: decision["decided_at"] as String?,
            )
          : null,
      allowedActions: _strings(json["allowed_actions"]),
      disabledActions: [
        for (final item in json["disabled_actions"] as List? ?? const [])
          DisabledReviewAction(
            action: (item as Map<String, dynamic>)["action"] as String,
            reasonCode: item["reason_code"] as String,
            message: item["message"] as String,
          ),
      ],
    );
  }

  static ResponsePlan _plan(Map<String, dynamic> json) => ResponsePlan(
    planId: json["plan_id"] as String?,
    planType: json["plan_type"] as String,
    validationStatus: json["validation_status"] as String,
    totalAmount: _decimal(json["total_amount"]),
    currency: json["currency"] as String? ?? "KRW",
    allocations: [
      for (final item in json["allocations"] as List)
        PlanAllocation(
          supplierId: (item as Map<String, dynamic>)["supplier_id"] as String,
          supplierName: item["supplier_name"] as String? ?? "이름 미확인 업체",
          quoteId: (item["quote_id"] ?? item["quote_version_id"]) as String?,
          quantity: _decimal(item["quantity"])!,
          unit: item["unit"] as String?,
          unitPrice: _decimal(item["unit_price"]),
        ),
    ],
    conditions: _strings(json["conditions"]),
    adjustments: _strings(json["adjustments"]),
    reason: json["reason"] as String?,
  );

  static CounterOffer _counter(Map<String, dynamic> json) {
    final target = json["target"];
    final reference = json["reference"];
    return CounterOffer(
      status: json["status"] as String,
      reason: json["reason"] as String?,
      draftIds: _strings(json["draft_ids"]),
      target: target is Map<String, dynamic>
          ? CounterOfferTarget(
              supplierId: target["supplier_id"] as String,
              supplierName: target["supplier_name"] as String? ?? "기존 업체",
              targetUnitPrice: target["target_unit_price"] as String,
              conditions: _strings(target["conditions"]),
            )
          : null,
      reference: reference is Map<String, dynamic>
          ? CounterOfferReference(
              status: reference["status"] as String,
              unit: reference["unit"] as String?,
              requestedUnitPrice: reference["requested_unit_price"] as String?,
              previousUnitPrice: reference["previous_unit_price"] as String?,
              ceilingUnitPrice: reference["ceiling_unit_price"] as String?,
              alternativeTotal: reference["alternative_total"] as String?,
              allowedRange: _strings(reference["allowed_range"]),
            )
          : null,
    );
  }

  static ReviewQuestion _question(Map<String, dynamic> json) => ReviewQuestion(
    supplierName: json["supplier_name"] as String? ?? "업체",
    field: json["field"] as String,
    priority: json["priority"] as String,
    reason: json["reason"] as String,
    breakEvenAmount: json["break_even_amount"] as String?,
    formula: json["formula"] as String?,
  );

  static QuoteVersion _quote(Map<String, dynamic> json) {
    final moq = json["moq"];
    return QuoteVersion(
      quoteId: json["quote_id"] as String,
      versionNo: json["version_no"] as int,
      supplierId: json["supplier_id"] as String,
      supplierName: json["supplier_name"] as String? ?? "이름 미확인 업체",
      isIncumbent: json["is_incumbent"] as bool? ?? false,
      extractionStatus: json["extraction_status"] as String? ?? "",
      unitPrice: json["unit_price"] as String?,
      unit: json["unit"] as String?,
      currency: json["currency"] as String? ?? "KRW",
      taxBasis: json["tax_basis"] as String?,
      availableQuantity: json["available_quantity"] as String?,
      moq: moq is Map<String, dynamic> && moq["quantity"] != null
          ? "${moq["quantity"]} ${moq["unit"] ?? ""}".trim()
          : null,
      effectiveFrom: json["effective_from"] as String?,
      validUntil: json["valid_until"] as String?,
      costs: [
        for (final item in json["costs"] as List? ?? const [])
          QuoteCost(
            costType: (item as Map<String, dynamic>)["cost_type"] as String,
            amount: item["amount"] as String?,
            includedInPrice: item["included_in_price"] as bool?,
            sourceText: item["source_text"] as String?,
          ),
      ],
      checks: [
        for (final item in json["checks"] as List? ?? const [])
          QuoteCheck(
            field: (item as Map<String, dynamic>)["field"] as String,
            state: item["state"] as String,
            value: item["value"] as String?,
          ),
      ],
      itemNotes: _strings(json["item_notes"]),
      evidence: [
        for (final item in json["evidence"] as List? ?? const [])
          QuoteEvidence(
            field: (item as Map<String, dynamic>)["field"] as String,
            mailId: item["mail_id"] as String,
            rawValue: item["raw_value"] as String?,
            location: item["location"] as String?,
          ),
      ],
    );
  }
}
