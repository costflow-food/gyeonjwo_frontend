import "package:riverpod_annotation/riverpod_annotation.dart";

import "../domain/review_progress.dart";
import "../domain/review_progress_repository.dart";
import "review_progress_data_source.dart";

part 'review_progress_repository_impl.g.dart';

@Riverpod(keepAlive: true)
ReviewProgressRepository reviewProgressRepository(Ref ref) {
  return ReviewProgressRepositoryImpl(
    ref.watch(reviewProgressDataSourceProvider),
  );
}

class ReviewProgressRepositoryImpl implements ReviewProgressRepository {
  const ReviewProgressRepositoryImpl(this._dataSource);

  final ReviewProgressDataSource _dataSource;

  @override
  Stream<ReviewProgress> watchProgress(String requestId) {
    return _dataSource
        .watchProgress(requestId)
        .map(
          (json) => ReviewProgress(
            completedSteps: json["completedSteps"] as int,
            totalSteps: json["totalSteps"] as int,
            synthetic: json["synthetic"] as bool,
          ),
        );
  }
}
