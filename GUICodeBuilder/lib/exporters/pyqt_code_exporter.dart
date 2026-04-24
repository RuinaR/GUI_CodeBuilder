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
      'test_mains/pyqt_test_main.py': _exportTestMain(),
      'requirements_export.txt': 'flet\nPyQt6\n',
      'tools/install_export_python_deps.cmd':
          '@echo off\npython -m pip install -r "%~dp0..\\requirements_export.txt"\npause\n',
    };
  }

  @override
  String exportPage(Map<String, dynamic> irJson) {
    final document = IrDocument.fromJson(irJson);
    final width = _formatNumber(document.width);
    final height = _formatNumber(document.height);
    final nodes = document.nodes;

    return '''
from PyQt6 import QtCore, QtWidgets


# GUI Code Builder에서 생성된 PyQt6 페이지이다.
class GeneratedPyQtWindow(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Generated Page")
        self.resize($width, $height)
${_exportMembers(nodes)}
        self.build_ui()

    def build_ui(self):
${nodes.map((node) => _exportMemberAssignment(node, 8, parent: 'self')).join('\n')}

    def on_button_clicked(self, control_id):
        pass
''';
  }

  String _exportTestMain() {
    return '''
import sys

from pathlib import Path

from PyQt6 import QtWidgets

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from pyqt_generated_page import GeneratedPyQtWindow


# 생성된 PyQt6 페이지를 바로 실행하는 테스트 main이다.
if __name__ == "__main__":
    app = QtWidgets.QApplication(sys.argv)
    window = GeneratedPyQtWindow()
    window.show()
    sys.exit(app.exec())
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
      WidgetNodeType.text =>
        'self.$name = QtWidgets.QLabel(${_quote(node.props['text']?.toString() ?? '')}, $parent)',
      WidgetNodeType.button =>
        'self.$name = QtWidgets.QPushButton(${_quote(node.props['text']?.toString() ?? 'Button')}, $parent)\n        self.$name.clicked.connect(lambda checked=False: self.on_button_clicked(${_quote(node.id)}))',
      WidgetNodeType.container ||
      WidgetNodeType.row ||
      WidgetNodeType.column =>
        'self.$name = QtWidgets.QFrame($parent)',
    };
  }

  String _applyStyle(WidgetNode node) {
    final name = _memberName(node);
    if (node.type == WidgetNodeType.text) {
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

  String _memberName(WidgetNode node) {
    final raw = node.props['name']?.toString() ?? node.id;
    final compact = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    final safe = compact.isEmpty ? node.id : compact;
    return RegExp(r'^[0-9]').hasMatch(safe) ? 'control_$safe' : safe;
  }
}
