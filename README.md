# GUI Code Builder

Flutter 기반 GUI 코드 생성기입니다. 편집기에서 위젯 트리를 만들고 `page_ir.json` IR을 기준으로 Flutter, Flet, PyQt6, HTML/CSS 코드를 생성합니다.

## 실행

프로젝트 폴더 기준 상대 경로로 동작합니다.

```cmd
cd GUICodeBuilder
tools\run_debug_windows.cmd
```

릴리즈 빌드/실행:

```cmd
tools\build_release.cmd
tools\build_and_run_release.cmd
```

릴리즈 실행 파일은 빌드 후 아래에 생성됩니다.

```text
GUICodeBuilder\build\windows\x64\runner\Release\gui_code_builder.exe
```

## 확인한 로컬 버전

- Flutter 3.41.7 stable
- Dart 3.11.5
- Flet 0.82.2
- PyQt6 6.11.0
- Qt 6.11.0

이 프로젝트의 exporter는 위 버전 기준 API에 맞춰져 있습니다. 특히 Flutter Radio는 RadioGroup<String>, Flet Radio는 ft.RadioGroup(content=ft.Radio(...)) 구조를 사용합니다.

## Export 구조

Export 버튼을 누르면 `GUICodeBuilder/exports/` 폴더가 만들어집니다. 모든 코드는 `page_ir.json` IR에서 생성됩니다.

```text
exports\page_ir.json
exports\flutter_generated_page.dart
exports\flet_generated_page.py
exports\pyqt_generated_page.py
exports\html_generated_page.html
exports\html_generated_page.css
exports\test_mains\run_flutter_test.cmd
exports\test_mains\run_flet_test.cmd
exports\test_mains\run_pyqt_test.cmd
exports\test_mains\run_html_test.cmd
```

HTML은 같은 폴더의 `html_generated_page.css`를 상대 경로로 참조합니다.

생성 클래스는 `initialize`, `build`, `release` 생명주기를 분리합니다. `build` 안에서는 `initialize`를 호출하지 않으며, 테스트 main은 실행 확인을 위해 `initialize -> build` 순서로 호출합니다. 이벤트가 필요한 컨트롤은 멤버 변수명 기반의 빈 핸들러가 생성되어 바로 수정할 수 있습니다.

## 구조

- `lib/editor/`: 에디터 UI, 패널, 트리, 리사이즈 핸들
- `lib/models/`: IR 노드와 편집 상태
- `lib/models/widgets/`: 위젯 정의 인터페이스, 속성 정의, 위젯별 클래스, 레지스트리
- `lib/exporters/`: Flutter/Flet/PyQt/HTML exporter
- `lib/renderers/`: 캔버스 미리보기 렌더러
- `tools/`: 상대 경로 기반 실행/빌드 스크립트

## Git에 포함하지 않는 항목

아래 항목은 재생성 가능한 산출물/캐시라 `.gitignore`로 제외합니다.

```text
.dart_tool/
.dart-home/
.flutter-sdk/
build/
exports/
.vscode/
.idea/
```

## 지원 위젯

Button, Radio button, Check box, Spin box, Double spin box, Label, Combo box, Text box, Line edit, List box, Progress bar, Horizontal/Vertical slider, Table, Image, Group box, Tab, Scroll area, Container, Row, Column을 지원합니다.

Radio button은 `radio group name`이 같은 항목끼리 한 그룹으로 묶입니다. Flutter export는 정식 `RadioGroup<String>`을 사용합니다.

