// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_document_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sourceDocumentDataSource)
final sourceDocumentDataSourceProvider = SourceDocumentDataSourceProvider._();

final class SourceDocumentDataSourceProvider
    extends
        $FunctionalProvider<
          SourceDocumentDataSource,
          SourceDocumentDataSource,
          SourceDocumentDataSource
        >
    with $Provider<SourceDocumentDataSource> {
  SourceDocumentDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sourceDocumentDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sourceDocumentDataSourceHash();

  @$internal
  @override
  $ProviderElement<SourceDocumentDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SourceDocumentDataSource create(Ref ref) {
    return sourceDocumentDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SourceDocumentDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SourceDocumentDataSource>(value),
    );
  }
}

String _$sourceDocumentDataSourceHash() =>
    r'c67e503bca02e7e0601e9c3ad9ade4bf7e88fb01';
