// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_draft_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SCR-007 drafts of one case. Polls while a send is in progress.

@ProviderFor(MailDraftViewModel)
final mailDraftViewModelProvider = MailDraftViewModelFamily._();

/// SCR-007 drafts of one case. Polls while a send is in progress.
final class MailDraftViewModelProvider
    extends $AsyncNotifierProvider<MailDraftViewModel, List<MailDraft>> {
  /// SCR-007 drafts of one case. Polls while a send is in progress.
  MailDraftViewModelProvider._({
    required MailDraftViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'mailDraftViewModelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mailDraftViewModelHash();

  @override
  String toString() {
    return r'mailDraftViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MailDraftViewModel create() => MailDraftViewModel();

  @override
  bool operator ==(Object other) {
    return other is MailDraftViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mailDraftViewModelHash() =>
    r'f38983d8e01a1af768aa8f590678a0528e9324ca';

/// SCR-007 drafts of one case. Polls while a send is in progress.

final class MailDraftViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          MailDraftViewModel,
          AsyncValue<List<MailDraft>>,
          List<MailDraft>,
          FutureOr<List<MailDraft>>,
          String
        > {
  MailDraftViewModelFamily._()
    : super(
        retry: _noRetry,
        name: r'mailDraftViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// SCR-007 drafts of one case. Polls while a send is in progress.

  MailDraftViewModelProvider call(String caseId) =>
      MailDraftViewModelProvider._(argument: caseId, from: this);

  @override
  String toString() => r'mailDraftViewModelProvider';
}

/// SCR-007 drafts of one case. Polls while a send is in progress.

abstract class _$MailDraftViewModel extends $AsyncNotifier<List<MailDraft>> {
  late final _$args = ref.$arg as String;
  String get caseId => _$args;

  FutureOr<List<MailDraft>> build(String caseId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<MailDraft>>, List<MailDraft>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MailDraft>>, List<MailDraft>>,
              AsyncValue<List<MailDraft>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
