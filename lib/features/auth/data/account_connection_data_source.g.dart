// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_connection_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountConnectionDataSource)
final accountConnectionDataSourceProvider =
    AccountConnectionDataSourceProvider._();

final class AccountConnectionDataSourceProvider
    extends
        $FunctionalProvider<
          AccountConnectionDataSource,
          AccountConnectionDataSource,
          AccountConnectionDataSource
        >
    with $Provider<AccountConnectionDataSource> {
  AccountConnectionDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountConnectionDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountConnectionDataSourceHash();

  @$internal
  @override
  $ProviderElement<AccountConnectionDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountConnectionDataSource create(Ref ref) {
    return accountConnectionDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountConnectionDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountConnectionDataSource>(value),
    );
  }
}

String _$accountConnectionDataSourceHash() =>
    r'b9e9e2ab65641a5dfdcebd444c697ffde491ddde';
