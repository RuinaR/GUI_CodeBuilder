import 'document_store.dart';
import 'document_store_factory_stub.dart'
    if (dart.library.io) 'document_store_factory_io.dart'
    if (dart.library.html) 'document_store_factory_web.dart' as platform;

DocumentStore createDefaultDocumentStore() {
  return platform.createDefaultDocumentStore();
}
