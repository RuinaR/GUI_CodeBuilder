import 'dart:convert';

import '../models/export_format.dart';
import 'document_store.dart';
import 'local_file_document_store.dart';

// JSON IR과 생성 코드를 파일로 저장하고 읽는다.
class JsonDocumentService {
  JsonDocumentService({DocumentStore? documentStore})
      : documentStore = documentStore ?? const LocalFileDocumentStore();

  final DocumentStore documentStore;

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
    await documentStore.saveExportBundle(
      DocumentExportBundle(
        jsonText: jsonText,
        generatedFiles: generatedFiles,
        readmeText: _buildExportReadme(),
      ),
    );
  }

  Future<Map<String, dynamic>?> loadJsonDocument(String relativePath) async {
    final jsonText = await documentStore.readText(relativePath);
    if (jsonText == null) {
      return null;
    }
    return decode(jsonText);
  }

  String _buildExportReadme() {
    return '''
# GUI Code Builder Export

이 폴더는 GUI Code Builder의 Export 결과물입니다. 모든 플랫폼 코드는 `page_ir.json` 중간 데이터(IR)를 기준으로 생성됩니다.

## 생성 환경

- GUI Code Builder Export Schema: 3
- Flutter: 3.41.7 stable
- Dart: 3.11.5
- Flet: 0.82.2
- PyQt6: 6.11.0
- Qt: 6.11.0
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

이 스크립트는 `flet==0.82.2`, `PyQt6==6.11.0`를 설치하고, 프로젝트 루트에 `.flutter-sdk/flutter`가 없으면 GitHub stable Flutter SDK를 clone합니다.

## 생성 클래스 수명주기

생성 클래스는 `initialize`, `build`, `release`를 분리합니다. `build` 내부에서 `initialize`를 다시 호출하지 않으므로, 사용하는 쪽에서 필요한 순서대로 직접 호출해야 합니다.

- Flutter: 기본 생성자는 자동 초기화하지 않습니다. 테스트 main은 바로 확인할 수 있도록 `autoInitialize: true`로 실행합니다.
- Flet: `initialize()`가 컨트롤 멤버를 생성하고, `build(page)`가 페이지에 canvas를 추가하며, `release(page)`가 canvas를 제거합니다.
- PyQt: `initialize()`가 UI 멤버를 생성하고, `build()`가 window를 표시하며, `release()`가 window를 닫습니다.
- HTML/CSS: `initialize()`가 DOM 멤버를 수집하고 이벤트를 연결하며, `build()`는 렌더링 진입점으로 분리되어 있고, `release()`가 root DOM을 제거합니다.

이벤트가 필요한 컨트롤은 멤버 변수명 기반의 빈 핸들러를 생성해 자동 연결합니다. 예: `btnStart_on_click`, `btnStartControlOnPressed`, `btnStart_on_clicked`, `btnStart_onClick`.

버튼 클릭 시 다른 페이지로 이동하고 싶다면 생성 코드의 이벤트 핸들러에서 `release`를 호출한 뒤 새 페이지를 띄우면 됩니다.

## 주의

생성 코드는 Export 산출물입니다. 장기 유지보수는 `page_ir.json`과 GUI Code Builder 프로젝트를 기준으로 진행하는 것을 권장합니다.
''';
  }
}
