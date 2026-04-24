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
    };
  }

  @override
  String exportPage(Map<String, dynamic> irJson) {
    final document = IrDocument.fromJson(irJson);
    final width = _formatNumber(document.width);
    final height = _formatNumber(document.height);
    final nodes = document.nodes;

    return '''
import flet as ft


# GUI Code Builder에서 생성된 Flet 페이지이다.
class GeneratedFletPage:
    def __init__(self):
${_exportMembers(nodes)}

    def build(self, page: ft.Page):
        page.title = "Generated Page"
        page.window_width = $width
        page.window_height = $height
        page.padding = 0
${nodes.map((node) => _exportMemberAssignment(node, 8)).join('\n')}
        self.canvas = ft.Stack(
            width=$width,
            height=$height,
            controls=[
${nodes.map((node) => _exportPositionedNode(node, 16)).join('\n')}
            ],
        )
        page.add(self.canvas)

    def on_button_click(self, control_id):
        pass


def main(page: ft.Page):
    GeneratedFletPage().build(page)
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

  String _exportMembers(List<WidgetNode> nodes) {
    final lines = <String>['        self.canvas = None'];
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
    lines.add(
      '$space'
      'self.${_memberName(node)} = ${_exportControl(node, indent)}',
    );
    return lines.join('\n');
  }

  String _exportControl(WidgetNode node, int indent) {
    switch (node.type) {
      case WidgetNodeType.text:
        return _exportText(node, indent);
      case WidgetNodeType.button:
        return _exportButton(node, indent);
      case WidgetNodeType.container:
        return _exportContainer(node, indent);
      case WidgetNodeType.row:
        return _exportFlex(node, indent, 'Row');
      case WidgetNodeType.column:
        return _exportFlex(node, indent, 'Column');
    }
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
$space    text=${_quote(node.props['text']?.toString() ?? 'Button')},
$space    bgcolor=${_quote(node.props['backgroundColor']?.toString() ?? '#2563EB')},
$space    color=${_quote(node.props['foregroundColor']?.toString() ?? '#FFFFFF')},
$space    on_click=lambda e: self.on_button_click(${_quote(node.id)}),
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
        .map((child) =>
            '${' ' * (indent + 8)}${_exportSized(child, indent + 8)},')
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
