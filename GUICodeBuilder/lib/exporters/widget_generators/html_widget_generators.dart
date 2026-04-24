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
          '${' ' * i}<button>${e._escape(n.payload.string('text', fallback: n.displayName))}</button>'),
  HtmlTypedGenerator({'radioButton'}, (e, n, i) {
    final space = ' ' * i;
    final childSpace = ' ' * (i + 2);
    final checked = n.payload.boolean('selected') ? ' checked' : '';
    return '''$space<label class="control-label">
$childSpace<input type="radio" name="${e._escape(e._radioGroupName(n))}" value="${e._escape(e._radioValue(n))}"$checked>
$childSpace<span>${e._escape(n.payload.string('text', fallback: n.displayName))}</span>
$space</label>''';
  }),
  HtmlTypedGenerator({'checkBox'}, (e, n, i) {
    final space = ' ' * i;
    final childSpace = ' ' * (i + 2);
    final checked = n.payload.boolean('checked') ? ' checked' : '';
    return '''$space<label class="control-label">
$childSpace<input type="checkbox"$checked>
$childSpace<span>${e._escape(n.payload.string('text', fallback: n.displayName))}</span>
$space</label>''';
  }),
  HtmlTypedGenerator(
      {'spinBox'},
      (e, n, i) =>
          '${' ' * i}<input type="number" value="${n.payload.number('value')}" min="${n.payload.number('min')}" max="${n.payload.number('max', fallback: 100)}">'),
  HtmlTypedGenerator(
      {'doubleSpinBox'},
      (e, n, i) =>
          '${' ' * i}<input type="number" step="0.01" value="${n.payload.number('value')}" min="${n.payload.number('min')}" max="${n.payload.number('max', fallback: 100)}">'),
  HtmlTypedGenerator({'comboBox'}, (e, n, i) {
    final space = ' ' * i;
    final childSpace = ' ' * (i + 2);
    final current = n.payload.string('value');
    final options = e
        ._items(n)
        .map((item) =>
            '$childSpace<option value="${e._escape(item)}"${item == current ? ' selected' : ''}>${e._escape(item)}</option>')
        .join('\n');
    return '''$space<select>
$options
$space</select>''';
  }),
  HtmlTypedGenerator(
      {'textBox'},
      (e, n, i) =>
          '${' ' * i}<textarea>${e._escape(n.payload.string('text', fallback: n.displayName))}</textarea>'),
  HtmlTypedGenerator(
      {'lineEdit'},
      (e, n, i) =>
          '${' ' * i}<input type="text" value="${e._escape(n.payload.string('text'))}" placeholder="${e._escape(n.payload.string('placeholder'))}">'),
  HtmlTypedGenerator({'listBox'}, (e, n, i) {
    final space = ' ' * i;
    final childSpace = ' ' * (i + 2);
    final options = e
        ._items(n)
        .map((item) =>
            '$childSpace<option value="${e._escape(item)}">${e._escape(item)}</option>')
        .join('\n');
    return '''$space<select multiple>
$options
$space</select>''';
  }),
  HtmlTypedGenerator({'table'}, (e, n, i) => e._table(n, i)),
  HtmlTypedGenerator(
      {'progressBar'},
      (e, n, i) =>
          '${' ' * i}<progress max="${n.payload.number('max', fallback: 100)}" value="${n.payload.number('value')}"></progress>'),
  HtmlTypedGenerator(
      {'horizontalSlider'},
      (e, n, i) =>
          '${' ' * i}<input type="range" min="${n.payload.number('min')}" max="${n.payload.number('max', fallback: 100)}" value="${n.payload.number('value')}">'),
  HtmlTypedGenerator(
      {'verticalSlider'},
      (e, n, i) =>
          '${' ' * i}<input class="vertical-slider" type="range" min="${n.payload.number('min')}" max="${n.payload.number('max', fallback: 100)}" value="${n.payload.number('value')}">'),
  HtmlTypedGenerator({'image'}, (e, n, i) {
    final space = ' ' * i;
    final src = n.payload.string('src');
    final text = e._escape(n.payload.string('text', fallback: n.displayName));
    return src.isEmpty
        ? '$space<div>$text</div>'
        : '$space<img src="${e._escape(src)}" alt="$text" style="width:100%;height:100%;object-fit:cover">';
  }),
  HtmlTypedGenerator({'tabs'}, (e, n, i) {
    final space = ' ' * i;
    final childSpace = ' ' * (i + 2);
    final tabs = e._csv(n.payload.string('tabs', fallback: 'Tab 1,Tab 2'));
    final buttons = tabs
        .map((tab) =>
            '$childSpace<button type="button">${e._escape(tab)}</button>')
        .join('\n');
    return '''$space<div class="tabs" role="tablist">
$buttons
$space</div>''';
  }),
  HtmlTypedGenerator({'container', 'groupBox', 'scrollArea', 'row', 'column'},
      (e, n, i) {
    final title = n.payload.string('title');
    return title.isEmpty
        ? ''
        : '${' ' * i}<strong>${e._escape(title)}</strong>';
  }),
  HtmlTypedGenerator(
      <String>{},
      (e, n, i) =>
          '${' ' * i}<div>${e._escape(n.payload.string('text', fallback: n.displayName))}</div>'),
];
