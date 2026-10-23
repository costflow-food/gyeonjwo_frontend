import "package:riverpod_annotation/riverpod_annotation.dart";

import "../data/supplier_evidence_repository_impl.dart";
import "../domain/supplier_evidence.dart";

part 'supplier_evidence_view_model.g.dart';

// null을 반환하면 자동 재시도 없이 사용자의 다시 시도만 기다립니다.
Duration? _noRetry(int retryCount, Object error) => null;

// _$ 클래스와 Provider 선언은 build_runner가 생성합니다.
@Riverpod(keepAlive: true, retry: _noRetry)
class SupplierEvidenceViewModel extends _$SupplierEvidenceViewModel {
  @override
  // 요청·거래처별 Provider를 만듭니다: supplierEvidenceViewModelProvider(id, letter).
  Future<SupplierEvidence> build(String requestId, String supplierLetter) {
    return ref
        .watch(supplierEvidenceRepositoryProvider)
        .getEvidence(requestId, supplierLetter);
  }

  void refresh() => ref.invalidateSelf();
}
