import "package:riverpod_annotation/riverpod_annotation.dart";

import "../domain/supplier.dart";
import "../domain/supplier_repository.dart";
import "supplier_data_source.dart";

part "supplier_repository_impl.g.dart";

@Riverpod(keepAlive: true)
SupplierRepository supplierRepository(Ref ref) {
  return SupplierRepositoryImpl(ref.watch(supplierDataSourceProvider));
}

class SupplierRepositoryImpl implements SupplierRepository {
  const SupplierRepositoryImpl(this._dataSource);

  final SupplierDataSource _dataSource;

  @override
  Future<SupplierPage> getSuppliers({String query = "", String? cursor}) =>
      _guard(() async {
        final response = await _dataSource.fetchSuppliers(
          query: query,
          cursor: cursor,
        );
        final data = response["data"] as Map<String, dynamic>;
        final counts = data["counts"] as Map<String, dynamic>?;
        final items = [
          for (final entry in data["items"] as List)
            _summary(entry as Map<String, dynamic>),
        ];
        return SupplierPage(
          items: List.unmodifiable(items),
          total: counts?["total"] as int? ?? items.length,
          nextCursor: data["next_cursor"] as String?,
        );
      });

  @override
  Future<SupplierDetail> getSupplier(String supplierId) => _guard(() async {
    final response = await _dataSource.fetchSupplier(supplierId);
    return _detail(response["data"] as Map<String, dynamic>);
  });

  @override
  Future<PriceHistory> getPriceHistory(String supplierItemId) =>
      _guard(() async {
        final response = await _dataSource.fetchPriceHistory(supplierItemId);
        final data = response["data"] as Map<String, dynamic>;
        List<PriceRecord> records(String key, String dateKey) {
          final list = [
            for (final entry in data[key] as List)
              _priceRecord(entry as Map<String, dynamic>, dateKey),
          ]..sort((a, b) => (b.date ?? "").compareTo(a.date ?? ""));
          return List.unmodifiable(list);
        }

        return PriceHistory(
          referenceQuotes: records("reference_quotes", "effective_from"),
          actualPurchases: records("actual_purchases", "transaction_date"),
        );
      });

  @override
  Future<SupplierDetail> registerSupplier(
    SupplierDraft draft, {
    required String idempotencyKey,
  }) => _guard(() async {
    final response = await _dataSource.createSupplier(
      draft.toJson(),
      idempotencyKey: idempotencyKey,
    );
    return _detail(response["data"] as Map<String, dynamic>);
  });

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on SupplierApiException catch (error) {
      final body = error.body["error"] as Map<String, dynamic>?;
      throw SupplierFailure(
        body?["code"] as String? ?? "HTTP_${error.statusCode}",
        body?["message"] as String? ?? "요청을 처리하지 못했습니다.",
      );
    }
  }

  static SupplierSummary _summary(Map<String, dynamic> json) => SupplierSummary(
    id: json["supplier_id"] as String,
    name: json["name"] as String,
    sourceType: SupplierSourceType.fromCode(json["source_type"] as String),
    itemNames: List.unmodifiable(
      (json["item_names"] as List).cast<String>(),
    ),
    contactEmail: json["contact_email"] as String?,
    location: json["location"] as String?,
  );

  static SupplierDetail _detail(Map<String, dynamic> json) {
    final contact = json["contact"] as Map<String, dynamic>? ?? const {};
    return SupplierDetail(
      id: json["supplier_id"] as String,
      name: json["name"] as String,
      sourceType: SupplierSourceType.fromCode(json["source_type"] as String),
      businessRegistrationNo: json["business_registration_no"] as String?,
      contactEmail: json["contact_email"] as String?,
      contact: SupplierContact(
        name: contact["name"] as String?,
        phone: contact["phone"] as String?,
      ),
      location: json["location"] as String?,
      evidence: _evidence(json["evidence"]),
      items: List.unmodifiable([
        for (final entry in json["items"] as List)
          _item(entry as Map<String, dynamic>),
      ]),
    );
  }

  static SupplierItem _item(Map<String, dynamic> json) {
    final quote = json["latest_reference_quote"] as Map<String, dynamic>?;
    final purchase = json["last_purchase"] as Map<String, dynamic>?;
    return SupplierItem(
      id: json["supplier_item_id"] as String,
      itemName: json["item_name"] as String,
      specification: json["specification"] as String?,
      unit: json["unit"] as String?,
      unitsPerBox: json["units_per_box"] as String?,
      weightPerBox: json["weight_per_box"] as String?,
      origin: json["origin"] as String?,
      certifications: List.unmodifiable([
        for (final entry in json["certifications"] as List? ?? const [])
          Certification(
            name: entry["name"] as String,
            status: CertificationStatus.fromCode(entry["status"] as String),
            validUntil: entry["valid_until"] as String?,
          ),
      ]),
      notes: json["notes"] as String?,
      notesEvidence: _evidence(json["notes_evidence"]),
      latestReferenceQuote: quote == null
          ? null
          : ReferenceQuote(
              unitPrice: quote["unit_price"] as String,
              unit: quote["unit"] as String,
              effectiveFrom: quote["effective_from"] as String?,
            ),
      lastPurchase: purchase == null
          ? null
          : LastPurchase(
              unitPrice: purchase["unit_price"] as String,
              unit: purchase["unit"] as String,
              transactionDate: purchase["transaction_date"] as String,
            ),
    );
  }

  static PriceRecord _priceRecord(Map<String, dynamic> json, String dateKey) =>
      PriceRecord(
        unitPrice: json["unit_price"] as String,
        unit: json["unit"] as String,
        date: json[dateKey] as String?,
        quantity: json["quantity"] as String?,
        conditions: json["conditions"] as String?,
        sourceLabel: json["source_label"] as String? ?? "출처 미확인",
        sourceMailId: json["source_mail_id"] as String?,
      );

  static SourceEvidence? _evidence(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final label = value["source_label"] as String?;
    if (label == null) return null;
    return SourceEvidence(
      label: label,
      checkedAt: value["checked_at"] as String?,
      memo: value["memo"] as String?,
      sourceMailId: value["source_mail_id"] as String?,
    );
  }
}
