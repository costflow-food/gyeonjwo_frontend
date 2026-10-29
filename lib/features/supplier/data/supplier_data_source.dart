import "dart:convert";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "supplier_preview_data.dart";

part "supplier_data_source.g.dart";

@Riverpod(keepAlive: true)
SupplierDataSource supplierDataSource(Ref ref) {
  return PreviewSupplierDataSource();
}

/// Returns decoded JSON in the 08 API shape (`data`, `meta`).
///
/// Reads: API-29 `GET /suppliers`, API-30 `GET /suppliers/{supplier_id}`,
/// API-31 `GET /supplier-items/{supplier_item_id}/price-history`.
/// Create: `POST /suppliers`, a proposed contract not yet in 08; the server
/// stores it with service_role.
/// Failures use the 08 error shape via [SupplierApiException].
abstract interface class SupplierDataSource {
  Future<Map<String, dynamic>> fetchSuppliers({
    required String query,
    String? cursor,
    int limit = 25,
  });

  Future<Map<String, dynamic>> fetchSupplier(String supplierId);

  Future<Map<String, dynamic>> fetchPriceHistory(String supplierItemId);

  Future<Map<String, dynamic>> createSupplier(
    Map<String, Object?> body, {
    required String idempotencyKey,
  });
}

class SupplierApiException implements Exception {
  const SupplierApiException(this.statusCode, this.body);
  final int statusCode;
  final Map<String, dynamic> body;
}

/// In-memory responses until the API is ready. Registered suppliers last
/// until the browser reloads.
class PreviewSupplierDataSource implements SupplierDataSource {
  PreviewSupplierDataSource({
    this.latency = const Duration(milliseconds: 250),
  }) : _details = [
         for (final detail in supplierPreviewDetails)
           _copy(detail) as Map<String, dynamic>,
       ];

  final Duration latency;
  final List<Map<String, dynamic>> _details;
  final Map<String, (String, Map<String, dynamic>)> _idempotentResults = {};
  int _sequence = 0;

  @override
  Future<Map<String, dynamic>> fetchSuppliers({
    required String query,
    String? cursor,
    int limit = 25,
  }) async {
    await Future<void>.delayed(latency);
    final needle = query.trim().toLowerCase();
    final matches =
        _details.where((detail) => _matches(detail, needle)).toList()
          ..sort(_byNameThenId);
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + limit).clamp(0, matches.length);
    return {
      "data": {
        "items": [for (final detail in matches.sublist(start, end)) _summary(detail)],
        "next_cursor": end < matches.length ? "$end" : null,
        "counts": {"total": matches.length},
      },
      "meta": {"request_id": "req-preview-suppliers"},
    };
  }

  @override
  Future<Map<String, dynamic>> fetchSupplier(String supplierId) async {
    await Future<void>.delayed(latency);
    final detail = _details
        .where((entry) => entry["supplier_id"] == supplierId)
        .firstOrNull;
    if (detail == null) {
      throw const SupplierApiException(404, {
        "error": {
          "code": "RESOURCE_NOT_FOUND",
          "message": "거래처를 찾을 수 없습니다.",
        },
      });
    }
    return {
      "data": _copy(detail),
      "meta": {"request_id": "req-preview-supplier"},
    };
  }

  @override
  Future<Map<String, dynamic>> fetchPriceHistory(String supplierItemId) async {
    await Future<void>.delayed(latency);
    final known = _details.any(
      (detail) => (detail["items"] as List).any(
        (item) => item["supplier_item_id"] == supplierItemId,
      ),
    );
    if (!known) {
      throw const SupplierApiException(404, {
        "error": {
          "code": "RESOURCE_NOT_FOUND",
          "message": "품목을 찾을 수 없습니다.",
        },
      });
    }
    final history =
        supplierPricePreviewHistory[supplierItemId] ??
        const {"reference_quotes": [], "actual_purchases": []};
    return {
      "data": _copy(history),
      "meta": {"request_id": "req-preview-price-history"},
    };
  }

  @override
  Future<Map<String, dynamic>> createSupplier(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final bodyHash = jsonEncode(body);
    final previous = _idempotentResults[idempotencyKey];
    if (previous != null) {
      if (previous.$1 != bodyHash) {
        throw const SupplierApiException(409, {
          "error": {
            "code": "IDEMPOTENCY_KEY_REUSED",
            "message": "이미 다른 내용으로 접수된 요청입니다.",
          },
        });
      }
      return _copy(previous.$2) as Map<String, dynamic>;
    }

    final name = (body["name"] as String).trim();
    final registrationNo = body["business_registration_no"] as String?;
    final duplicate = _details.any(
      (detail) =>
          (registrationNo != null &&
              detail["business_registration_no"] == registrationNo) ||
          (registrationNo == null && detail["name"] == name),
    );
    if (duplicate) {
      throw const SupplierApiException(409, {
        "error": {
          "code": "SUPPLIER_ALREADY_EXISTS",
          "message": "같은 사업자번호 또는 업체명의 거래처가 이미 있습니다.",
        },
      });
    }

    _sequence++;
    final contact = body["contact"] as Map<String, Object?>;
    final evidence = body["evidence"] as Map<String, Object?>;
    final now = DateTime.now().toUtc().toIso8601String();
    final detail = <String, dynamic>{
      "supplier_id": "preview-supplier-$_sequence",
      "name": name,
      "business_registration_no": registrationNo,
      "contact_email": body["contact_email"],
      "contact": {"name": contact["name"], "phone": contact["phone"]},
      "location": body["location"],
      "source_type": "REGISTERED",
      "evidence": {
        "source_label": "구매담당자 직접 등록",
        "checked_at": now,
        "memo": evidence["memo"],
      },
      "items": [
        for (final (index, item) in (body["items"] as List).indexed)
          _registeredItem(item as Map<String, Object?>, index, now),
      ],
    };
    _details.add(detail);
    final response = {
      "data": _copy(detail),
      "meta": {"request_id": "req-preview-supplier-create"},
    };
    _idempotentResults[idempotencyKey] = (bodyHash, response);
    return _copy(response) as Map<String, dynamic>;
  }

  Map<String, dynamic> _registeredItem(
    Map<String, Object?> item,
    int index,
    String now,
  ) {
    final notes = item["notes"] as String?;
    return {
      "supplier_item_id": "preview-supplier-$_sequence-item-$index",
      "item_name": item["item_name"],
      "specification": item["specification"],
      "unit": item["unit"],
      "units_per_box": item["units_per_box"],
      "weight_per_box": item["weight_per_box"],
      "origin": item["origin"],
      // User-entered certifications stay unconfirmed until evidence is checked.
      "certifications": [
        for (final name in item["certifications"] as List)
          {"name": name, "status": "UNCONFIRMED", "valid_until": null},
      ],
      "notes": notes,
      "notes_evidence": notes == null
          ? null
          : {"source_label": "구매담당자 직접 입력", "checked_at": now},
      "latest_reference_quote": null,
      "last_purchase": null,
    };
  }

  static bool _matches(Map<String, dynamic> detail, String needle) {
    if (needle.isEmpty) return true;
    final contact = detail["contact"] as Map<String, dynamic>;
    final fields = [
      detail["name"],
      detail["business_registration_no"],
      detail["contact_email"],
      contact["name"],
      detail["location"],
      for (final item in detail["items"] as List) item["item_name"],
    ];
    return fields.whereType<String>().any(
      (field) => field.toLowerCase().contains(needle),
    );
  }

  static int _byNameThenId(Map<String, dynamic> a, Map<String, dynamic> b) {
    final byName = (a["name"] as String).compareTo(b["name"] as String);
    if (byName != 0) return byName;
    return (a["supplier_id"] as String).compareTo(b["supplier_id"] as String);
  }

  static Map<String, dynamic> _summary(Map<String, dynamic> detail) => {
    "supplier_id": detail["supplier_id"],
    "name": detail["name"],
    "contact_email": detail["contact_email"],
    "location": detail["location"],
    "source_type": detail["source_type"],
    "item_names": [
      for (final item in detail["items"] as List) item["item_name"],
    ],
  };

  // A fresh JSON object per call, just like a decoded HTTP response.
  static Object? _copy(Object? value) => jsonDecode(jsonEncode(value));
}
