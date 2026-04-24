part of '../html_css_exporter.dart';

// HTML 요소별 코드 생성 전략이다.
abstract class HtmlWidgetGenerator {
  const HtmlWidgetGenerator();
  bool supports(String type);
  String export(HtmlCssExporter exporter, WidgetNode node, int indent);
}

class HtmlTypedGenerator extends HtmlWidgetGenerator {
  const HtmlTypedGenerator(this.types, this.builder);
  final Set<String> types;
  final String Function(HtmlCssExporter exporter, WidgetNode node, int indent)
      builder;

  @override
  bool supports(String type) => types.isEmpty || types.contains(type);

  @override
  String export(HtmlCssExporter exporter, WidgetNode node, int indent) =>
      builder(exporter, node, indent);
}

final _htmlWidgetGenerators = <HtmlWidgetGenerator>[
  HtmlTypedGenerator(
      {'button'},
      (e, n, i) =>
          '${' ' * i}<button>${e._escape(n.props['text']?.toString() ?? n.displayName)}</button>'),
  HtmlTypedGenerator({'radioButton'}, (e, n, i) {
    final space = ' ' * i;
    final childSpace = ' ' * (i + 2);
    final checked = n.props['selected'] == true ? ' checked' : '';
    return '''$space<label class="control-label">
$childSpace<input type="radio" name="${e._escape(e._radioGroupName(n))}" value="${e._escape(e._radioValue(n))}"$checked>
$childSpace<span>${e._escape(n.props['text']?.toString() ?? n.displayName)}</span>
$space</label>''';
  }),
  HtmlTypedGenerator({'checkBox'}, (e, n, i) {
    final space = ' ' * i;
    final childSpace = ' ' * (i + 2);
    final checked = n.props['checked'] == true ? ' checked' : '';
    return '''$space<label class="control-label">
$childSpace<input type="checkbox"$checked>
$childSpace<span>${e._escape(n.props['text']?.toString() ?? n.displayName)}</span>
$space</label>''';
  }),
  HtmlTypedGenerator(
      {'spinBox'},
      (e, n, i) =>
          '${' ' * i}<input type="number" value="${n.props['value'] ?? 0}" min="${n.props['min'] ?? 0}" max="${n.props['max'] ?? 100}">'),
  HtmlTypedGenerator(
      {'doubleSpinBox'},
      (e, n, i) =>
          '${' ' * i}<input type="number" step="0.01" value="${n.props['value'] ?? 0}" min="${n.props['min'] ?? 0}" max="${n.props['max'] ?? 100}">'),
  HtmlTypedGenerator({'comboBox'}, (e, n, i) {
    final space = ' ' * i;
    final childSpace = ' ' * (i + 2);
    final current = n.props['value']?.toString();
    final options = e
        ._items(n)
        .map((item) =>
            '$childSpace<option${item == current ? ' selected' : ''}>${e._escape(item)}</option>')
        .join('\n');
    return '''$space<select>
$options
$space</select>''';
  }),
  HtmlTypedGenerator(
      {'textBox'},
      (e, n, i) =>
          '${' ' * i}<textarea>${e._escape(n.props['text']?.toString() ?? n.displayName)}</textarea>'),
  HtmlTypedGenerator(
      {'lineEdit'},
      (e, n, i) =>
          '${' ' * i}<input type="text" value="${e._escape(n.props['text']?.toString() ?? '')}" placeholder="${e._escape(n.props['placeholder']?.toString() ?? '')}">'),
  HtmlTypedGenerator({'listBox'}, (e, n, i) {
    final space = ' ' * i;
    final childSpace = ' ' * (i + 2);
    final options = e
        ._items(n)
        .map((item) => '$childSpace<option>${e._escape(item)}</option>')
        .join('\n');
    return '''$space<select multiple>
$options
$space</select>''';
  }),
  HtmlTypedGenerator({'table'}, (e, n, i) => e._table(n, i)),
  HtmlTypedGenerator(
      {'progressBar'},
      (e, n, i) =>
          '${' ' * i}<progress max="${n.props['max'] ?? 100}" value="${n.props['value'] ?? 0}"></progress>'),
  HtmlTypedGenerator(
      {'horizontalSlider'},
      (e, n, i) =>
          '${' ' * i}<input type="range" min="${n.props['min'] ?? 0}" max="${n.props['max'] ?? 100}" value="${n.props['value'] ?? 0}">'),
  HtmlTypedGenerator(
      {'verticalSlider'},
      (e, n, i) =>
          '${' ' * i}<input class="vertical-slider" type="range" min="${n.props['min'] ?? 0}" max="${n.props['max'] ?? 100}" value="${n.props['value'] ?? 0}">'),
  HtmlTypedGenerator({'image'}, (e, n, i) {
    final space = ' ' * i;
    final src = n.props['src']?.toString() ?? '';
    final text = e._escape(n.props['text']?.toString() ?? n.displayName);
    return src.isEmpty
        ? '$space<div>$text</div>'
        : '$space<img src="${e._escape(src)}" alt="$text" style="width:100%;height:100%;object-fit:cover">';
  }),
  HtmlTypedGenerator(
      {'container', 'groupBox', 'tabs', 'scrollArea', 'row', 'column'},
      (e, n, i) {
    final title = n.props['title'];
    return title == null
        ? ''
        : '${' ' * i}<strong>${e._escape(title.toString())}</strong>';
  }),
  HtmlTypedGenerator(
      <String>{},
      (e, n, i) =>
          '${' ' * i}<div>${e._escape(n.props['text']?.toString() ?? n.displayName)}</div>'),
];
