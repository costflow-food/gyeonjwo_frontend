import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../shared/network/api_request.dart";
import "../../work_queue/domain/work_case.dart";
import "../domain/review_progress_repository.dart";
import "review_progress_data_source.dart";

part "review_progress_repository_impl.g.dart";

@Riverpod(keepAlive: true)
ReviewProgressRepository reviewProgressRepository(Ref ref) =>
    ReviewProgressRepositoryImpl(ref.watch(reviewProgressDataSourceProvider));

class ReviewProgressRepositoryImpl implements ReviewProgressRepository {
  const ReviewProgressRepositoryImpl(this._dataSource);

  final ReviewProgressDataSource _dataSource;

  @override
  Future<CaseProgress> getProgress(String caseId) async {
    final Map<String, dynamic> response;
    try {
      response = await _dataSource.fetchProgress(caseId);
    } on ApiException catch (error) {
      throw ReviewProgressFailure(error.code, error.message);
    }
    final data = response["data"];
    try {
      final progress = CaseProgress.fromJson(data as Map<String, dynamic>);
      if (progress.caseId != caseId) throw const FormatException();
      return progress;
    } catch (_) {
      throw const ReviewProgressFailure(
        "INVALID_RESPONSE",
        "서버 응답을 확인하지 못했습니다.",
      );
    }
  }
}
