// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sign-in state for route guards, the sidebar and the account screen.

@ProviderFor(AuthSessionViewModel)
final authSessionViewModelProvider = AuthSessionViewModelProvider._();

/// Sign-in state for route guards, the sidebar and the account screen.
final class AuthSessionViewModelProvider
    extends $AsyncNotifierProvider<AuthSessionViewModel, AuthSession> {
  /// Sign-in state for route guards, the sidebar and the account screen.
  AuthSessionViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'authSessionViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSessionViewModelHash();

  @$internal
  @override
  AuthSessionViewModel create() => AuthSessionViewModel();
}

String _$authSessionViewModelHash() =>
    r'39f586af96b5c14fd104eaebb97b36987a85a8f9';

/// Sign-in state for route guards, the sidebar and the account screen.

abstract class _$AuthSessionViewModel extends $AsyncNotifier<AuthSession> {
  FutureOr<AuthSession> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthSession>, AuthSession>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthSession>, AuthSession>,
              AsyncValue<AuthSession>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// OAuth error returned on the redirect URL, read once per page load.

@ProviderFor(authRedirectFailure)
final authRedirectFailureProvider = AuthRedirectFailureProvider._();

/// OAuth error returned on the redirect URL, read once per page load.

final class AuthRedirectFailureProvider
    extends $FunctionalProvider<AuthFailure?, AuthFailure?, AuthFailure?>
    with $Provider<AuthFailure?> {
  /// OAuth error returned on the redirect URL, read once per page load.
  AuthRedirectFailureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRedirectFailureProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRedirectFailureHash();

  @$internal
  @override
  $ProviderElement<AuthFailure?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthFailure? create(Ref ref) {
    return authRedirectFailure(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthFailure? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthFailure?>(value),
    );
  }
}

String _$authRedirectFailureHash() =>
    r'563bcea995a388edcbdf0dc06aba804d1ebeb2d9';
