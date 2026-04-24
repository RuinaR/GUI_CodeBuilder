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
${nodes.where((node) => !node.isRadioButton).map((node) => _exportPositionedNode(node, 16)).join('\n')}
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
    if (node.isRadioButton) {
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
    return node.payload.boolean('selected')
        ? '${space}self.radio_group_values.setdefault($groupName, $value)'
        : '${space}self.radio_group_values.setdefault($groupName, None)';
  }

  String _exportRadio(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final value = _quote(_radioValue(node));
    return '''ft.Radio(
$space    label=${_quote(node.payload.string('text', fallback: 'Radio'))},
$space    value=$value,
$space)''';
  }

  String _exportRadioGroups(
      List<WidgetNode> nodes, int indent, String width, String height) {
    final grouped = <String, List<WidgetNode>>{};
    for (final node in nodes.where((node) => node.isRadioButton)) {
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
$space    value=${_quote(node.payload.string('text'))},
$space    size=${_formatNumber(node.payload.number('fontSize', fallback: 16))},
$space    color=${_quote(node.payload.string('color', fallback: '#111827'))},
$space    font_family=${_quote(node.payload.string('fontFamily', fallback: 'Arial'))},
$space)''';
  }

  String _exportButton(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.ElevatedButton(
$space    content=${_quote(node.payload.string('text', fallback: 'Button'))},
$space    bgcolor=${_quote(node.payload.string('backgroundColor', fallback: '#2563EB'))},
$space    color=${_quote(node.payload.string('foregroundColor', fallback: '#FFFFFF'))},
$space    on_click=self.${_eventHandlerName(node, 'on_click')},
$space)''';
  }

  String _exportCheckBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.Checkbox(
$space    label=${_quote(node.payload.string('text', fallback: 'Check'))},
$space    value=${node.payload.boolean('checked') ? 'True' : 'False'},
$space    on_change=self.${_eventHandlerName(node, 'on_change')},
$space)''';
  }

  String _exportNumberInput(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.TextField(
$space    value=${_quote(node.payload.string('value', fallback: '0'))},
$space    keyboard_type=ft.KeyboardType.NUMBER,
$space    on_change=self.${_eventHandlerName(node, 'on_change')},
$space)''';
  }

  String _exportComboBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final items = _items(node);
    final payloadValue = node.payload.string('value');
    final selected = items.contains(payloadValue)
        ? payloadValue
        : (items.isEmpty ? '' : items.first);
    final options = items
        .map((item) =>
            '${' ' * (indent + 8)}ft.dropdown.Option(${_quote(item)}),')
        .join('\n');
    return '''ft.Dropdown(
$space    value=${selected.isEmpty ? 'None' : _quote(selected)},
$space    options=[
$options
$space    ],
$space    on_select=self.${_eventHandlerName(node, 'on_select')},
$space)''';
  }

  String _exportTextBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.TextField(
$space    value=${_quote(node.payload.string('text'))},
$space    multiline=True,
$space    min_lines=3,
$space    max_lines=8,
$space    on_change=self.${_eventHandlerName(node, 'on_change')},
$space)''';
  }

  String _exportLineEdit(WidgetNode node, int indent) {
    final space = ' ' * indent;
    return '''ft.TextField(
$space    value=${_quote(node.payload.string('text'))},
$space    hint_text=${_quote(node.payload.string('placeholder'))},
$space    on_change=self.${_eventHandlerName(node, 'on_change')},
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
    final (min, max) = _sliderRange(node);
    final value = node.payload.number('value').clamp(min, max);
    if (!vertical) {
      return '''ft.Slider(
$space    value=${_formatNumber(value)},
$space    min=${_formatNumber(min)},
$space    max=${_formatNumber(max)},
$space    width=${_formatNumber(node.width)},
$space    padding=0,
$space    on_change=self.${_eventHandlerName(node, 'on_change')},
$space)''';
    }
    final left = (node.width - node.height) / 2;
    final top = (node.height - node.width) / 2;
    return '''ft.Container(
$space    width=${_formatNumber(node.width)},
$space    height=${_formatNumber(node.height)},
$space    clip_behavior=ft.ClipBehavior.NONE,
$space    content=ft.Stack(
$space        width=${_formatNumber(node.width)},
$space        height=${_formatNumber(node.height)},
$space        clip_behavior=ft.ClipBehavior.NONE,
$space        controls=[
$space            ft.Slider(
$space                value=${_formatNumber(value)},
$space                min=${_formatNumber(min)},
$space                max=${_formatNumber(max)},
$space                width=${_formatNumber(node.height)},
$space                height=${_formatNumber(node.width)},
$space                left=${_formatNumber(left)},
$space                top=${_formatNumber(top)},
$space                padding=0,
$space                on_change=self.${_eventHandlerName(node, 'on_change')},
$space                rotate=ft.Rotate(angle=-1.5708, alignment=ft.Alignment(0, 0)),
$space            ),
$space        ],
$space    ),
$space)''';
  }

  String _exportTable(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final columns =
        _csv(node.payload.string('columns', fallback: 'Name,Value'));
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
    final src = node.payload.string('src');
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
$space    border=ft.border.all(1, ${_quote(node.payload.string('borderColor', fallback: '#CBD5E1'))}),
$space    border_radius=${_formatNumber(node.payload.number('borderRadius', fallback: 6))},
$space    padding=8,
$space    content=ft.Column(
$space        spacing=6,
$space        controls=[
$space            ft.Text(${_quote(node.payload.string('title', fallback: 'Group'))}, weight=ft.FontWeight.BOLD),
$space            $content,
$space        ],
$space    ),
$space)''';
  }

  String _exportTabs(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final tabs = _csv(node.payload.string('tabs', fallback: 'Tab 1,Tab 2'));
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
          .where((child) => !child.isRadioButton)
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
$space    bgcolor=${_quote(node.payload.string('backgroundColor', fallback: '#F8FAFC'))},
$space    border=ft.border.all(1, ${_quote(node.payload.string('borderColor', fallback: '#94A3B8'))}),
$space    border_radius=${_formatNumber(node.payload.number('borderRadius', fallback: 6))},
$space    padding=${_formatNumber(node.payload.number('padding'))},
$space    content=$content,
$space)''';
  }

  String _exportFlex(WidgetNode node, int indent, String controlName) {
    final space = ' ' * indent;
    final controls = [
      node.children
          .where((child) => !child.isRadioButton)
          .map(
            (child) =>
                '${' ' * (indent + 8)}${_exportSized(child, indent + 8)},',
          )
          .join('\n'),
      _exportInlineRadioGroups(node.children, indent + 8),
    ].where((part) => part.trim().isNotEmpty).join('\n');
    return '''ft.Container(
$space    bgcolor=${_quote(node.payload.string('backgroundColor', fallback: '#FFFFFF'))},
$space    border=ft.border.all(1, ${_quote(node.payload.string('borderColor', fallback: '#CBD5E1'))}),
$space    padding=${_formatNumber(node.payload.number('padding', fallback: 8))},
$space    content=ft.$controlName(
$space        spacing=${_formatNumber(node.payload.number('gap', fallback: 8))},
$space        controls=[
$controls
$space        ],
$space    ),
$space)''';
  }

  String _exportInlineRadioGroups(List<WidgetNode> nodes, int indent) {
    final grouped = <String, List<WidgetNode>>{};
    for (final node in nodes.where((node) => node.isRadioButton)) {
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
      if (node.isButton) {
        lines.add('''    def ${_eventHandlerName(node, 'on_click')}(self, e):
        # 여기에 ${_memberName(node)}의 클릭 이벤트를 구현합니다.
        pass
''');
      }
      if (node.isCheckBox ||
          node.widgetType == WidgetType.spinBox ||
          node.widgetType == WidgetType.doubleSpinBox ||
          node.widgetType == WidgetType.textBox ||
          node.widgetType == WidgetType.lineEdit ||
          node.isSlider) {
        lines.add('''    def ${_eventHandlerName(node, 'on_change')}(self, e):
        # 여기에 ${_memberName(node)}의 변경 이벤트를 구현합니다.
        pass
''');
      }
      if (node.widgetType == WidgetType.comboBox) {
        lines.add('''    def ${_eventHandlerName(node, 'on_select')}(self, e):
        # 여기에 ${_memberName(node)}의 선택 변경 이벤트를 구현합니다.
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
      if (node.isRadioButton) {
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
      node.payload.string('groupName').isNotEmpty
          ? node.payload.string('groupName')
          : 'default';

  String _radioValue(WidgetNode node) =>
      node.payload.string('radioValue').isNotEmpty
          ? node.payload.string('radioValue')
          : node.id;

  List<String> _items(WidgetNode node) => node.payload.csv('items');

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

  String _progressValue(WidgetNode node) {
    final value = node.payload.number('value');
    final max = node.payload.number('max', fallback: 100);
    if (max <= 0) {
      return '0';
    }
    return (value / max).clamp(0, 1).toStringAsFixed(3);
  }

  (double, double) _sliderRange(WidgetNode node) {
    final min = node.payload.number('min');
    final rawMax = node.payload.number('max', fallback: 100);
    final max = rawMax <= min ? min + 1 : rawMax;
    return (min, max);
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
