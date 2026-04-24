import 'document_store.dart';

DocumentStore createDefaultDocumentStore() {
  return const _UnsupportedDocumentStore();
}

class _UnsupportedDocumentStore implements DocumentStore {
  const _UnsupportedDocumentStore();

  @override
  Future<void> saveExportBundle(DocumentExportBundle bundle) {
    throw UnsupportedError('File export is not supported on this platform.');
  }

  @override
  Future<String?> readText(String relativePath) async {
    return null;
  }
}
