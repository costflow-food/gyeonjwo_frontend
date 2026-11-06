// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_queue_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 사이드바의 품목별 업무 큐와 현재 선택한 업무.
///
/// 목록 조회(API-01)는 상태를 바꾸지 않습니다. 업무를 선택해도 추출이 시작되지 않습니다.

@ProviderFor(WorkQueueViewModel)
final workQueueViewModelProvider = WorkQueueViewModelProvider._();

/// 사이드바의 품목별 업무 큐와 현재 선택한 업무.
///
/// 목록 조회(API-01)는 상태를 바꾸지 않습니다. 업무를 선택해도 추출이 시작되지 않습니다.
final class WorkQueueViewModelProvider
    extends $AsyncNotifierProvider<WorkQueueViewModel, WorkQueueState> {
  /// 사이드바의 품목별 업무 큐와 현재 선택한 업무.
  ///
  /// 목록 조회(API-01)는 상태를 바꾸지 않습니다. 업무를 선택해도 추출이 시작되지 않습니다.
  WorkQueueViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'workQueueViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workQueueViewModelHash();

  @$internal
  @override
  WorkQueueViewModel create() => WorkQueueViewModel();
}

String _$workQueueViewModelHash() =>
    r'ea030eb14f95ad4aedec99e5e4d688d4bb8fd737';

/// 사이드바의 품목별 업무 큐와 현재 선택한 업무.
///
/// 목록 조회(API-01)는 상태를 바꾸지 않습니다. 업무를 선택해도 추출이 시작되지 않습니다.

abstract class _$WorkQueueViewModel extends $AsyncNotifier<WorkQueueState> {
  FutureOr<WorkQueueState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WorkQueueState>, WorkQueueState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WorkQueueState>, WorkQueueState>,
              AsyncValue<WorkQueueState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// API-02 업무 한 건. 주소로 연 업무가 지금 목록(탭·검색·페이지)에 없을 때 씁니다.

@ProviderFor(caseDetail)
final caseDetailProvider = CaseDetailFamily._();

/// API-02 업무 한 건. 주소로 연 업무가 지금 목록(탭·검색·페이지)에 없을 때 씁니다.

final class CaseDetailProvider
    extends
        $FunctionalProvider<AsyncValue<WorkCase>, WorkCase, FutureOr<WorkCase>>
    with $FutureModifier<WorkCase>, $FutureProvider<WorkCase> {
  /// API-02 업무 한 건. 주소로 연 업무가 지금 목록(탭·검색·페이지)에 없을 때 씁니다.
  CaseDetailProvider._({
    required CaseDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'caseDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$caseDetailHash();

  @override
  String toString() {
    return r'caseDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkCase> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WorkCase> create(Ref ref) {
    final argument = this.argument as String;
    return caseDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CaseDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$caseDetailHash() => r'4cc1a8aba7b67a17f85ffc3218b8c678395d7a7d';

/// API-02 업무 한 건. 주소로 연 업무가 지금 목록(탭·검색·페이지)에 없을 때 씁니다.

final class CaseDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkCase>, String> {
  CaseDetailFamily._()
    : super(
        retry: _noRetry,
        name: r'caseDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// API-02 업무 한 건. 주소로 연 업무가 지금 목록(탭·검색·페이지)에 없을 때 씁니다.

  CaseDetailProvider call(String caseId) =>
      CaseDetailProvider._(argument: caseId, from: this);

  @override
  String toString() => r'caseDetailProvider';
}

/// API-03 진행 단계. 멈춘 업무(보류·추가 정보 필요)에서만 조회합니다.

@ProviderFor(caseProgress)
final caseProgressProvider = CaseProgressFamily._();

/// API-03 진행 단계. 멈춘 업무(보류·추가 정보 필요)에서만 조회합니다.

final class CaseProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<CaseProgress>,
          CaseProgress,
          FutureOr<CaseProgress>
        >
    with $FutureModifier<CaseProgress>, $FutureProvider<CaseProgress> {
  /// API-03 진행 단계. 멈춘 업무(보류·추가 정보 필요)에서만 조회합니다.
  CaseProgressProvider._({
    required CaseProgressFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'caseProgressProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$caseProgressHash();

  @override
  String toString() {
    return r'caseProgressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CaseProgress> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CaseProgress> create(Ref ref) {
    final argument = this.argument as String;
    return caseProgress(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CaseProgressProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$caseProgressHash() => r'c53ef5e0766cea1b0225c820d97c23dac979dff9';

/// API-03 진행 단계. 멈춘 업무(보류·추가 정보 필요)에서만 조회합니다.

final class CaseProgressFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CaseProgress>, String> {
  CaseProgressFamily._()
    : super(
        retry: _noRetry,
        name: r'caseProgressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// API-03 진행 단계. 멈춘 업무(보류·추가 정보 필요)에서만 조회합니다.

  CaseProgressProvider call(String caseId) =>
      CaseProgressProvider._(argument: caseId, from: this);

  @override
  String toString() => r'caseProgressProvider';
}

/// API-11 후보. 고를 수 있는 업무(SELECT_CANDIDATES)에서만 조회합니다.

@ProviderFor(caseCandidates)
final caseCandidatesProvider = CaseCandidatesFamily._();

/// API-11 후보. 고를 수 있는 업무(SELECT_CANDIDATES)에서만 조회합니다.

final class CaseCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<CandidateSet>,
          CandidateSet,
          FutureOr<CandidateSet>
        >
    with $FutureModifier<CandidateSet>, $FutureProvider<CandidateSet> {
  /// API-11 후보. 고를 수 있는 업무(SELECT_CANDIDATES)에서만 조회합니다.
  CaseCandidatesProvider._({
    required CaseCandidatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'caseCandidatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$caseCandidatesHash();

  @override
  String toString() {
    return r'caseCandidatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CandidateSet> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CandidateSet> create(Ref ref) {
    final argument = this.argument as String;
    return caseCandidates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CaseCandidatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$caseCandidatesHash() => r'43e899956f93d5ed5cc6aee631ea950e99277e4e';

/// API-11 후보. 고를 수 있는 업무(SELECT_CANDIDATES)에서만 조회합니다.

final class CaseCandidatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CandidateSet>, String> {
  CaseCandidatesFamily._()
    : super(
        retry: _noRetry,
        name: r'caseCandidatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// API-11 후보. 고를 수 있는 업무(SELECT_CANDIDATES)에서만 조회합니다.

  CaseCandidatesProvider call(String caseId) =>
      CaseCandidatesProvider._(argument: caseId, from: this);

  @override
  String toString() => r'caseCandidatesProvider';
}

/// API-25 원문. 열기만 해서는 추출·OCR이 실행되지 않습니다.

@ProviderFor(originalMail)
final originalMailProvider = OriginalMailFamily._();

/// API-25 원문. 열기만 해서는 추출·OCR이 실행되지 않습니다.

final class OriginalMailProvider
    extends
        $FunctionalProvider<
          AsyncValue<OriginalMail>,
          OriginalMail,
          FutureOr<OriginalMail>
        >
    with $FutureModifier<OriginalMail>, $FutureProvider<OriginalMail> {
  /// API-25 원문. 열기만 해서는 추출·OCR이 실행되지 않습니다.
  OriginalMailProvider._({
    required OriginalMailFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'originalMailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$originalMailHash();

  @override
  String toString() {
    return r'originalMailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OriginalMail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OriginalMail> create(Ref ref) {
    final argument = this.argument as String;
    return originalMail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OriginalMailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$originalMailHash() => r'164617511233085b0b882ee4caddaa0d4a269ca2';

/// API-25 원문. 열기만 해서는 추출·OCR이 실행되지 않습니다.

final class OriginalMailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<OriginalMail>, String> {
  OriginalMailFamily._()
    : super(
        retry: _noRetry,
        name: r'originalMailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// API-25 원문. 열기만 해서는 추출·OCR이 실행되지 않습니다.

  OriginalMailProvider call(String mailId) =>
      OriginalMailProvider._(argument: mailId, from: this);

  @override
  String toString() => r'originalMailProvider';
}

/// API-26 첨부 원본. 뷰어를 닫으면 메모리에서 내려갑니다.

@ProviderFor(attachmentContent)
final attachmentContentProvider = AttachmentContentFamily._();

/// API-26 첨부 원본. 뷰어를 닫으면 메모리에서 내려갑니다.

final class AttachmentContentProvider
    extends
        $FunctionalProvider<
          AsyncValue<Uint8List>,
          Uint8List,
          FutureOr<Uint8List>
        >
    with $FutureModifier<Uint8List>, $FutureProvider<Uint8List> {
  /// API-26 첨부 원본. 뷰어를 닫으면 메모리에서 내려갑니다.
  AttachmentContentProvider._({
    required AttachmentContentFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: _noRetry,
         name: r'attachmentContentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attachmentContentHash();

  @override
  String toString() {
    return r'attachmentContentProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Uint8List> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Uint8List> create(Ref ref) {
    final argument = this.argument as (String, String);
    return attachmentContent(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is AttachmentContentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attachmentContentHash() => r'8b8f685036f176e9eb87c5c4405b8fe491fafdcc';

/// API-26 첨부 원본. 뷰어를 닫으면 메모리에서 내려갑니다.

final class AttachmentContentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Uint8List>, (String, String)> {
  AttachmentContentFamily._()
    : super(
        retry: _noRetry,
        name: r'attachmentContentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// API-26 첨부 원본. 뷰어를 닫으면 메모리에서 내려갑니다.

  AttachmentContentProvider call(String mailId, String attachmentId) =>
      AttachmentContentProvider._(argument: (mailId, attachmentId), from: this);

  @override
  String toString() => r'attachmentContentProvider';
}

/// Realtime change signal while signed in; nothing when signed out.

@ProviderFor(workCaseChanges)
final workCaseChangesProvider = WorkCaseChangesProvider._();

/// Realtime change signal while signed in; nothing when signed out.

final class WorkCaseChangesProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Realtime change signal while signed in; nothing when signed out.
  WorkCaseChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workCaseChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workCaseChangesHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return workCaseChanges(ref);
  }
}

String _$workCaseChangesHash() => r'9afbb535abd426346abafefb48aad72d939039c0';
