import '../models/export_format.dart';
import '../models/ir_document.dart';
import '../models/widget_node.dart';
import 'code_exporter.dart';

// JSON IR을 PyQt6 코드로 변환한다.
class PyQtCodeExporter implements CodeExporter {
  @override
  ExportFormat get format => ExportFormat.pyqt;

  @override
  Map<String, String> exportFiles(Map<String, dynamic> irJson) {
    return {
      format.fileName: exportPage(irJson),
      'test_mains/pyqt_test_main.py': _exportTestMain(irJson),
      'test_mains/run_pyqt_test.cmd': _exportRunPyQtTestCmd(),
      'requirements_export.txt': 'flet\nPyQt6\n',
      'tools/install_export_python_deps.cmd':
          '@echo off\nsetlocal\nfor %%I in ("%~dp0..\\..") do set "ROOT=%%~fI\\"\npython -m pip install -r "%~dp0..\\requirements_export.txt"\nif not exist "%ROOT%.flutter-sdk\\flutter\\bin\\flutter.bat" (\n  where git >nul 2>nul\n  if errorlevel 1 (\n    echo Git is required to install Flutter SDK.\n    pause\n    exit /b 1\n  )\n  mkdir "%ROOT%.flutter-sdk" 2>nul\n  git clone -b stable https://github.com/flutter/flutter.git "%ROOT%.flutter-sdk\\flutter"\n)\n"%ROOT%.flutter-sdk\\flutter\\bin\\flutter.bat" --version\npause\n',
    };
  }

  @override
  String exportPage(Map<String, dynamic> irJson) {
    final document = IrDocument.fromJson(irJson);
    final className = _safeClassName(document.className);
    final width = _formatNumber(document.width);
    final height = _formatNumber(document.height);
    final nodes = document.nodes;

    return '''
from PyQt6 import QtCore, QtWidgets


# GUI Code Builder에서 생성된 PyQt6 페이지이다.
class ${className}PyQtWindow(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Generated Page")
        self.resize($width, $height)
${_exportMembers(nodes)}
        self.radio_groups = {}
        self.initialize()
        self.build()

    def initialize(self):
        pass

    def build(self):
${nodes.map((node) => _exportMemberAssignment(node, 8, parent: 'self')).join('\n')}

    def release(self):
        self.close()

    def on_button_clicked(self, control_id):
        QtWidgets.QMessageBox.information(self, "Button clicked", f"Clicked: {control_id}")
''';
  }

  String _exportTestMain(Map<String, dynamic> irJson) {
    final document = IrDocument.fromJson(irJson);
    final className = _safeClassName(document.className);
    return '''
import sys

from pathlib import Path

from PyQt6 import QtWidgets

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from pyqt_generated_page import ${className}PyQtWindow


# 생성된 PyQt6 페이지를 바로 실행하는 테스트 main이다.
if __name__ == "__main__":
    app = QtWidgets.QApplication(sys.argv)
    window = ${className}PyQtWindow()
    window.show()
    sys.exit(app.exec())
''';
  }

  String _exportRunPyQtTestCmd() {
    return r'''
@echo off
setlocal
python "%~dp0pyqt_test_main.py"
pause
''';
  }

  String _exportMembers(List<WidgetNode> nodes) {
    final lines = <String>[];
    void collect(WidgetNode node) {
      lines.add('        self.${_memberName(node)} = None');
      for (final child in node.children) {
        collect(child);
      }
    }

    for (final node in nodes) {
      collect(node);
    }
    return lines.join('\n');
  }

  String _exportMemberAssignment(
    WidgetNode node,
    int indent, {
    required String parent,
  }) {
    final space = ' ' * indent;
    final name = _memberName(node);
    final lines = <String>[
      '$space${_createControl(node, parent)}',
      '${space}self.$name.setGeometry(${_formatNumber(node.x)}, ${_formatNumber(node.y)}, ${_formatNumber(node.width)}, ${_formatNumber(node.height)})',
      '$space${_applyStyle(node)}',
    ];
    for (final child in node.children) {
      lines.add(_exportMemberAssignment(child, indent, parent: 'self.$name'));
    }
    return lines.where((line) => line.trim().isNotEmpty).join('\n');
  }

  String _createControl(WidgetNode node, String parent) {
    final name = _memberName(node);
    return switch (node.type) {
      'text' =>
        'self.$name = QtWidgets.QLabel(${_quote(node.props['text']?.toString() ?? '')}, $parent)',
      'button' =>
        'self.$name = QtWidgets.QPushButton(${_quote(node.props['text']?.toString() ?? 'Button')}, $parent)\n        self.$name.clicked.connect(lambda checked=False: self.on_button_clicked(${_quote(node.id)}))',
      'radioButton' => _createRadioControl(node, parent),
      'checkBox' =>
        'self.$name = QtWidgets.QCheckBox(${_quote(node.props['text']?.toString() ?? 'Check')}, $parent)',
      'spinBox' => 'self.$name = QtWidgets.QSpinBox($parent)',
      'doubleSpinBox' => 'self.$name = QtWidgets.QDoubleSpinBox($parent)',
      'comboBox' =>
        'self.$name = QtWidgets.QComboBox($parent)\n        self.$name.addItems([${_items(node).map(_quote).join(', ')}])',
      'textBox' =>
        'self.$name = QtWidgets.QTextEdit(${_quote(node.props['text']?.toString() ?? '')}, $parent)',
      'lineEdit' =>
        'self.$name = QtWidgets.QLineEdit($parent)\n        self.$name.setPlaceholderText(${_quote(node.props['placeholder']?.toString() ?? '')})',
      'listBox' =>
        'self.$name = QtWidgets.QListWidget($parent)\n        self.$name.addItems([${_items(node).map(_quote).join(', ')}])',
      'progressBar' =>
        'self.$name = QtWidgets.QProgressBar($parent)\n        self.$name.setValue(${_formatNumber(node.props['value'] ?? 0)})',
      'horizontalSlider' =>
        'self.$name = QtWidgets.QSlider(QtCore.Qt.Orientation.Horizontal, $parent)',
      'verticalSlider' =>
        'self.$name = QtWidgets.QSlider(QtCore.Qt.Orientation.Vertical, $parent)',
      'table' => 'self.$name = QtWidgets.QTableWidget($parent)',
      'image' =>
        'self.$name = QtWidgets.QLabel(${_quote(node.props['text']?.toString() ?? 'Image')}, $parent)',
      'container' ||
      'row' ||
      'column' ||
      'groupBox' ||
      'tabs' ||
      'scrollArea' =>
        'self.$name = QtWidgets.QFrame($parent)',
      _ =>
        'self.$name = QtWidgets.QLabel(${_quote(node.displayName)}, $parent)',
    };
  }

  String _createRadioControl(WidgetNode node, String parent) {
    final name = _memberName(node);
    final groupName = _radioGroupName(node);
    final selectedLine = node.props['selected'] == true
        ? '\n        self.$name.setChecked(True)'
        : '';
    return 'self.$name = QtWidgets.QRadioButton(${_quote(node.props['text']?.toString() ?? 'Radio')}, $parent)\n        if ${_quote(groupName)} not in self.radio_groups:\n            self.radio_groups[${_quote(groupName)}] = QtWidgets.QButtonGroup(self)\n            self.radio_groups[${_quote(groupName)}].setExclusive(True)\n        self.radio_groups[${_quote(groupName)}].addButton(self.$name)$selectedLine';
  }

  String _applyStyle(WidgetNode node) {
    final name = _memberName(node);
    if (node.type == 'text') {
      final color = node.props['color']?.toString() ?? '#111827';
      final fontSize = _formatNumber(node.props['fontSize'] ?? 16);
      return 'self.$name.setStyleSheet(${_quote('color: $color; font-size: ${fontSize}px;')})';
    }
    final background = node.props['backgroundColor']?.toString() ?? '#FFFFFF';
    final foreground = node.props['foregroundColor']?.toString();
    final border = node.props['borderColor']?.toString() ?? '#CBD5E1';
    final radius = _formatNumber(node.props['borderRadius'] ?? 0);
    final textColor = foreground == null ? '' : ' color: $foreground;';
    return 'self.$name.setStyleSheet(${_quote('background-color: $background; border: 1px solid $border; border-radius: ${radius}px;$textColor')})';
  }

  List<String> _items(WidgetNode node) =>
      (node.props['items']?.toString() ?? '')
          .split(',')
          .where((item) => item.trim().isNotEmpty)
          .toList();
  String _safeClassName(String name) {
    final compact = name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
    if (compact.isEmpty) {
      return 'GeneratedPage';
    }
    return '${compact.substring(0, 1).toUpperCase()}${compact.substring(1)}';
  }

  String _formatNumber(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(1);
  }

  String _quote(String text) {
    return '"${text.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';
  }

  String _radioGroupName(WidgetNode node) =>
      node.props['groupName']?.toString().isNotEmpty == true
          ? node.props['groupName'].toString()
          : 'default';
  String _memberName(WidgetNode node) {
    final raw = node.props['memberName']?.toString() ??
        node.props['name']?.toString() ??
        node.id;
    final compact = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    final safe = compact.isEmpty ? node.id : compact;
    return RegExp(r'^[0-9]').hasMatch(safe) ? 'control_$safe' : safe;
  }
}
