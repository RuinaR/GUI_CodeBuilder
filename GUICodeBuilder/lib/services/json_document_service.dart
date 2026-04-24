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
    await File('exports/README.md').writeAsString(_buildExportReadme());
    for (final entry in generatedFiles.entries) {
      for (final fileEntry in entry.value.entries) {
        final file = File('exports/${fileEntry.key}');
        file.parent.createSync(recursive: true);
        await file.writeAsString(fileEntry.value);
      }
    }
  }

  String _buildExportReadme() {
    return '''
# GUI Code Builder Export

이 폴더는 GUI Code Builder의 Export 결과물입니다. 모든 플랫폼 코드는 `page_ir.json` 중간 데이터(IR)를 기준으로 생성됩니다.

## 생성 환경

- GUI Code Builder Export Schema: 3
- Flutter: 3.41.7 stable
- Dart: 3.11.5
- 지원 Export 언어: Flutter(Dart), Flet(Python), PyQt6(Python), HTML/CSS

## 폴더 구조

```text
exports/
  page_ir.json
  flutter_generated_page.dart
  flet_generated_page.py
  pyqt_generated_page.py
  html_generated_page.html
  html_generated_page.css
  requirements_export.txt
  README.md
  test_mains/
    flutter_test_main.dart
    flet_test_main.py
    pyqt_test_main.py
    run_flutter_test.cmd
    run_flet_test.cmd
    run_pyqt_test.cmd
    run_html_test.cmd
  tools/
    install_export_python_deps.cmd
```

## IR 구조

`page_ir.json`은 `schemaVersion`, `generator`, `page`, `exportTargets`, `nodes`로 구성됩니다. 각 노드는 `id`, `type`, `role`, `frame`, `content`, `style`, `layout`, `behavior`, `children`을 가집니다.

- `frame`: x/y/width/height/responsive 배치 정보
- `content`: text/name/font 정보
- `style`: 색상, 테두리, 패딩, radius 정보
- `layout`: Row/Column 정렬, gap, layout mode 정보
- `behavior`: 생성 코드의 멤버 변수명, 클릭 액션 정보
- `children`: 부모-자식 트리 구조

## 실행 방법

```powershell
exports\\test_mains\\run_flutter_test.cmd
exports\\test_mains\\run_flet_test.cmd
exports\\test_mains\\run_pyqt_test.cmd
```

Python 의존성과 Flutter SDK 준비:

```powershell
exports\\tools\\install_export_python_deps.cmd
```

이 스크립트는 `flet`, `PyQt6`를 설치하고, 프로젝트 루트에 `.flutter-sdk/flutter`가 없으면 GitHub stable Flutter SDK를 clone합니다.

## 생성 클래스 수명주기

- Flutter: `init()`은 컨트롤 멤버를 초기화하고, `release()`는 현재 route를 닫습니다.
- Flet: `init()`은 멤버 변수를 초기화하고, `release(page)`는 현재 canvas를 페이지에서 제거합니다.
- PyQt: `init()`은 UI 멤버를 초기화하고, `release()`는 현재 window를 닫습니다.

- HTML/CSS: initialize()는 DOM 멤버를 수집하고, uild()는 페이지 객체를 준비하며, 
elease()는 root DOM을 제거합니다.

버튼 클릭 시 다른 페이지로 이동하고 싶다면 생성 코드의 버튼 핸들러에서 `release`를 호출한 뒤 새 페이지를 띄우면 됩니다.

## 주의

생성 코드는 Export 산출물입니다. 장기 유지보수는 `page_ir.json`과 GUI Code Builder 프로젝트를 기준으로 진행하는 것을 권장합니다.
''';
  }
}
