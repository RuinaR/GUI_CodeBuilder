import '../models/export_format.dart';
import '../models/ir_document.dart';
import '../models/widget_node.dart';
import 'code_exporter.dart';

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

button, select, textarea, input[type="text"], input[type="range"], progress {
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

textarea { resize: none; }
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
    final space = ' ' * indent;
    final childSpace = ' ' * (indent + 2);
    final text = _escape(node.props['text']?.toString() ?? node.displayName);
    switch (node.type) {
      case 'button':
        return '$space<button>$text</button>';
      case 'radioButton':
        final groupName = _escape(_radioGroupName(node));
        final value = _escape(_radioValue(node));
        final checked = node.props['selected'] == true ? ' checked' : '';
        return '''$space<label class="control-label">
$childSpace<input type="radio" name="$groupName" value="$value"$checked>
$childSpace<span>$text</span>
$space</label>''';
      case 'checkBox':
        final checked = node.props['checked'] == true ? ' checked' : '';
        return '''$space<label class="control-label">
$childSpace<input type="checkbox"$checked>
$childSpace<span>$text</span>
$space</label>''';
      case 'comboBox':
        final current = node.props['value']?.toString();
        final options = _items(node)
            .map(
              (item) =>
                  '$childSpace<option${item == current ? ' selected' : ''}>${_escape(item)}</option>',
            )
            .join('\n');
        return '''$space<select>
$options
$space</select>''';
      case 'textBox':
        return '$space<textarea>$text</textarea>';
      case 'lineEdit':
        return '$space<input type="text" value="$text" placeholder="${_escape(node.props['placeholder']?.toString() ?? '')}">';
      case 'progressBar':
        return '$space<progress max="${node.props['max'] ?? 100}" value="${node.props['value'] ?? 0}"></progress>';
      case 'horizontalSlider':
      case 'verticalSlider':
        return '$space<input type="range" min="${node.props['min'] ?? 0}" max="${node.props['max'] ?? 100}" value="${node.props['value'] ?? 0}">';
      case 'image':
        final src = node.props['src']?.toString() ?? '';
        return src.isEmpty
            ? '$space<div>$text</div>'
            : '$space<img src="${_escape(src)}" alt="$text" style="width:100%;height:100%;object-fit:cover">';
      case 'container':
      case 'groupBox':
      case 'tabs':
      case 'scrollArea':
      case 'row':
      case 'column':
        return node.props['title'] == null
            ? ''
            : '$space<strong>${_escape(node.props['title'].toString())}</strong>';
      default:
        return '$space<div>$text</div>';
    }
  }

  String _eventBindings(List<WidgetNode> nodes, int indent) {
    final lines = <String>[];
    void collect(WidgetNode node) {
      final member = _memberName(node);
      final handler = _eventHandlerName(node, 'onChange');
      switch (node.type) {
        case 'button':
          lines.add(
            "${' ' * indent}this.controls['$member']?.querySelector('button')?.addEventListener('click', this.${_eventHandlerName(node, 'onClick')}.bind(this));",
          );
          break;
        case 'radioButton':
          lines.add(
            "${' ' * indent}this.controls['$member']?.querySelector('input[type=\"radio\"]')?.addEventListener('change', this.$handler.bind(this));",
          );
          break;
        case 'checkBox':
          lines.add(
            "${' ' * indent}this.controls['$member']?.querySelector('input[type=\"checkbox\"]')?.addEventListener('change', this.$handler.bind(this));",
          );
          break;
        case 'comboBox':
          lines.add(
            "${' ' * indent}this.controls['$member']?.querySelector('select')?.addEventListener('change', this.$handler.bind(this));",
          );
          break;
        case 'textBox':
          lines.add(
            "${' ' * indent}this.controls['$member']?.querySelector('textarea')?.addEventListener('input', this.$handler.bind(this));",
          );
          break;
        case 'lineEdit':
          lines.add(
            "${' ' * indent}this.controls['$member']?.querySelector('input[type=\"text\"]')?.addEventListener('input', this.$handler.bind(this));",
          );
          break;
        case 'horizontalSlider':
        case 'verticalSlider':
          lines.add(
            "${' ' * indent}this.controls['$member']?.querySelector('input[type=\"range\"]')?.addEventListener('input', this.$handler.bind(this));",
          );
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

  String _eventHandlers(List<WidgetNode> nodes, int indent) {
    final lines = <String>[];
    void collect(WidgetNode node) {
      final space = ' ' * indent;
      switch (node.type) {
        case 'button':
          lines.add(
              "$space${_eventHandlerName(node, 'onClick')}(event) {\n$space  // 여기에 ${_memberName(node)}의 클릭 이벤트를 구현합니다.\n$space}");
          break;
        case 'radioButton':
        case 'checkBox':
        case 'comboBox':
        case 'textBox':
        case 'lineEdit':
        case 'horizontalSlider':
        case 'verticalSlider':
          lines.add(
              "$space${_eventHandlerName(node, 'onChange')}(event) {\n$space  // 여기에 ${_memberName(node)}의 변경 이벤트를 구현합니다.\n$space}");
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
    return lines.isEmpty ? '' : '${lines.join('\n')}\n';
  }

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
