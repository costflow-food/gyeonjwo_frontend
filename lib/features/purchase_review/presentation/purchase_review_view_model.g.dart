// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_review_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 업무 한 건의 저장 검토 카드(API-14)와 근거 견적(API-13), 판단(API-15).
///
/// 판단이 저장되면 카드와 업무 큐를 다시 읽어 서버가 저장한 결과와 허용 동작을 보여 줍니다.
/// 카드가 바뀌어 거절되면(revision 충돌 등) 최신 카드를 다시 읽고 실패를 알립니다.

@ProviderFor(PurchaseReviewViewModel)
final purchaseReviewViewModelProvider = PurchaseReviewViewModelFamily._();

/// 업무 한 건의 저장 검토 카드(API-14)와 근거 견적(API-13), 판단(API-15).
///
/// 판단이 저장되면 카드와 업무 큐를 다시 읽어 서버가 저장한 결과와 허용 동작을 보여 줍니다.
/// 카드가 바뀌어 거절되면(revision 충돌 등) 최신 카드를 다시 읽고 실패를 알립니다.
final class PurchaseReviewViewModelProvider
    extends $AsyncNotifierProvider<PurchaseReviewViewModel, PurchaseReview> {
  /// 업무 한 건의 저장 검토 카드(API-14)와 근거 견적(API-13), 판단(API-15).
  ///
  /// 판단이 저장되면 카드와 업무 큐를 다시 읽어 서버가 저장한 결과와 허용 동작을 보여 줍니다.
  /// 카드가 바뀌어 거절되면(revision 충돌 등) 최신 카드를 다시 읽고 실패를 알립니다.
  PurchaseReviewViewModelProvider._({
    required PurchaseReviewViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'purchaseReviewViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$purchaseReviewViewModelHash();

  @override
  String toString() {
    return r'purchaseReviewViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PurchaseReviewViewModel create() => PurchaseReviewViewModel();

  @override
  bool operator ==(Object other) {
    return other is PurchaseReviewViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$purchaseReviewViewModelHash() =>
    r'9686a045bce37cebc313737a7ebe7152c7011326';

/// 업무 한 건의 저장 검토 카드(API-14)와 근거 견적(API-13), 판단(API-15).
///
/// 판단이 저장되면 카드와 업무 큐를 다시 읽어 서버가 저장한 결과와 허용 동작을 보여 줍니다.
/// 카드가 바뀌어 거절되면(revision 충돌 등) 최신 카드를 다시 읽고 실패를 알립니다.

final class PurchaseReviewViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          PurchaseReviewViewModel,
          AsyncValue<PurchaseReview>,
          PurchaseReview,
          FutureOr<PurchaseReview>,
          String
        > {
  PurchaseReviewViewModelFamily._()
    : super(
        retry: _noRetry,
        name: r'purchaseReviewViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 업무 한 건의 저장 검토 카드(API-14)와 근거 견적(API-13), 판단(API-15).
  ///
  /// 판단이 저장되면 카드와 업무 큐를 다시 읽어 서버가 저장한 결과와 허용 동작을 보여 줍니다.
  /// 카드가 바뀌어 거절되면(revision 충돌 등) 최신 카드를 다시 읽고 실패를 알립니다.

  PurchaseReviewViewModelProvider call(String caseId) =>
      PurchaseReviewViewModelProvider._(argument: caseId, from: this);

  @override
  String toString() => r'purchaseReviewViewModelProvider';
}

/// 업무 한 건의 저장 검토 카드(API-14)와 근거 견적(API-13), 판단(API-15).
///
/// 판단이 저장되면 카드와 업무 큐를 다시 읽어 서버가 저장한 결과와 허용 동작을 보여 줍니다.
/// 카드가 바뀌어 거절되면(revision 충돌 등) 최신 카드를 다시 읽고 실패를 알립니다.

abstract class _$PurchaseReviewViewModel
    extends $AsyncNotifier<PurchaseReview> {
  late final _$args = ref.$arg as String;
  String get caseId => _$args;

  FutureOr<PurchaseReview> build(String caseId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PurchaseReview>, PurchaseReview>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PurchaseReview>, PurchaseReview>,
              AsyncValue<PurchaseReview>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
