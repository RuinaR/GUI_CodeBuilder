# GUI Code Builder

Flutter 기반 GUI 코드 생성기입니다. 편집기에서 위젯 트리를 만들고 `page_ir.json` IR을 기준으로 Flutter, Flet, PyQt6, HTML/CSS 코드를 생성합니다.

## Live Demo

[Open Web Demo](https://ruinar.github.io/GUI_CodeBuilder/)

## GitHub Pages 배포

이 저장소는 GitHub Actions에서 Flutter Web을 빌드한 뒤 GitHub Pages artifact로 배포합니다. 빌드 산출물은 브랜치에 커밋하지 않습니다.

- workflow: `.github/workflows/deploy-pages.yml`
- 실행 조건: `main` 브랜치 push 또는 수동 실행(`workflow_dispatch`)
- 배포 산출물: `GUICodeBuilder/build/web`
- Pages base href: `/GUI_CodeBuilder/`

GitHub 저장소의 `Settings > Pages`에서 `Build and deployment`의 `Source`를 `GitHub Actions`로 선택하세요.

로컬에서 같은 base path로 웹 빌드를 확인하려면 다음 명령을 실행합니다.

```cmd
cd GUICodeBuilder
.flutter-sdk\flutter\bin\flutter.bat build web --release --base-href /GUI_CodeBuilder/
```

## 실행

프로젝트 폴더 기준 상대 경로로 동작합니다. Git에서 새로 받은 경우에도 아래 스크립트가 `.flutter-sdk/flutter`에 Flutter 3.41.7을 자동으로 준비합니다. 우선 Windows release zip을 내려받고, 실패하면 Git clone 방식으로 재시도합니다.

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

처음 실행하는 환경에는 아래 도구가 필요합니다.

- Git: Flutter SDK 자동 다운로드에 필요
- Visual Studio 2022 C++ desktop workload: Windows Flutter 앱 빌드에 필요
- Python: Flet/PyQt export 결과 실행과 문법 검증에 필요

Flutter SDK만 먼저 준비하려면 다음 스크립트를 실행합니다.

```cmd
cd GUICodeBuilder
tools\ensure_flutter_sdk.cmd
```

SDK 다운로드가 중간에 끊긴 경우에는 스크립트를 다시 실행하면 불완전한 `.flutter-sdk\flutter` 폴더를 지우고 다시 받습니다. 그래도 실패하면 아래 접근이 가능한지 확인하세요.

- Flutter Windows SDK archive: `https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.41.7-stable.zip`
- fallback Git clone: `https://github.com/flutter/flutter.git`
- 사내망/백신/방화벽이 PowerShell `Invoke-WebRequest` 또는 `git clone`을 차단하지 않는지 확인

## 확인한 로컬 버전

- Flutter 3.41.7 stable
- Dart 3.11.5
- Flet 0.82.2
- PyQt6 6.11.0
- Qt 6.11.0

이 프로젝트의 exporter는 위 버전 기준 API에 맞춰져 있습니다. 특히 Flutter Radio는 RadioGroup<String>, Flet Radio는 ft.RadioGroup(content=ft.Radio(...)) 구조를 사용합니다.
생성되는 Python export 의존성 파일은 Flet을 `flet==0.82.2`로 고정합니다.

## 에디터 동작 기준

- `Load JSON`은 붙여넣기와 Windows 데스크톱 드래그&드롭을 지원합니다.
- JSON을 불러오면 `page_ir.json` 기준으로 캔버스/위젯 트리를 다시 구성합니다.
- JSON 로드는 자동 export를 실행하지 않습니다. 파일 생성은 사용자가 `Export`를 눌렀을 때만 수행합니다.
- Label은 `text` 속성을 Property panel에서 편집할 수 있으며, 기존 문서의 legacy `text` 타입도 Label로 호환 처리합니다.
- Slider는 에디터 캔버스에서 실제 조작용 컨트롤보다 선택/이동이 쉬운 편집용 프리뷰를 우선합니다. 값 조작은 Property panel의 `value/min/max`에서 수행합니다.

## Export 구조

Export 버튼을 누르면 `GUICodeBuilder/exports/` 폴더가 만들어집니다. 모든 코드는 `page_ir.json` IR에서 생성됩니다.

```text
exports\page_ir.json
exports\flutter_generated_page.dart
exports\flet_generated_page.py
exports\pyqt_generated_page.py
exports\html_generated_page.html
exports\html_generated_page.css
exports\requirements_export.txt
exports\test_mains\run_flutter_test.cmd
exports\test_mains\run_flet_test.cmd
exports\test_mains\run_pyqt_test.cmd
exports\test_mains\run_html_test.cmd
```

HTML은 같은 폴더의 `html_generated_page.css`를 상대 경로로 참조합니다.

생성 클래스는 `initialize`, `build`, `release` 생명주기를 분리합니다. `build` 안에서는 `initialize`를 호출하지 않으며, 테스트 main은 실행 확인을 위해 `initialize -> build` 순서로 호출합니다. 이벤트가 필요한 컨트롤은 멤버 변수명 기반의 빈 핸들러가 생성되어 바로 수정할 수 있습니다.

### Export 결과 실행

Export 후 생성된 결과는 아래 스크립트로 확인할 수 있습니다.

```cmd
cd GUICodeBuilder
exports\test_mains\run_flutter_test.cmd
exports\test_mains\run_flet_test.cmd
exports\test_mains\run_pyqt_test.cmd
exports\test_mains\run_html_test.cmd
```

Python export 의존성은 다음 파일에 고정됩니다.

```text
exports\requirements_export.txt
```

필요하면 Python 의존성을 먼저 설치합니다.

```cmd
cd GUICodeBuilder
exports\tools\install_export_python_deps.cmd
```

### Exporter 호환성 메모

- Flet exporter는 Flet 0.82.2 기준입니다.
- Flet 0.82.2에는 별도 native vertical slider API가 없어, Vertical slider는 horizontal `ft.Slider`를 회전하는 fallback으로 생성합니다.
- PyQt exporter는 PyQt6/Qt 6.11.0 기준으로 기본 폰트, Label, checkbox/radio/button 상호작용 피드백을 최소 보정합니다.
- HTML/CSS exporter는 정적 HTML, CSS, DOM 이벤트 바인딩을 함께 생성합니다.

## 구조

- `lib/editor/`: 에디터 UI, 패널, 트리, 리사이즈 핸들
- `lib/models/`: IR 노드와 편집 상태
- `lib/models/widgets/`: 위젯 정의 인터페이스, 속성 정의, 위젯별 클래스, 레지스트리
- `lib/exporters/`: Flutter/Flet/PyQt/HTML exporter
- `lib/renderers/`: 캔버스 미리보기 렌더러
- `tools/`: 상대 경로 기반 실행/빌드 스크립트
  - `ensure_flutter_sdk.cmd`: Git clone 후 Flutter 3.41.7 SDK를 `.flutter-sdk/flutter`에 준비
  - `run_debug_windows.cmd`: SDK 준비 후 Windows debug 실행
  - `build_release.cmd`: SDK 준비 후 Windows release 빌드

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

정리할 때는 아래 기준을 따릅니다.

- 삭제해도 되는 항목: `build/`, `__pycache__/`, `*.pyc`
- 보존 권장 항목: `.flutter-sdk/`는 로컬 실행 스크립트가 사용하는 SDK이므로 사용 중이면 삭제하지 않습니다.
- 보존 권장 항목: `windows/flutter/ephemeral/`은 Flutter Windows 빌드가 재생성할 수 있지만, 로컬 권한/SDK 상태에 따라 재생성 과정에서 실패할 수 있으므로 불필요하게 삭제하지 않습니다.
- 보존 권장 항목: `exports/`는 생성 결과 확인용 폴더입니다. 재생성 가능하지만, 사용자가 열어둔 결과물을 확인 중이면 삭제하지 않습니다.
- `build_release.cmd`는 clean 상태의 Flutter 3.41.7 Windows release 빌드에서 필요한 빈 `build/native_assets/windows` 폴더를 빌드 전에 보장합니다.

Git에 올릴 때 `.flutter-sdk/`, `.dart_tool/`, `.dart-home/`, `build/`, `exports/`는 올리지 않습니다. clone 후에는 위 실행/빌드/export 스크립트가 필요한 산출물을 다시 만듭니다.

## 검증 명령어

```cmd
cd GUICodeBuilder
.flutter-sdk\flutter\bin\flutter.bat analyze
.flutter-sdk\flutter\bin\flutter.bat test
.flutter-sdk\flutter\bin\dart.bat run tools\generate_sample_exports.dart
python -m py_compile exports\flet_generated_page.py exports\pyqt_generated_page.py
```

## 지원 위젯

Button, Radio button, Check box, Spin box, Double spin box, Label, Combo box, Text box, Line edit, List box, Progress bar, Horizontal/Vertical slider, Table, Image, Group box, Tab, Scroll area, Container, Row, Column을 지원합니다.

Radio button은 `radio group name`이 같은 항목끼리 한 그룹으로 묶입니다. Flutter export는 정식 `RadioGroup<String>`을 사용합니다.

