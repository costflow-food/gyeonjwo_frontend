import "supplier_evidence.dart";

abstract interface class SupplierEvidenceRepository {
  Future<SupplierEvidence> getEvidence(String requestId, String supplierLetter);
}
