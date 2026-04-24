import '../models/export_format.dart';

class DocumentExportBundle {
  const DocumentExportBundle({
    required this.jsonText,
    required this.generatedFiles,
    required this.readmeText,
    this.irFileName = 'page_ir.json',
    this.readmeFileName = 'README.md',
  });

  final String jsonText;
  final Map<ExportFormat, Map<String, String>> generatedFiles;
  final String readmeText;
  final String irFileName;
  final String readmeFileName;

  Map<String, String> flattenedFiles() {
    return {
      irFileName: jsonText,
      readmeFileName: readmeText,
      for (final entry in generatedFiles.entries)
        for (final fileEntry in entry.value.entries)
          fileEntry.key: fileEntry.value,
    };
  }
}

abstract interface class DocumentStore {
  Future<void> saveExportBundle(DocumentExportBundle bundle);

  Future<String?> readText(String relativePath);
}
