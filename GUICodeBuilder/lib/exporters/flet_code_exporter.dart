import '../models/export_format.dart';
import '../models/ir_document.dart';
import '../models/widget_node.dart';
import 'code_exporter.dart';

// JSON IR을 Python Flet 코드로 변환한다.
class FletCodeExporter implements CodeExporter {
  @override
  ExportFormat get format => ExportFormat.flet;

  @override
  Map<String, String> exportFiles(Map<String, dynamic> irJson) {
    return {
      format.fileName: exportPage(irJson),
      'test_mains/flet_test_main.py': _exportTestMain(),
      'test_mains/run_flet_test.cmd': _exportRunFletTestCmd(),
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
import flet as ft


# GUI Code Builder에서 생성된 Flet 페이지이다.
class ${className}FletPage:
    def __init__(self):
${_exportMembers(nodes)}

    def initialize(self):
${nodes.map((node) => _exportMemberAssignment(node, 8)).join('\n')}

    def build(self, page: ft.Page):
        page.title = "Generated Page"
        page.window_width = $width
        page.window_height = $height
        page.padding = 0
        self.canvas = ft.Stack(
            width=$width,
            height=$height,
            controls=[
${nodes.map((node) => _exportPositionedNode(node, 16)).join('\n')}
            ],
        )
        page.add(self.canvas)

    def release(self, page: ft.Page):
        if self.canvas in page.controls:
            page.controls.remove(self.canvas)
            page.update()

${_exportEventHandlers(nodes)}


def main(page: ft.Page):
    generated_page = ${className}FletPage()
    generated_page.initialize()
    generated_page.build(page)
''';
  }

  String _exportTestMain() {
    return '''
import flet as ft

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from flet_generated_page import main


# 생성된 Flet 페이지를 바로 실행하는 테스트 main이다.
if __name__ == "__main__":
    ft.app(target=main)
''';
  }

  String _exportRunFletTestCmd() {
    return r'''
@echo off
setlocal
python "%~dp0flet_test_main.py"
pause
''';
  }

  String _exportMembers(List<WidgetNode> nodes) {
    final lines = <String>[
      '        self.canvas = None',
      '        self.radio_group_values = {}',
    ];
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

  String _exportPositionedNode(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''${space}ft.Container(
$space    left=${_formatNumber(node.x)},
$space    top=${_formatNumber(node.y)},
$space    width=${_formatNumber(node.width)},
$space    height=${_formatNumber(node.height)},
$space    content=self.${_memberName(node)},
$space),''';
  }

  String _exportMemberAssignment(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final lines = <String>[];
    for (final child in node.children) {
      lines.add(_exportMemberAssignment(child, indent));
    }
    if (node.type == 'radioButton') {
      lines.add(_exportRadioDefault(node, indent));
    }
    lines.add(
      '$space'
      'self.${_memberName(node)} = ${_exportControl(node, indent)}',
    );
    return lines.join('\n');
  }

  String _exportControl(WidgetNode node, int indent) {
    switch (node.type) {
      case 'text':
        return _exportText(node, indent);
      case 'button':
        return _exportButton(node, indent);
      case 'container':
      case 'groupBox':
      case 'tabs':
      case 'scrollArea':
        return _exportContainer(node, indent);
      case 'row':
        return _exportFlex(node, indent, 'Row');
      case 'column':
        return _exportFlex(node, indent, 'Column');
      case 'radioButton':
        return _exportRadio(node, indent);
      case 'checkBox':
      case 'spinBox':
      case 'doubleSpinBox':
      case 'comboBox':
      case 'textBox':
      case 'lineEdit':
      case 'listBox':
      case 'progressBar':
      case 'horizontalSlider':
      case 'verticalSlider':
      case 'table':
      case 'image':
        return _exportText(node, indent);
      default:
        return _exportText(node, indent);
    }
  }

  String _exportRadioDefault(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final groupName = _quote(_radioGroupName(node));
    final value = _quote(_radioValue(node));
    return node.props['selected'] == true
        ? '$space self.radio_group_values.setdefault($groupName, $value)'
        : '$space self.radio_group_values.setdefault($groupName, None)';
  }

  String _exportRadio(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final groupName = _quote(_radioGroupName(node));
    final value = _quote(_radioValue(node));
    return '''ft.RadioGroup(
$space    value=self.radio_group_values.get($groupName),
$space    data=$groupName,
$space    on_change=self.${_eventHandlerName(node, 'on_change')},
$space    content=ft.Radio(
$space        label=${_quote(node.props['text']?.toString() ?? 'Radio')},
$space        value=$value,
$space    ),
$space)''';
  }

  String _exportText(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.Text(
$space    value=${_quote(node.props['text']?.toString() ?? '')},
$space    size=${_formatNumber(node.props['fontSize'] ?? 16)},
$space    color=${_quote(node.props['color']?.toString() ?? '#111827')},
$space    font_family=${_quote(node.props['fontFamily']?.toString() ?? 'Arial')},
$space)''';
  }

  String _exportButton(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.ElevatedButton(
$space    content=${_quote(node.props['text']?.toString() ?? 'Button')},
$space    bgcolor=${_quote(node.props['backgroundColor']?.toString() ?? '#2563EB')},
$space    color=${_quote(node.props['foregroundColor']?.toString() ?? '#FFFFFF')},
$space    on_click=self.${_eventHandlerName(node, 'on_click')},
$space)''';
  }

  String _exportContainer(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final children = node.children
        .map((child) => _exportPositionedNode(child, indent + 12))
        .join('\n');
    final content = node.children.isEmpty
        ? 'None'
        : '''ft.Stack(
$space        controls=[
$children
$space        ],
$space    )''';
    return '''ft.Container(
$space    bgcolor=${_quote(node.props['backgroundColor']?.toString() ?? '#F8FAFC')},
$space    border=ft.border.all(1, ${_quote(node.props['borderColor']?.toString() ?? '#94A3B8')}),
$space    border_radius=${_formatNumber(node.props['borderRadius'] ?? 6)},
$space    padding=${_formatNumber(node.props['padding'] ?? 0)},
$space    content=$content,
$space)''';
  }

  String _exportFlex(WidgetNode node, int indent, String controlName) {
    final space = ' ' * indent;
    final controls = node.children
        .map(
          (child) => '${' ' * (indent + 8)}${_exportSized(child, indent + 8)},',
        )
        .join('\n');
    return '''ft.Container(
$space    bgcolor=${_quote(node.props['backgroundColor']?.toString() ?? '#FFFFFF')},
$space    border=ft.border.all(1, ${_quote(node.props['borderColor']?.toString() ?? '#CBD5E1')}),
$space    padding=${_formatNumber(node.props['padding'] ?? 8)},
$space    content=ft.$controlName(
$space        spacing=${_formatNumber(node.props['gap'] ?? 8)},
$space        controls=[
$controls
$space        ],
$space    ),
$space)''';
  }

  String _exportSized(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.Container(
$space    width=${_formatNumber(node.width)},
$space    height=${_formatNumber(node.height)},
$space    content=self.${_memberName(node)},
$space)''';
  }

  String _exportEventHandlers(List<WidgetNode> nodes) {
    final lines = <String>[];
    void collect(WidgetNode node) {
      switch (node.type) {
        case 'button':
          lines.add('''    def ${_eventHandlerName(node, 'on_click')}(self, e):
        # 여기에 ${_memberName(node)}의 클릭 이벤트를 구현합니다.
        pass
''');
          break;
        case 'radioButton':
          lines.add('''    def ${_eventHandlerName(node, 'on_change')}(self, e):
        # 여기에 ${_memberName(node)}의 변경 이벤트를 구현합니다.
        self.radio_group_values[e.control.data] = e.control.value
''');
          break;
        default:
          break;
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

  String _radioGroupName(WidgetNode node) =>
      node.props['groupName']?.toString().isNotEmpty == true
          ? node.props['groupName'].toString()
          : 'default';

  String _radioValue(WidgetNode node) =>
      node.props['radioValue']?.toString().isNotEmpty == true
          ? node.props['radioValue'].toString()
          : node.id;
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

  String _memberName(WidgetNode node) {
    final raw = node.props['memberName']?.toString() ??
        node.props['name']?.toString() ??
        node.id;
    final compact = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    final safe = compact.isEmpty ? node.id : compact;
    return RegExp(r'^[0-9]').hasMatch(safe) ? 'control_$safe' : safe;
  }

  String _eventHandlerName(WidgetNode node, String suffix) =>
      '${_memberName(node)}_$suffix';
}
