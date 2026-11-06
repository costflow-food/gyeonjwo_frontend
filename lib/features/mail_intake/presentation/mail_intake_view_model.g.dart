// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_intake_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SCR-009 pending intake mails. The work queue reads totalPending from here.
///
/// No Realtime signal covers intake mails (they do not touch work_cases), so
/// the list re-reads itself every [pollInterval] (08 §11 suggests 15 seconds).

@ProviderFor(MailIntakeViewModel)
final mailIntakeViewModelProvider = MailIntakeViewModelProvider._();

/// SCR-009 pending intake mails. The work queue reads totalPending from here.
///
/// No Realtime signal covers intake mails (they do not touch work_cases), so
/// the list re-reads itself every [pollInterval] (08 §11 suggests 15 seconds).
final class MailIntakeViewModelProvider
    extends $AsyncNotifierProvider<MailIntakeViewModel, IntakePage> {
  /// SCR-009 pending intake mails. The work queue reads totalPending from here.
  ///
  /// No Realtime signal covers intake mails (they do not touch work_cases), so
  /// the list re-reads itself every [pollInterval] (08 §11 suggests 15 seconds).
  MailIntakeViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'mailIntakeViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mailIntakeViewModelHash();

  @$internal
  @override
  MailIntakeViewModel create() => MailIntakeViewModel();
}

String _$mailIntakeViewModelHash() =>
    r'71dd89747f65fce43d26a73fda206e36f84bd5e7';

/// SCR-009 pending intake mails. The work queue reads totalPending from here.
///
/// No Realtime signal covers intake mails (they do not touch work_cases), so
/// the list re-reads itself every [pollInterval] (08 §11 suggests 15 seconds).

abstract class _$MailIntakeViewModel extends $AsyncNotifier<IntakePage> {
  FutureOr<IntakePage> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<IntakePage>, IntakePage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<IntakePage>, IntakePage>,
              AsyncValue<IntakePage>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
