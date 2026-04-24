part of '../flutter_code_exporter.dart';

// Flutter 위젯별 코드 생성 전략이다.
abstract class FlutterWidgetGenerator {
  const FlutterWidgetGenerator();
  bool supports(String type);
  String export(FlutterCodeExporter exporter, WidgetNode node, int indent);
}

class FlutterTypedGenerator extends FlutterWidgetGenerator {
  const FlutterTypedGenerator(this.types, this.builder);
  final Set<String> types;
  final String Function(
      FlutterCodeExporter exporter, WidgetNode node, int indent) builder;

  @override
  bool supports(String type) => types.isEmpty || types.contains(type);

  @override
  String export(FlutterCodeExporter exporter, WidgetNode node, int indent) =>
      builder(exporter, node, indent);
}

final _flutterWidgetGenerators = <FlutterWidgetGenerator>[
  FlutterTypedGenerator({'text'}, (e, n, i) => e._exportText(n, i)),
  FlutterTypedGenerator({'button'}, (e, n, i) => e._exportButton(n, i)),
  FlutterTypedGenerator({'container'}, (e, n, i) => e._exportContainer(n, i)),
  FlutterTypedGenerator({'groupBox'}, (e, n, i) => e._exportGroupBox(n, i)),
  FlutterTypedGenerator({'tabs'}, (e, n, i) => e._exportTabs(n, i)),
  FlutterTypedGenerator({'scrollArea'}, (e, n, i) => e._exportScrollArea(n, i)),
  FlutterTypedGenerator({'row'}, (e, n, i) => e._exportFlex(n, i, 'Row')),
  FlutterTypedGenerator({'column'}, (e, n, i) => e._exportFlex(n, i, 'Column')),
  FlutterTypedGenerator({'radioButton'}, (e, n, i) => e._exportRadio(n, i)),
  FlutterTypedGenerator({'checkBox'}, (e, n, i) => e._exportCheckBox(n, i)),
  FlutterTypedGenerator(
      {'spinBox', 'doubleSpinBox'}, (e, n, i) => e._exportNumberInput(n, i)),
  FlutterTypedGenerator({'comboBox'}, (e, n, i) => e._exportComboBox(n, i)),
  FlutterTypedGenerator({'textBox'}, (e, n, i) => e._exportTextBox(n, i)),
  FlutterTypedGenerator({'lineEdit'}, (e, n, i) => e._exportLineEdit(n, i)),
  FlutterTypedGenerator({'listBox'}, (e, n, i) => e._exportListBox(n, i)),
  FlutterTypedGenerator(
      {'progressBar'}, (e, n, i) => e._exportProgressBar(n, i)),
  FlutterTypedGenerator(
      {'horizontalSlider'}, (e, n, i) => e._exportSlider(n, i, false)),
  FlutterTypedGenerator(
      {'verticalSlider'}, (e, n, i) => e._exportSlider(n, i, true)),
  FlutterTypedGenerator({'table'}, (e, n, i) => e._exportTable(n, i)),
  FlutterTypedGenerator({'image'}, (e, n, i) => e._exportImage(n, i)),
  FlutterTypedGenerator(<String>{}, (e, n, i) => e._exportSimple(n, i, n.type)),
];
