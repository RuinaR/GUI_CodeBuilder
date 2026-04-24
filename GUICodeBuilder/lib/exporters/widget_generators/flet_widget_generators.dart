part of '../flet_code_exporter.dart';

// Flet 컨트롤별 코드 생성 전략이다.
abstract class FletWidgetGenerator {
  const FletWidgetGenerator();
  bool supports(String type);
  String export(FletCodeExporter exporter, WidgetNode node, int indent);
}

class FletTypedGenerator extends FletWidgetGenerator {
  const FletTypedGenerator(this.types, this.builder);
  final Set<String> types;
  final String Function(FletCodeExporter exporter, WidgetNode node, int indent)
      builder;

  @override
  bool supports(String type) => types.isEmpty || types.contains(type);

  @override
  String export(FletCodeExporter exporter, WidgetNode node, int indent) =>
      builder(exporter, node, indent);
}

final _fletWidgetGenerators = <FletWidgetGenerator>[
  FletTypedGenerator({'text'}, (e, n, i) => e._exportText(n, i)),
  FletTypedGenerator({'button'}, (e, n, i) => e._exportButton(n, i)),
  FletTypedGenerator({'container'}, (e, n, i) => e._exportContainer(n, i)),
  FletTypedGenerator({'groupBox'}, (e, n, i) => e._exportGroupBox(n, i)),
  FletTypedGenerator({'tabs'}, (e, n, i) => e._exportTabs(n, i)),
  FletTypedGenerator({'scrollArea'}, (e, n, i) => e._exportScrollArea(n, i)),
  FletTypedGenerator({'row'}, (e, n, i) => e._exportFlex(n, i, 'Row')),
  FletTypedGenerator({'column'}, (e, n, i) => e._exportFlex(n, i, 'Column')),
  FletTypedGenerator({'radioButton'}, (e, n, i) => e._exportRadio(n, i)),
  FletTypedGenerator({'checkBox'}, (e, n, i) => e._exportCheckBox(n, i)),
  FletTypedGenerator(
      {'spinBox', 'doubleSpinBox'}, (e, n, i) => e._exportNumberInput(n, i)),
  FletTypedGenerator({'comboBox'}, (e, n, i) => e._exportComboBox(n, i)),
  FletTypedGenerator({'textBox'}, (e, n, i) => e._exportTextBox(n, i)),
  FletTypedGenerator({'lineEdit'}, (e, n, i) => e._exportLineEdit(n, i)),
  FletTypedGenerator({'listBox'}, (e, n, i) => e._exportListBox(n, i)),
  FletTypedGenerator({'progressBar'}, (e, n, i) => e._exportProgressBar(n, i)),
  FletTypedGenerator(
      {'horizontalSlider'}, (e, n, i) => e._exportSlider(n, i, false)),
  FletTypedGenerator(
      {'verticalSlider'}, (e, n, i) => e._exportSlider(n, i, true)),
  FletTypedGenerator({'table'}, (e, n, i) => e._exportTable(n, i)),
  FletTypedGenerator({'image'}, (e, n, i) => e._exportImage(n, i)),
  FletTypedGenerator(<String>{}, (e, n, i) => e._exportText(n, i)),
];
