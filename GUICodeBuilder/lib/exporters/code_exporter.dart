import '../models/export_format.dart';

// JSON IR을 특정 플랫폼 코드로 변환하는 공통 계약이다.
abstract class CodeExporter {
  ExportFormat get format;

  String exportPage(Map<String, dynamic> irJson);

  // 기본 생성 파일과 테스트 실행 파일을 함께 반환한다.
  Map<String, String> exportFiles(Map<String, dynamic> irJson) {
    return {format.fileName: exportPage(irJson)};
  }
}
