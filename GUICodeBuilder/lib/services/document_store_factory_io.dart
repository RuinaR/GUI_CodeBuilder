import 'document_store.dart';
import 'local_file_document_store.dart';

DocumentStore createDefaultDocumentStore() {
  return const LocalFileDocumentStore();
}
