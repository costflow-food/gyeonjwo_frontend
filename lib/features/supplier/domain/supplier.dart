/// Temporary app models for supplier screens; independent of the DB schema.
///
/// Based on 06 suppliers/supplier_items and 08 API-29~31. Money and quantities
/// keep the server Decimal strings; null is shown as "미확인".
library;

/// suppliers.source_type. Web candidates (crawled_suppliers) are separate.
enum SupplierSourceType {
  registered("REGISTERED", "직접 등록"),
  verifiedWeb("VERIFIED_WEB", "웹 확인");

  const SupplierSourceType(this.code, this.label);
  final String code;
  final String label;

  static SupplierSourceType fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => throw SupplierFailure(
      "UNKNOWN_SOURCE_TYPE",
      "알 수 없는 거래처 등록 경로입니다: $code",
    ),
  );
}

/// Unconfirmed is not the same as not met.
enum CertificationStatus {
  confirmed("CONFIRMED", "확인됨"),
  unconfirmed("UNCONFIRMED", "미확인"),
  notMet("NOT_MET", "불충족");

  const CertificationStatus(this.code, this.label);
  final String code;
  final String label;

  static CertificationStatus fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => CertificationStatus.unconfirmed,
  );
}

class SupplierContact {
  const SupplierContact({this.name, this.phone});
  final String? name;
  final String? phone;
}

/// The source and time the screen needs from evidence_jsonb fields.
class SourceEvidence {
  const SourceEvidence({
    required this.label,
    this.checkedAt,
    this.memo,
    this.sourceMailId,
  });
  final String label;

  /// UTC ISO 8601.
  final String? checkedAt;
  final String? memo;

  /// Original mail, opened in SCR-004 when present.
  final String? sourceMailId;
}

/// One API-29 list row.
class SupplierSummary {
  const SupplierSummary({
    required this.id,
    required this.name,
    required this.sourceType,
    required this.itemNames,
    this.contactEmail,
    this.location,
  });

  final String id;
  final String name;
  final SupplierSourceType sourceType;
  final List<String> itemNames;
  final String? contactEmail;
  final String? location;
}

class SupplierPage {
  const SupplierPage({
    required this.items,
    required this.total,
    this.nextCursor,
  });

  final List<SupplierSummary> items;
  final int total;
  final String? nextCursor;
}

class Certification {
  const Certification({
    required this.name,
    required this.status,
    this.validUntil,
  });

  final String name;
  final CertificationStatus status;

  /// YYYY-MM-DD.
  final String? validUntil;
}

/// Reference price from a mail quote; not an actual purchase price.
class ReferenceQuote {
  const ReferenceQuote({
    required this.unitPrice,
    required this.unit,
    this.effectiveFrom,
  });

  final String unitPrice;
  final String unit;
  final String? effectiveFrom;
}

/// Last purchase confirmed by a receipt or similar evidence.
class LastPurchase {
  const LastPurchase({
    required this.unitPrice,
    required this.unit,
    required this.transactionDate,
  });

  final String unitPrice;
  final String unit;
  final String transactionDate;
}

class SupplierItem {
  const SupplierItem({
    required this.id,
    required this.itemName,
    required this.certifications,
    this.specification,
    this.unit,
    this.unitsPerBox,
    this.weightPerBox,
    this.origin,
    this.notes,
    this.notesEvidence,
    this.latestReferenceQuote,
    this.lastPurchase,
  });

  final String id;
  final String itemName;
  final String? specification;
  final String? unit;
  final String? unitsPerBox;
  final String? weightPerBox;
  final String? origin;
  final List<Certification> certifications;

  /// Free-text memo; never an exclusion or scoring rule.
  final String? notes;
  final SourceEvidence? notesEvidence;
  final ReferenceQuote? latestReferenceQuote;
  final LastPurchase? lastPurchase;
}

/// API-30 detail.
class SupplierDetail {
  const SupplierDetail({
    required this.id,
    required this.name,
    required this.sourceType,
    required this.contact,
    required this.items,
    this.businessRegistrationNo,
    this.contactEmail,
    this.location,
    this.evidence,
  });

  final String id;
  final String name;
  final SupplierSourceType sourceType;
  final String? businessRegistrationNo;
  final String? contactEmail;
  final SupplierContact contact;
  final String? location;
  final SourceEvidence? evidence;
  final List<SupplierItem> items;
}

/// Item entered on the register form. The server sets standardized_item_key.
class SupplierItemDraft {
  const SupplierItemDraft({
    required this.itemName,
    this.specification,
    this.unit,
    this.unitsPerBox,
    this.weightPerBox,
    this.origin,
    this.certifications = const [],
    this.notes,
  });

  final String itemName;
  final String? specification;
  final String? unit;
  final String? unitsPerBox;
  final String? weightPerBox;
  final String? origin;
  final List<String> certifications;
  final String? notes;

  Map<String, Object?> toJson() => {
    "item_name": itemName,
    "specification": specification,
    "unit": unit,
    "units_per_box": unitsPerBox,
    "weight_per_box": weightPerBox,
    "origin": origin,
    "certifications": certifications,
    "notes": notes,
  };
}

/// Register request. The server records source_type as REGISTERED.
class SupplierDraft {
  const SupplierDraft({
    required this.name,
    this.businessRegistrationNo,
    this.contactEmail,
    this.contactName,
    this.contactPhone,
    this.location,
    this.evidenceMemo,
    this.items = const [],
  });

  final String name;
  final String? businessRegistrationNo;
  final String? contactEmail;
  final String? contactName;
  final String? contactPhone;
  final String? location;
  final String? evidenceMemo;
  final List<SupplierItemDraft> items;

  Map<String, Object?> toJson() => {
    "name": name,
    "business_registration_no": businessRegistrationNo,
    "contact_email": contactEmail,
    "contact": {"name": contactName, "phone": contactPhone},
    "location": location,
    "evidence": {"memo": evidenceMemo},
    "items": [for (final item in items) item.toJson()],
  };
}

/// One API-31 row. Quotes and purchases live in separate lists.
class PriceRecord {
  const PriceRecord({
    required this.unitPrice,
    required this.unit,
    required this.sourceLabel,
    this.date,
    this.quantity,
    this.conditions,
    this.sourceMailId,
  });

  final String unitPrice;
  final String unit;

  /// Quote effective date or purchase date (YYYY-MM-DD); null if unknown.
  final String? date;

  /// Purchased quantity, or null.
  final String? quantity;

  /// Summary of spec, quantity tier, delivery and other terms.
  final String? conditions;
  final String sourceLabel;
  final String? sourceMailId;
}

class PriceHistory {
  const PriceHistory({
    required this.referenceQuotes,
    required this.actualPurchases,
  });

  /// Mail quotes, newest effective date first.
  final List<PriceRecord> referenceQuotes;

  /// Actual purchases, newest transaction first.
  final List<PriceRecord> actualPurchases;

  PriceRecord? get latestReferenceQuote => referenceQuotes.firstOrNull;
  PriceRecord? get lastActualPurchase => actualPurchases.firstOrNull;
}

/// `code` and `message` from the 08 error response.
class SupplierFailure implements Exception {
  const SupplierFailure(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => "SupplierFailure($code)";
}
