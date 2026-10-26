// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_document_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SourceDocumentViewModel)
final sourceDocumentViewModelProvider = SourceDocumentViewModelFamily._();

final class SourceDocumentViewModelProvider
    extends $AsyncNotifierProvider<SourceDocumentViewModel, SourceDocument> {
  SourceDocumentViewModelProvider._({
    required SourceDocumentViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'sourceDocumentViewModelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sourceDocumentViewModelHash();

  @override
  String toString() {
    return r'sourceDocumentViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SourceDocumentViewModel create() => SourceDocumentViewModel();

  @override
  bool operator ==(Object other) {
    return other is SourceDocumentViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sourceDocumentViewModelHash() =>
    r'0f167a1503068d2b8a80bb13b84fc67f5f73cde6';

final class SourceDocumentViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          SourceDocumentViewModel,
          AsyncValue<SourceDocument>,
          SourceDocument,
          FutureOr<SourceDocument>,
          String
        > {
  SourceDocumentViewModelFamily._()
    : super(
        retry: _noRetry,
        name: r'sourceDocumentViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  SourceDocumentViewModelProvider call(String requestId) =>
      SourceDocumentViewModelProvider._(argument: requestId, from: this);

  @override
  String toString() => r'sourceDocumentViewModelProvider';
}

abstract class _$SourceDocumentViewModel
    extends $AsyncNotifier<SourceDocument> {
  late final _$args = ref.$arg as String;
  String get requestId => _$args;

  FutureOr<SourceDocument> build(String requestId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SourceDocument>, SourceDocument>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SourceDocument>, SourceDocument>,
              AsyncValue<SourceDocument>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
