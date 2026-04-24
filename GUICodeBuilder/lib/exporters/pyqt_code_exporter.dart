import '../models/export_format.dart';
import '../models/ir_document.dart';
import '../models/widget_node.dart';
import 'code_exporter.dart';

part 'widget_generators/pyqt_widget_generators.dart';

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
      'requirements_export.txt': 'flet==0.82.2\nPyQt6==6.11.0\n',
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
from PyQt6 import QtCore, QtGui, QtWidgets


# GUI Code Builder에서 생성된 PyQt6 페이지이다.
class ${className}PyQtWindow(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Generated Page")
        self.resize($width, $height)
${_exportMembers(nodes)}
        self.radio_groups = {}

    def initialize(self):
${nodes.map((node) => _exportMemberAssignment(node, 8, parent: 'self')).join('\n')}

    def build(self):
        self.show()

    def release(self):
        self.close()

${_exportEventHandlers(nodes)}
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
    window.initialize()
    window.build()
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
    final childParent = <String, String>{
          'scrollArea': 'self.${name}_content',
          'tabs': 'self.${name}_page_0',
        }[node.type] ??
        'self.$name';
    for (final child in node.children) {
      lines.add(_exportMemberAssignment(child, indent, parent: childParent));
    }
    return lines.where((line) => line.trim().isNotEmpty).join('\n');
  }

  String _createControl(WidgetNode node, String parent) {
    return _pyqtWidgetGenerators
        .firstWhere((generator) => generator.supports(node.type))
        .create(this, node, parent);
  }

  String _createTableControl(WidgetNode node, String parent) {
    final name = _memberName(node);
    final columns =
        _csv(node.payload.string('columns', fallback: 'Name,Value'));
    final rows = _tableRows(node);
    final headers = columns.map(_quote).join(', ');
    final rowLines = <String>[
      'self.$name = QtWidgets.QTableWidget($parent)',
      'self.$name.setColumnCount(${columns.length})',
      'self.$name.setHorizontalHeaderLabels([$headers])',
      'self.$name.setRowCount(${rows.length})',
    ];
    for (var r = 0; r < rows.length; r += 1) {
      for (var c = 0; c < columns.length; c += 1) {
        final value = c < rows[r].length ? rows[r][c] : '';
        rowLines.add(
            'self.$name.setItem($r, $c, QtWidgets.QTableWidgetItem(${_quote(value)}))');
      }
    }
    return rowLines.join('\n        ');
  }

  String _createImageControl(WidgetNode node, String parent) {
    final name = _memberName(node);
    final src = node.payload.string('src');
    if (src.isEmpty) {
      return 'self.$name = QtWidgets.QLabel(${_quote(node.payload.string('text', fallback: 'Image'))}, $parent)';
    }
    return 'self.$name = QtWidgets.QLabel($parent)\n        self.${name}_pixmap = QtGui.QPixmap(${_quote(src)})\n        self.$name.setPixmap(self.${name}_pixmap.scaled(${_formatNumber(node.width)}, ${_formatNumber(node.height)}, QtCore.Qt.AspectRatioMode.KeepAspectRatio, QtCore.Qt.TransformationMode.SmoothTransformation))';
  }

  String _createTabsControl(WidgetNode node, String parent) {
    final name = _memberName(node);
    final tabs = _csv(node.payload.string('tabs', fallback: 'Tab 1,Tab 2'));
    final lines = <String>[
      'self.$name = QtWidgets.QTabWidget($parent)',
    ];
    for (var i = 0; i < tabs.length; i += 1) {
      lines.add('self.${name}_page_$i = QtWidgets.QWidget()');
      lines.add('self.$name.addTab(self.${name}_page_$i, ${_quote(tabs[i])})');
    }
    if (tabs.isEmpty) {
      lines.add('self.${name}_page_0 = QtWidgets.QWidget()');
      lines.add('self.$name.addTab(self.${name}_page_0, ${_quote('Tab 1')})');
    }
    return lines.join('\n        ');
  }

  String _createScrollAreaControl(WidgetNode node, String parent) {
    final name = _memberName(node);
    return 'self.$name = QtWidgets.QScrollArea($parent)\n        self.$name.setWidgetResizable(False)\n        self.${name}_content = QtWidgets.QWidget()\n        self.${name}_content.setGeometry(0, 0, ${_formatNumber(node.width)}, ${_formatNumber(node.height)})\n        self.$name.setWidget(self.${name}_content)';
  }

  String _createRadioControl(WidgetNode node, String parent) {
    final name = _memberName(node);
    final groupName = _radioGroupName(node);
    final selectedLine = node.payload.boolean('selected')
        ? '\n        self.$name.setChecked(True)'
        : '';
    return 'self.$name = QtWidgets.QRadioButton(${_quote(node.payload.string('text', fallback: 'Radio'))}, $parent)\n        if ${_quote(groupName)} not in self.radio_groups:\n            self.radio_groups[${_quote(groupName)}] = QtWidgets.QButtonGroup(self)\n            self.radio_groups[${_quote(groupName)}].setExclusive(True)\n        self.radio_groups[${_quote(groupName)}].addButton(self.$name)$selectedLine\n        self.$name.toggled.connect(self.${_eventHandlerName(node, 'on_toggled')})';
  }

  String _applyStyle(WidgetNode node) {
    final name = _memberName(node);
    if (node.widgetType == WidgetType.label) {
      final color = node.payload.string('color', fallback: '#111827');
      final fontSize =
          _formatNumber(node.payload.number('fontSize', fallback: 16));
      return 'self.$name.setStyleSheet(${_quote('color: $color; font-size: ${fontSize}px;')})';
    }
    final background =
        node.payload.string('backgroundColor', fallback: '#FFFFFF');
    final foreground = node.payload.string('foregroundColor');
    final border = node.payload.string('borderColor', fallback: '#CBD5E1');
    final radius = _formatNumber(node.payload.number('borderRadius'));
    final textColor = foreground.isEmpty ? '' : ' color: $foreground;';
    return 'self.$name.setStyleSheet(${_quote('background-color: $background; border: 1px solid $border; border-radius: ${radius}px;$textColor')})';
  }

  List<String> _items(WidgetNode node) => node.payload.csv('items');

  String _exportEventHandlers(List<WidgetNode> nodes) {
    final lines = <String>[];
    final builders = <String, String Function(WidgetNode)>{
      'button': (node) =>
          '''    def ${_eventHandlerName(node, 'on_clicked')}(self, checked=False):
        # 여기에 ${_memberName(node)}의 클릭 이벤트를 구현합니다.
        pass
''',
      'radioButton': (node) =>
          '''    def ${_eventHandlerName(node, 'on_toggled')}(self, checked):
        # 여기에 ${_memberName(node)}의 선택 변경 이벤트를 구현합니다.
        pass
''',
      'checkBox': (node) =>
          '''    def ${_eventHandlerName(node, 'on_state_changed')}(self, state):
        # 여기에 ${_memberName(node)}의 체크 변경 이벤트를 구현합니다.
        pass
''',
      'comboBox': (node) =>
          '''    def ${_eventHandlerName(node, 'on_current_text_changed')}(self, text):
        # 여기에 ${_memberName(node)}의 선택값 변경 이벤트를 구현합니다.
        pass
''',
      'lineEdit': (node) =>
          '''    def ${_eventHandlerName(node, 'on_text_changed')}(self, text):
        # 여기에 ${_memberName(node)}의 텍스트 변경 이벤트를 구현합니다.
        pass
''',
      'textBox': (node) =>
          '''    def ${_eventHandlerName(node, 'on_text_changed')}(self):
        # 여기에 ${_memberName(node)}의 텍스트 변경 이벤트를 구현합니다.
        pass
''',
      'spinBox': (node) =>
          '''    def ${_eventHandlerName(node, 'on_value_changed')}(self, value):
        # 여기에 ${_memberName(node)}의 값 변경 이벤트를 구현합니다.
        pass
''',
      'doubleSpinBox': (node) =>
          '''    def ${_eventHandlerName(node, 'on_value_changed')}(self, value):
        # 여기에 ${_memberName(node)}의 값 변경 이벤트를 구현합니다.
        pass
''',
      'horizontalSlider': (node) =>
          '''    def ${_eventHandlerName(node, 'on_value_changed')}(self, value):
        # 여기에 ${_memberName(node)}의 값 변경 이벤트를 구현합니다.
        pass
''',
      'verticalSlider': (node) =>
          '''    def ${_eventHandlerName(node, 'on_value_changed')}(self, value):
        # 여기에 ${_memberName(node)}의 값 변경 이벤트를 구현합니다.
        pass
''',
    };
    void collect(WidgetNode node) {
      final builder = builders[node.type];
      if (builder != null) {
        lines.add(builder(node));
      }
      for (final child in node.children) {
        collect(child);
      }
    }

    for (final node in nodes) {
      collect(node);
    }
    return lines.join('\n');
  }

  List<String> _csv(String text) => text
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  List<List<String>> _tableRows(WidgetNode node) => node.payload
      .string('rows')
      .split(';')
      .where((row) => row.trim().isNotEmpty)
      .map(_csv)
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
      node.payload.string('groupName').isNotEmpty
          ? node.payload.string('groupName')
          : 'default';
  String _memberName(WidgetNode node) {
    final raw = node.payload.string(
      'memberName',
      fallback: node.payload.string('name', fallback: node.id),
    );
    final compact = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    final safe = compact.isEmpty ? node.id : compact;
    return RegExp(r'^[0-9]').hasMatch(safe) ? 'control_$safe' : safe;
  }

  String _eventHandlerName(WidgetNode node, String suffix) =>
      '${_memberName(node)}_$suffix';
}
