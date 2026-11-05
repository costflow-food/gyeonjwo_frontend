// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_progress_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// API-03 progress of one case after START or RESUME was accepted.
///
/// While the server is working it re-reads every [pollInterval], and at
/// once when Supabase Realtime says a case changed. It stops asking when
/// the case waits for the buyer or a reply, when the app is hidden
/// ([pause]), and when the dialog closes (auto-dispose). The server keeps
/// working either way.

@ProviderFor(ReviewProgressViewModel)
final reviewProgressViewModelProvider = ReviewProgressViewModelFamily._();

/// API-03 progress of one case after START or RESUME was accepted.
///
/// While the server is working it re-reads every [pollInterval], and at
/// once when Supabase Realtime says a case changed. It stops asking when
/// the case waits for the buyer or a reply, when the app is hidden
/// ([pause]), and when the dialog closes (auto-dispose). The server keeps
/// working either way.
final class ReviewProgressViewModelProvider
    extends $AsyncNotifierProvider<ReviewProgressViewModel, ReviewProgress> {
  /// API-03 progress of one case after START or RESUME was accepted.
  ///
  /// While the server is working it re-reads every [pollInterval], and at
  /// once when Supabase Realtime says a case changed. It stops asking when
  /// the case waits for the buyer or a reply, when the app is hidden
  /// ([pause]), and when the dialog closes (auto-dispose). The server keeps
  /// working either way.
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
    r'712cabff6c1695ce4d05b0f681356314ae32ca39';

/// API-03 progress of one case after START or RESUME was accepted.
///
/// While the server is working it re-reads every [pollInterval], and at
/// once when Supabase Realtime says a case changed. It stops asking when
/// the case waits for the buyer or a reply, when the app is hidden
/// ([pause]), and when the dialog closes (auto-dispose). The server keeps
/// working either way.

final class ReviewProgressViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          ReviewProgressViewModel,
          AsyncValue<ReviewProgress>,
          ReviewProgress,
          FutureOr<ReviewProgress>,
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
  /// While the server is working it re-reads every [pollInterval], and at
  /// once when Supabase Realtime says a case changed. It stops asking when
  /// the case waits for the buyer or a reply, when the app is hidden
  /// ([pause]), and when the dialog closes (auto-dispose). The server keeps
  /// working either way.

  ReviewProgressViewModelProvider call(String caseId) =>
      ReviewProgressViewModelProvider._(argument: caseId, from: this);

  @override
  String toString() => r'reviewProgressViewModelProvider';
}

/// API-03 progress of one case after START or RESUME was accepted.
///
/// While the server is working it re-reads every [pollInterval], and at
/// once when Supabase Realtime says a case changed. It stops asking when
/// the case waits for the buyer or a reply, when the app is hidden
/// ([pause]), and when the dialog closes (auto-dispose). The server keeps
/// working either way.

abstract class _$ReviewProgressViewModel
    extends $AsyncNotifier<ReviewProgress> {
  late final _$args = ref.$arg as String;
  String get caseId => _$args;

  FutureOr<ReviewProgress> build(String caseId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ReviewProgress>, ReviewProgress>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ReviewProgress>, ReviewProgress>,
              AsyncValue<ReviewProgress>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
