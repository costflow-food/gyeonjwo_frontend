// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_progress_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// API-03 progress of one case after START or RESUME was accepted.
///
/// Re-reads every [pollInterval] while the server is still working and
/// stops once the case waits for the buyer. Closing the dialog stops
/// polling; the server keeps working.

@ProviderFor(ReviewProgressViewModel)
final reviewProgressViewModelProvider = ReviewProgressViewModelFamily._();

/// API-03 progress of one case after START or RESUME was accepted.
///
/// Re-reads every [pollInterval] while the server is still working and
/// stops once the case waits for the buyer. Closing the dialog stops
/// polling; the server keeps working.
final class ReviewProgressViewModelProvider
    extends $AsyncNotifierProvider<ReviewProgressViewModel, CaseProgress> {
  /// API-03 progress of one case after START or RESUME was accepted.
  ///
  /// Re-reads every [pollInterval] while the server is still working and
  /// stops once the case waits for the buyer. Closing the dialog stops
  /// polling; the server keeps working.
  ReviewProgressViewModelProvider._({
    required ReviewProgressViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'reviewProgressViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reviewProgressViewModelHash();

  @override
  String toString() {
    return r'reviewProgressViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ReviewProgressViewModel create() => ReviewProgressViewModel();

  @override
  bool operator ==(Object other) {
    return other is ReviewProgressViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reviewProgressViewModelHash() =>
    r'5fffbabd47ffc1f59457fd05375cd4f41f80b374';

/// API-03 progress of one case after START or RESUME was accepted.
///
/// Re-reads every [pollInterval] while the server is still working and
/// stops once the case waits for the buyer. Closing the dialog stops
/// polling; the server keeps working.

final class ReviewProgressViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          ReviewProgressViewModel,
          AsyncValue<CaseProgress>,
          CaseProgress,
          FutureOr<CaseProgress>,
          String
        > {
  ReviewProgressViewModelFamily._()
    : super(
        retry: _noRetry,
        name: r'reviewProgressViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// API-03 progress of one case after START or RESUME was accepted.
  ///
  /// Re-reads every [pollInterval] while the server is still working and
  /// stops once the case waits for the buyer. Closing the dialog stops
  /// polling; the server keeps working.

  ReviewProgressViewModelProvider call(String caseId) =>
      ReviewProgressViewModelProvider._(argument: caseId, from: this);

  @override
  String toString() => r'reviewProgressViewModelProvider';
}

/// API-03 progress of one case after START or RESUME was accepted.
///
/// Re-reads every [pollInterval] while the server is still working and
/// stops once the case waits for the buyer. Closing the dialog stops
/// polling; the server keeps working.

abstract class _$ReviewProgressViewModel extends $AsyncNotifier<CaseProgress> {
  late final _$args = ref.$arg as String;
  String get caseId => _$args;

  FutureOr<CaseProgress> build(String caseId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CaseProgress>, CaseProgress>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CaseProgress>, CaseProgress>,
              AsyncValue<CaseProgress>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
