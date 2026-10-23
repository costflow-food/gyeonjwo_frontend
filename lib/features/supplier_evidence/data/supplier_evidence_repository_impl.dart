import "package:riverpod_annotation/riverpod_annotation.dart";

import "../domain/supplier_evidence.dart";
import "../domain/supplier_evidence_repository.dart";
import "supplier_evidence_data_source.dart";

part 'supplier_evidence_repository_impl.g.dart';

@Riverpod(keepAlive: true)
SupplierEvidenceRepository supplierEvidenceRepository(Ref ref) {
  return SupplierEvidenceRepositoryImpl(
    ref.watch(supplierEvidenceDataSourceProvider),
  );
}

class SupplierEvidenceRepositoryImpl implements SupplierEvidenceRepository {
  const SupplierEvidenceRepositoryImpl(this._dataSource);

  final SupplierEvidenceDataSource _dataSource;

  @override
  Future<SupplierEvidence> getEvidence(
    String requestId,
    String supplierLetter,
  ) async {
    final json = await _dataSource.fetchEvidence(requestId, supplierLetter);
    return SupplierEvidence(
      requestId: requestId,
      supplierLetter: supplierLetter,
      subtitle: json["subtitle"] as String,
      impactCaption: json["impactCaption"] as String,
      monthlyCostImpact: json["monthlyCostImpact"] as int?,
      impactNote: json["impactNote"] as String,
      costLines: (json["costLines"] as List)
          .map((entry) {
            final line = entry as Map<String, dynamic>;
            return EvidenceLine(
              label: line["label"] as String,
              value: line["value"] as String,
              emphasized: line["emphasized"] as bool? ?? false,
            );
          })
          .toList(growable: false),
      crossCheckFormulas: (json["crossCheckFormulas"] as List)
          .cast<String>()
          .toList(growable: false),
      crossCheckNote: json["crossCheckNote"] as String,
      disclaimer: json["disclaimer"] as String,
      sections: (json["sections"] as List)
          .map((entry) {
            final section = entry as Map<String, dynamic>;
            return EvidenceSection(
              title: section["title"] as String,
              body: section["body"] as String,
              tag: section["tag"] as String?,
            );
          })
          .toList(growable: false),
    );
  }
}
