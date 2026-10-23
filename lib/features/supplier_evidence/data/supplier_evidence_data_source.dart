import "dart:convert";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "supplier_evidence_preview_data.dart";

part 'supplier_evidence_data_source.g.dart';

@Riverpod(keepAlive: true)
SupplierEvidenceDataSource supplierEvidenceDataSource(Ref ref) {
  return const PreviewSupplierEvidenceDataSource();
}

abstract interface class SupplierEvidenceDataSource {
  Future<Map<String, dynamic>> fetchEvidence(
    String requestId,
    String supplierLetter,
  );
}

class PreviewSupplierEvidenceDataSource implements SupplierEvidenceDataSource {
  const PreviewSupplierEvidenceDataSource({
    this.latency = const Duration(milliseconds: 250),
  });

  final Duration latency;

  @override
  Future<Map<String, dynamic>> fetchEvidence(
    String requestId,
    String supplierLetter,
  ) async {
    await Future<void>.delayed(latency);
    final response =
        supplierEvidencePreviewResponses[requestId]?[supplierLetter];
    if (response == null) {
      throw StateError("거래처 상세 근거가 없습니다: $requestId / $supplierLetter");
    }
    return jsonDecode(jsonEncode(response)) as Map<String, dynamic>;
  }
}
