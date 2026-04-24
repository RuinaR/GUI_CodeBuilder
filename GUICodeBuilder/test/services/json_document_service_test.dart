import 'package:flutter_test/flutter_test.dart';
import 'package:gui_code_builder/models/export_format.dart';
import 'package:gui_code_builder/services/document_store.dart';
import 'package:gui_code_builder/services/json_document_service.dart';

void main() {
  group('JsonDocumentService', () {
    test('encodes and decodes JSON documents without a file backend', () {
      final service =
          JsonDocumentService(documentStore: InMemoryDocumentStore());

      final jsonText = service.encodePretty({
        'page': {'className': 'SavedPage'},
        'nodes': <Map<String, dynamic>>[],
      });
      final decoded = service.decode(jsonText);

      expect(decoded['page'], isA<Map>());
      expect((decoded['page'] as Map)['className'], 'SavedPage');
      expect(decoded['nodes'], isEmpty);
    });

    test('saves export bundles through the configured document store',
        () async {
      final store = InMemoryDocumentStore();
      final service = JsonDocumentService(documentStore: store);

      await service.saveExportFiles(
        jsonText: '{"schemaVersion":3}',
        generatedFiles: {
          ExportFormat.flutter: {
            'flutter_generated_page.dart': 'class GeneratedPage {}',
            'test_mains/flutter_test_main.dart': 'void main() {}',
          },
          ExportFormat.html: {
            'html_generated_page.html': '<main></main>',
            'html_generated_page.css': '.page {}',
          },
        },
      );

      expect(store.files['page_ir.json'], '{"schemaVersion":3}');
      expect(store.files['README.md'], contains('GUI Code Builder Export'));
      expect(
        store.files['flutter_generated_page.dart'],
        'class GeneratedPage {}',
      );
      expect(
          store.files['test_mains/flutter_test_main.dart'], 'void main() {}');
      expect(store.files['html_generated_page.html'], '<main></main>');
      expect(store.files['html_generated_page.css'], '.page {}');
    });

    test('loads JSON documents through the configured document store',
        () async {
      final store = InMemoryDocumentStore()
        ..files['page_ir.json'] = '{"page":{"title":"Loaded"},"nodes":[]}';
      final service = JsonDocumentService(documentStore: store);

      final document = await service.loadJsonDocument('page_ir.json');

      expect(document, isNotNull);
      expect((document!['page'] as Map)['title'], 'Loaded');
      expect(await service.loadJsonDocument('missing.json'), isNull);
    });
  });
}

class InMemoryDocumentStore implements DocumentStore {
  final Map<String, String> files = <String, String>{};

  @override
  Future<String?> readText(String relativePath) async {
    return files[relativePath];
  }

  @override
  Future<void> saveExportBundle(DocumentExportBundle bundle) async {
    files.addAll(bundle.flattenedFiles());
  }
}
