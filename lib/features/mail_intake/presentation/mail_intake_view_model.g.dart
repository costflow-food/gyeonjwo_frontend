// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_intake_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SCR-009 pending intake mails. The work queue reads totalPending from here.

@ProviderFor(MailIntakeViewModel)
final mailIntakeViewModelProvider = MailIntakeViewModelProvider._();

/// SCR-009 pending intake mails. The work queue reads totalPending from here.
final class MailIntakeViewModelProvider
    extends $AsyncNotifierProvider<MailIntakeViewModel, IntakePage> {
  /// SCR-009 pending intake mails. The work queue reads totalPending from here.
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
    r'eab18634e584fbf61f1edc8198ec8a0b73f86c24';

/// SCR-009 pending intake mails. The work queue reads totalPending from here.

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
