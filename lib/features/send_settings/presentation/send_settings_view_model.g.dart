// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_settings_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SCR-008 effective settings for the mailbox or one case.

@ProviderFor(SendSettingsViewModel)
final sendSettingsViewModelProvider = SendSettingsViewModelFamily._();

/// SCR-008 effective settings for the mailbox or one case.
final class SendSettingsViewModelProvider
    extends $AsyncNotifierProvider<SendSettingsViewModel, SendSettings> {
  /// SCR-008 effective settings for the mailbox or one case.
  SendSettingsViewModelProvider._({
    required SendSettingsViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'sendSettingsViewModelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sendSettingsViewModelHash();

  @override
  String toString() {
    return r'sendSettingsViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SendSettingsViewModel create() => SendSettingsViewModel();

  @override
  bool operator ==(Object other) {
    return other is SendSettingsViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sendSettingsViewModelHash() =>
    r'a5133615f8528ccc9db2fbba6b681178fe81763e';

/// SCR-008 effective settings for the mailbox or one case.

final class SendSettingsViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          SendSettingsViewModel,
          AsyncValue<SendSettings>,
          SendSettings,
          FutureOr<SendSettings>,
          String
        > {
  SendSettingsViewModelFamily._()
    : super(
        retry: _noRetry,
        name: r'sendSettingsViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// SCR-008 effective settings for the mailbox or one case.

  SendSettingsViewModelProvider call(String scope) =>
      SendSettingsViewModelProvider._(argument: scope, from: this);

  @override
  String toString() => r'sendSettingsViewModelProvider';
}

/// SCR-008 effective settings for the mailbox or one case.

abstract class _$SendSettingsViewModel extends $AsyncNotifier<SendSettings> {
  late final _$args = ref.$arg as String;
  String get scope => _$args;

  FutureOr<SendSettings> build(String scope);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SendSettings>, SendSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SendSettings>, SendSettings>,
              AsyncValue<SendSettings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
