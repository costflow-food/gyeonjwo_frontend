// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preview_workspace.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(previewWorkspace)
final previewWorkspaceProvider = PreviewWorkspaceProvider._();

final class PreviewWorkspaceProvider
    extends
        $FunctionalProvider<
          PreviewWorkspace,
          PreviewWorkspace,
          PreviewWorkspace
        >
    with $Provider<PreviewWorkspace> {
  PreviewWorkspaceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'previewWorkspaceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$previewWorkspaceHash();

  @$internal
  @override
  $ProviderElement<PreviewWorkspace> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PreviewWorkspace create(Ref ref) {
    return previewWorkspace(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreviewWorkspace value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreviewWorkspace>(value),
    );
  }
}

String _$previewWorkspaceHash() => r'89991d7c41a7c83f83128a57a79a7e4af0d59626';
