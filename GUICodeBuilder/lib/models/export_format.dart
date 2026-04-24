// 지원하는 코드 출력 형식을 정의한다.
enum ExportFormat {
  flutter('Flutter', 'flutter_generated_page.dart'),
  flet('Flet', 'flet_generated_page.py'),
  pyqt('PyQt', 'pyqt_generated_page.py'),
  html('HTML/CSS', 'html_generated_page.html');

  const ExportFormat(this.label, this.fileName);

  final String label;
  final String fileName;
}
