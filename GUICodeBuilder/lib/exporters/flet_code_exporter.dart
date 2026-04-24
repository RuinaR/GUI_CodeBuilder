import '../models/export_format.dart';
import '../models/ir_document.dart';
import '../models/widget_node.dart';
import 'code_exporter.dart';

part 'widget_generators/flet_widget_generators.dart';

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
class $className:
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
${nodes.where((node) => node.type != 'radioButton').map((node) => _exportPositionedNode(node, 16)).join('\n')}
${_exportRadioGroups(nodes, 16, width, height)}
            ],
        )
        page.add(self.canvas)

    def release(self, page: ft.Page):
        if self.canvas in page.controls:
            page.controls.remove(self.canvas)
            page.update()

${_exportEventHandlers(nodes)}


def main(page: ft.Page):
    generated_page = $className()
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
    ft.run(main=main)
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
      '        self.canvas: ft.Stack | None = None',
      '        self.radio_group_values: dict[str, str | None] = {}',
    ];
    void collect(WidgetNode node) {
      lines.add(
          '        self.${_memberName(node)}: ${_fletType(node)} | None = None');
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
      lines.add(
          '$space' 'self.${_memberName(node)} = ${_exportRadio(node, indent)}');
      return lines.join('\n');
    }
    lines.add(
      '$space'
      'self.${_memberName(node)} = ${_exportControl(node, indent)}',
    );
    return lines.join('\n');
  }

  String _exportControl(WidgetNode node, int indent) {
    return _fletWidgetGenerators
        .firstWhere((generator) => generator.supports(node.type))
        .export(this, node, indent);
  }

  String _exportRadioDefault(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final groupName = _quote(_radioGroupName(node));
    final value = _quote(_radioValue(node));
    return node.props['selected'] == true
        ? '${space}self.radio_group_values.setdefault($groupName, $value)'
        : '${space}self.radio_group_values.setdefault($groupName, None)';
  }

  String _exportRadio(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final value = _quote(_radioValue(node));
    return '''ft.Radio(
$space    label=${_quote(node.props['text']?.toString() ?? 'Radio')},
$space    value=$value,
$space)''';
  }

  String _exportRadioGroups(
      List<WidgetNode> nodes, int indent, String width, String height) {
    final grouped = <String, List<WidgetNode>>{};
    for (final node in nodes.where((node) => node.type == 'radioButton')) {
      grouped.putIfAbsent(_radioGroupName(node), () => []).add(node);
    }
    final space = ' ' * indent;
    final blocks = <String>[];
    for (final entry in grouped.entries) {
      final groupName = _quote(entry.key);
      final minX =
          entry.value.map((node) => node.x).reduce((a, b) => a < b ? a : b);
      final minY =
          entry.value.map((node) => node.y).reduce((a, b) => a < b ? a : b);
      final maxX = entry.value
          .map((node) => node.x + node.width)
          .reduce((a, b) => a > b ? a : b);
      final maxY = entry.value
          .map((node) => node.y + node.height)
          .reduce((a, b) => a > b ? a : b);
      final controls = entry.value.map((node) {
        final childSpace = ' ' * (indent + 12);
        return '$childSpace self.${_memberName(node)},';
      }).join('\n');
      blocks.add('''${space}ft.Container(
$space    left=${_formatNumber(minX)},
$space    top=${_formatNumber(minY)},
$space    width=${_formatNumber(maxX - minX)},
$space    height=${_formatNumber(maxY - minY)},
$space    content=ft.RadioGroup(
$space        value=self.radio_group_values.get($groupName),
$space        data=$groupName,
$space        on_change=self.${_radioGroupHandlerName(entry.key)},
$space        content=ft.Column(
$space            spacing=2,
$space            controls=[
$controls
$space            ],
$space        ),
$space    ),
$space),''');
    }
    return blocks.join('\n');
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

  String _exportCheckBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.Checkbox(
$space    label=${_quote(node.props['text']?.toString() ?? 'Check')},
$space    value=${node.props['checked'] == true ? 'True' : 'False'},
$space)''';
  }

  String _exportNumberInput(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.TextField(
$space    value=${_quote((node.props['value'] ?? 0).toString())},
$space    keyboard_type=ft.KeyboardType.NUMBER,
$space)''';
  }

  String _exportComboBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final options = _items(node)
        .map((item) =>
            '${' ' * (indent + 8)}ft.dropdown.Option(${_quote(item)}),')
        .join('\n');
    return '''ft.Dropdown(
$space    value=${_quote(node.props['value']?.toString() ?? '')},
$space    options=[
$options
$space    ],
$space)''';
  }

  String _exportTextBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.TextField(
$space    value=${_quote(node.props['text']?.toString() ?? '')},
$space    multiline=True,
$space    min_lines=3,
$space    max_lines=8,
$space)''';
  }

  String _exportLineEdit(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.TextField(
$space    value=${_quote(node.props['text']?.toString() ?? '')},
$space    hint_text=${_quote(node.props['placeholder']?.toString() ?? '')},
$space)''';
  }

  String _exportListBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final controls = _items(node)
        .map((item) => '${' ' * (indent + 8)}ft.Text(${_quote(item)}),')
        .join('\n');
    return '''ft.ListView(
$space    controls=[
$controls
$space    ],
$space)''';
  }

  String _exportProgressBar(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.ProgressBar(
$space    value=${_progressValue(node)},
$space)''';
  }

  String _exportSlider(WidgetNode node, int indent, bool vertical) {
    final space = ' ' * indent;
    if (!vertical) {
      return '''ft.Slider(
$space    value=${_formatNumber(node.props['value'] ?? 0)},
$space    min=${_formatNumber(node.props['min'] ?? 0)},
$space    max=${_formatNumber(node.props['max'] ?? 100)},
$space)''';
    }
    return '''ft.Container(
$space    content=ft.Slider(
$space        value=${_formatNumber(node.props['value'] ?? 0)},
$space        min=${_formatNumber(node.props['min'] ?? 0)},
$space        max=${_formatNumber(node.props['max'] ?? 100)},
$space        rotate=ft.Rotate(angle=-1.5708),
$space    ),
$space)''';
  }

  String _exportTable(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final columns = _csv(node.props['columns']?.toString() ?? 'Name,Value');
    final rows = _tableRows(node);
    final columnCode = columns
        .map((item) =>
            '${' ' * (indent + 8)}ft.DataColumn(ft.Text(${_quote(item)})),')
        .join('\n');
    final rowCode = rows.map((row) {
      final cells = columns.asMap().entries.map((entry) {
        final value = entry.key < row.length ? row[entry.key] : '';
        return 'ft.DataCell(ft.Text(${_quote(value)}))';
      }).join(', ');
      return '${' ' * (indent + 8)}ft.DataRow(cells=[$cells]),';
    }).join('\n');
    return '''ft.DataTable(
$space    columns=[
$columnCode
$space    ],
$space    rows=[
$rowCode
$space    ],
$space)''';
  }

  String _exportImage(WidgetNode node, int indent) {
    final src = node.props['src']?.toString() ?? '';
    if (src.isEmpty) {
      return _exportText(node, indent);
    }
    final space = ' ' * indent;
    return '''ft.Image(
$space    src=${_quote(src)},
$space    fit=ft.BoxFit.COVER,
$space)''';
  }

  String _exportGroupBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final content = _stackContent(node, indent + 8);
    return '''ft.Container(
$space    border=ft.border.all(1, ${_quote(node.props['borderColor']?.toString() ?? '#CBD5E1')}),
$space    border_radius=${_formatNumber(node.props['borderRadius'] ?? 6)},
$space    padding=8,
$space    content=ft.Column(
$space        spacing=6,
$space        controls=[
$space            ft.Text(${_quote(node.props['title']?.toString() ?? 'Group')}, weight=ft.FontWeight.BOLD),
$space            $content,
$space        ],
$space    ),
$space)''';
  }

  String _exportTabs(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final tabs = _csv(node.props['tabs']?.toString() ?? 'Tab 1,Tab 2');
    final tabControls = tabs
        .map((tab) => '${' ' * (indent + 12)}ft.Tab(label=${_quote(tab)}),')
        .join('\n');
    final viewContent = _stackContent(node, indent + 12);
    final views =
        tabs.map((_) => '${' ' * (indent + 12)}$viewContent,').join('\n');
    return '''ft.Tabs(
$space    length=${tabs.isEmpty ? 1 : tabs.length},
$space    content=ft.Column(
$space        controls=[
$space            ft.TabBar(
$space                tabs=[
$tabControls
$space                ],
$space            ),
$space            ft.TabBarView(
$space                controls=[
$views
$space                ],
$space            ),
$space        ],
$space    ),
$space)''';
  }

  String _exportScrollArea(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final content = _stackContent(node, indent + 4);
    return '''ft.Column(
$space    scroll=ft.ScrollMode.AUTO,
$space    controls=[
$space        $content,
$space    ],
$space)''';
  }

  String _stackContent(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final children = [
      node.children
          .where((child) => child.type != 'radioButton')
          .map((child) => _exportPositionedNode(child, indent + 8))
          .join('\n'),
      _exportRadioGroups(
        node.children,
        indent + 8,
        _formatNumber(node.width),
        _formatNumber(node.height),
      ),
    ].where((part) => part.trim().isNotEmpty).join('\n');
    return '''ft.Stack(
$space    width=${_formatNumber(node.width)},
$space    height=${_formatNumber(node.height)},
$space    controls=[
$children
$space    ],
$space)''';
  }

  String _exportContainer(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final content =
        node.children.isEmpty ? 'None' : _stackContent(node, indent + 4);
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
    final controls = [
      node.children
          .where((child) => child.type != 'radioButton')
          .map(
            (child) =>
                '${' ' * (indent + 8)}${_exportSized(child, indent + 8)},',
          )
          .join('\n'),
      _exportInlineRadioGroups(node.children, indent + 8),
    ].where((part) => part.trim().isNotEmpty).join('\n');
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

  String _exportInlineRadioGroups(List<WidgetNode> nodes, int indent) {
    final grouped = <String, List<WidgetNode>>{};
    for (final node in nodes.where((node) => node.type == 'radioButton')) {
      grouped.putIfAbsent(_radioGroupName(node), () => []).add(node);
    }
    final space = ' ' * indent;
    return grouped.entries.map((entry) {
      final groupName = _quote(entry.key);
      final controls = entry.value
          .map((node) => '${' ' * (indent + 12)}self.${_memberName(node)},')
          .join('\n');
      return '''${space}ft.RadioGroup(
$space    value=self.radio_group_values.get($groupName),
$space    data=$groupName,
$space    on_change=self.${_radioGroupHandlerName(entry.key)},
$space    content=ft.Column(
$space        spacing=2,
$space        controls=[
$controls
$space        ],
$space    ),
$space),''';
    }).join('\n');
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
      if (node.type == 'button') {
        lines.add('''    def ${_eventHandlerName(node, 'on_click')}(self, e):
        # 여기에 ${_memberName(node)}의 클릭 이벤트를 구현합니다.
        pass
''');
      }
      for (final child in node.children) {
        collect(child);
      }
    }

    for (final node in nodes) {
      collect(node);
    }
    for (final groupName in _radioGroupNames(nodes)) {
      lines.add('''    def ${_radioGroupHandlerName(groupName)}(self, e):
        # 여기에 $groupName 라디오 그룹의 변경 이벤트를 구현합니다.
        self.radio_group_values[e.control.data] = e.control.value
''');
    }
    return lines.join('\n');
  }

  List<WidgetNode> _flattenRadioNodes(List<WidgetNode> nodes) {
    final result = <WidgetNode>[];
    void collect(WidgetNode node) {
      if (node.type == 'radioButton') {
        result.add(node);
      }
      for (final child in node.children) {
        collect(child);
      }
    }

    for (final node in nodes) {
      collect(node);
    }
    return result;
  }

  List<String> _radioGroupNames(List<WidgetNode> nodes) =>
      _flattenRadioNodes(nodes).map(_radioGroupName).toSet().toList();

  String _radioGroupHandlerName(String groupName) =>
      '${groupName.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')}_radio_group_on_change';

  String _fletType(WidgetNode node) {
    const typeMap = <String, String>{
      'button': 'ft.ElevatedButton',
      'radioButton': 'ft.Radio',
      'tabs': 'ft.Tabs',
    };
    return typeMap[node.type] ?? 'ft.Control';
  }

  String _radioGroupName(WidgetNode node) =>
      node.props['groupName']?.toString().isNotEmpty == true
          ? node.props['groupName'].toString()
          : 'default';

  String _radioValue(WidgetNode node) =>
      node.props['radioValue']?.toString().isNotEmpty == true
          ? node.props['radioValue'].toString()
          : node.id;

  List<String> _items(WidgetNode node) =>
      _csv(node.props['items']?.toString() ?? '');

  List<String> _csv(String text) => text
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  List<List<String>> _tableRows(WidgetNode node) =>
      (node.props['rows']?.toString() ?? '')
          .split(';')
          .where((row) => row.trim().isNotEmpty)
          .map(_csv)
          .toList();

  String _progressValue(WidgetNode node) {
    final value = double.tryParse((node.props['value'] ?? 0).toString()) ?? 0;
    final max = double.tryParse((node.props['max'] ?? 100).toString()) ?? 100;
    if (max <= 0) {
      return '0';
    }
    return (value / max).clamp(0, 1).toStringAsFixed(3);
  }

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
