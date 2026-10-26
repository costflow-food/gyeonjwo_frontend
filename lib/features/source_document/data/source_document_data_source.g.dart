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
    r'7be546371b361acd774558ef3fa6f07a9a266f7e';
