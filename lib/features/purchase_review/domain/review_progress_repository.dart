import "review_progress.dart";

abstract interface class ReviewProgressRepository {
  Stream<ReviewProgress> watchProgress(String requestId);
}
