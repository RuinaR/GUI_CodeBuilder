import 'dart:convert';
import 'dart:io';

import '../models/export_format.dart';

// JSON IR과 생성 코드를 파일로 저장하고 읽는다.
class JsonDocumentService {
  String encodePretty(Map<String, dynamic> document) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(document);
  }

  Map<String, dynamic> decode(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw const FormatException('JSON root must be an object.');
  }

  // Export 버튼을 누르면 exports 폴더에 IR과 생성 코드를 저장한다.
  Future<void> saveExportFiles({
    required String jsonText,
    required Map<ExportFormat, Map<String, String>> generatedFiles,
  }) async {
    final exportDirectory = Directory('exports');
    if (!exportDirectory.existsSync()) {
      exportDirectory.createSync(recursive: true);
    }

    await File('exports/page_ir.json').writeAsString(jsonText);
    for (final entry in generatedFiles.entries) {
      for (final fileEntry in entry.value.entries) {
        final file = File('exports/${fileEntry.key}');
        file.parent.createSync(recursive: true);
        await file.writeAsString(fileEntry.value);
      }
    }
  }
}
