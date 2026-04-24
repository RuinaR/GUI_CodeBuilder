import 'dart:io';

import 'document_store.dart';

class LocalFileDocumentStore implements DocumentStore {
  const LocalFileDocumentStore({this.exportDirectoryPath = 'exports'});

  final String exportDirectoryPath;

  @override
  Future<void> saveExportBundle(DocumentExportBundle bundle) async {
    final exportDirectory = Directory(exportDirectoryPath);
    if (!exportDirectory.existsSync()) {
      exportDirectory.createSync(recursive: true);
    }

    for (final entry in bundle.flattenedFiles().entries) {
      final file = File(_join(exportDirectoryPath, entry.key));
      file.parent.createSync(recursive: true);
      await file.writeAsString(entry.value);
    }
  }

  @override
  Future<String?> readText(String relativePath) async {
    final file = File(_join(exportDirectoryPath, relativePath));
    if (!file.existsSync()) {
      return null;
    }
    return file.readAsString();
  }

  String _join(String base, String relativePath) {
    final normalized = relativePath.replaceAll('/', Platform.pathSeparator);
    return '$base${Platform.pathSeparator}$normalized';
  }
}
