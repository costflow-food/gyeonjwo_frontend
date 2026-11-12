// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_settings_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SendSettingsViewModel)
final sendSettingsViewModelProvider = SendSettingsViewModelFamily._();

final class SendSettingsViewModelProvider
    extends $AsyncNotifierProvider<SendSettingsViewModel, SendSettings> {
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
    r'e65aef6ddb6c01eadaf02c2312b8542498d26dfc';

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

  SendSettingsViewModelProvider call(String scope) =>
      SendSettingsViewModelProvider._(argument: scope, from: this);

  @override
  String toString() => r'sendSettingsViewModelProvider';
}

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
