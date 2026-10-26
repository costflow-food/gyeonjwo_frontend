// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_document_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sourceDocumentRepository)
final sourceDocumentRepositoryProvider = SourceDocumentRepositoryProvider._();

final class SourceDocumentRepositoryProvider
    extends
        $FunctionalProvider<
          SourceDocumentRepository,
          SourceDocumentRepository,
          SourceDocumentRepository
        >
    with $Provider<SourceDocumentRepository> {
  SourceDocumentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sourceDocumentRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sourceDocumentRepositoryHash();

  @$internal
  @override
  $ProviderElement<SourceDocumentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SourceDocumentRepository create(Ref ref) {
    return sourceDocumentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SourceDocumentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SourceDocumentRepository>(value),
    );
  }
}

String _$sourceDocumentRepositoryHash() =>
    r'ff66f1a84552deb00aed45e742d8bb8f96e24172';
