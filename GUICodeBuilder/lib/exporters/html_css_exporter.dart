import '../models/export_format.dart';
import '../models/ir_document.dart';
import '../models/widget_node.dart';
import 'code_exporter.dart';

part 'widget_generators/html_widget_generators.dart';

// JSON IR을 HTML과 CSS 파일로 변환한다.
class HtmlCssExporter implements CodeExporter {
  @override
  ExportFormat get format => ExportFormat.html;

  @override
  Map<String, String> exportFiles(Map<String, dynamic> irJson) {
    return {
      format.fileName: exportPage(irJson),
      'html_generated_page.css': exportCss(irJson),
      'test_mains/run_html_test.cmd':
          '@echo off\nstart "" "%~dp0..\\html_generated_page.html"\n',
    };
  }

  @override
  String exportPage(Map<String, dynamic> irJson) {
    final document = IrDocument.fromJson(irJson);
    final nodes =
        document.nodes.map((node) => _positionedNode(node, 4)).join('\n');
    return '''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${_escape(document.title)}</title>
  <link rel="stylesheet" href="html_generated_page.css">
</head>
<body>
  <main id="page" class="page" style="width:${_n(document.width)}px;height:${_n(document.height)}px;">
$nodes
  </main>
  <script>
    class ${_safeClassName(document.className)}HtmlPage {
      constructor(root) { this.root = root; this.controls = {}; }
      initialize() {
        this.root.querySelectorAll('[data-member]').forEach((el) => this.controls[el.dataset.member] = el);
${_eventBindings(document.nodes, 8)}
      }
      build() {}
      release() { this.root.remove(); }
${_eventHandlers(document.nodes, 6)}
    }
    const generatedPage = new ${_safeClassName(document.className)}HtmlPage(document.getElementById('page'));
    generatedPage.initialize();
    generatedPage.build();
  </script>
</body>
</html>
''';
  }

  String exportCss(Map<String, dynamic> irJson) {
    return '''
body {
  margin: 0;
  font-family: Arial, sans-serif;
  background: #f3f4f6;
}

.page {
  position: relative;
  margin: 24px auto;
  background: white;
  border: 1px solid #cbd5e1;
  overflow: auto;
}

.node {
  position: absolute;
  box-sizing: border-box;
  overflow: hidden;
}

button, select, textarea, input[type="text"], input[type="number"], input[type="range"], progress, table {
  width: 100%;
  height: 100%;
  box-sizing: border-box;
}

label.control-label {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  height: 100%;
  box-sizing: border-box;
  padding: 0 8px;
  white-space: nowrap;
}

input[type="checkbox"], input[type="radio"] {
  width: 18px;
  height: 18px;
  flex: 0 0 auto;
}

input.vertical-slider {
  writing-mode: vertical-lr;
  direction: rtl;
  width: 100%;
  height: 100%;
}

textarea { resize: none; }
table { border-collapse: collapse; font-size: 13px; }
th, td { border: 1px solid #cbd5e1; padding: 4px 6px; text-align: left; }
img { display: block; }
''';
  }

  String _positionedNode(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final childSpace = ' ' * (indent + 2);
    final member = _memberName(node);
    final control = _control(node, indent + 2);
    final children = node.children
        .map((child) => _positionedNode(child, indent + 2))
        .join('\n');
    final body = [
      if (control.isNotEmpty) control,
      if (children.isNotEmpty) children,
    ].join('\n');
    return '''$space<div
${childSpace}class="node"
${childSpace}data-member="$member"
${childSpace}style="left:${_n(node.x)}px;top:${_n(node.y)}px;width:${_n(node.width)}px;height:${_n(node.height)}px;${_style(node)}">
$body
$space</div>''';
  }

  String _control(WidgetNode node, int indent) {
    return _htmlWidgetGenerators
        .firstWhere((generator) => generator.supports(node.type))
        .export(this, node, indent);
  }

  String _eventBindings(List<WidgetNode> nodes, int indent) {
    final lines = <String>[];
    final selectors = <String, ({String selector, String event})>{
      'radioButton': (selector: 'input[type="radio"]', event: 'change'),
      'checkBox': (selector: 'input[type="checkbox"]', event: 'change'),
      'spinBox': (selector: 'input[type="number"]', event: 'input'),
      'doubleSpinBox': (selector: 'input[type="number"]', event: 'input'),
      'comboBox': (selector: 'select', event: 'change'),
      'textBox': (selector: 'textarea', event: 'input'),
      'lineEdit': (selector: 'input[type="text"]', event: 'input'),
      'horizontalSlider': (selector: 'input[type="range"]', event: 'input'),
      'verticalSlider': (selector: 'input[type="range"]', event: 'input'),
    };
    void collect(WidgetNode node) {
      final member = _memberName(node);
      if (node.type == 'button') {
        lines.add(
          "${' ' * indent}this.controls['$member']?.querySelector('button')?.addEventListener('click', this.${_eventHandlerName(node, 'onClick')}.bind(this));",
        );
      } else {
        final binding = selectors[node.type];
        if (binding != null) {
          lines.add(
            "${' ' * indent}this.controls['$member']?.querySelector('${binding.selector}')?.addEventListener('${binding.event}', this.${_eventHandlerName(node, 'onChange')}.bind(this));",
          );
        }
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

  String _eventHandlers(List<WidgetNode> nodes, int indent) {
    final lines = <String>[];
    const changeTypes = {
      'radioButton',
      'checkBox',
      'spinBox',
      'doubleSpinBox',
      'comboBox',
      'textBox',
      'lineEdit',
      'horizontalSlider',
      'verticalSlider',
    };
    void collect(WidgetNode node) {
      final space = ' ' * indent;
      if (node.type == 'button') {
        lines.add(
            "$space${_eventHandlerName(node, 'onClick')}(event) {\n$space  // 여기에 ${_memberName(node)}의 클릭 이벤트를 구현합니다.\n$space}");
      } else if (changeTypes.contains(node.type)) {
        lines.add(
            "$space${_eventHandlerName(node, 'onChange')}(event) {\n$space  // 여기에 ${_memberName(node)}의 변경 이벤트를 구현합니다.\n$space}");
      }
      for (final child in node.children) {
        collect(child);
      }
    }

    for (final node in nodes) {
      collect(node);
    }
    return lines.isEmpty ? '' : '${lines.join('\n')}\n';
  }

  String _table(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final childSpace = ' ' * (indent + 2);
    final columns = _csv(node.props['columns']?.toString() ?? 'Name,Value');
    final rows = (node.props['rows']?.toString() ?? '')
        .split(';')
        .where((row) => row.trim().isNotEmpty)
        .map(_csv)
        .toList();
    final header = columns
        .map((column) => '$childSpace<th>${_escape(column)}</th>')
        .join('\n');
    final body = rows.map((row) {
      final cells = columns.asMap().entries.map((entry) {
        final value = entry.key < row.length ? row[entry.key] : '';
        return '${' ' * (indent + 4)}<td>${_escape(value)}</td>';
      }).join('\n');
      return '''$childSpace<tr>
$cells
$childSpace</tr>''';
    }).join('\n');
    return '''$space<table>
$childSpace<thead>
$childSpace<tr>
$header
$childSpace</tr>
$childSpace</thead>
$childSpace<tbody>
$body
$childSpace</tbody>
$space</table>''';
  }

  List<String> _csv(String text) => text
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  String _radioGroupName(WidgetNode node) =>
      node.props['groupName']?.toString().isNotEmpty == true
          ? node.props['groupName'].toString()
          : 'default';

  String _radioValue(WidgetNode node) =>
      node.props['radioValue']?.toString().isNotEmpty == true
          ? node.props['radioValue'].toString()
          : node.id;

  String _style(WidgetNode node) {
    final bg = node.props['backgroundColor']?.toString() ?? 'transparent';
    final border = node.props['borderColor']?.toString() ?? '#cbd5e1';
    final radius = node.props['borderRadius'] ?? 0;
    return 'background:$bg;border:1px solid $border;border-radius:${radius}px;';
  }

  List<String> _items(WidgetNode node) =>
      (node.props['items']?.toString() ?? '')
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

  String _memberName(WidgetNode node) {
    final raw = node.props['memberName']?.toString() ??
        node.props['name']?.toString() ??
        node.id;
    final compact = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    return compact.isEmpty ? node.id : compact;
  }

  String _eventHandlerName(WidgetNode node, String suffix) =>
      '${_memberName(node)}_$suffix';

  String _safeClassName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '').isEmpty
          ? 'GeneratedPage'
          : name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');

  String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  String _n(num value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
