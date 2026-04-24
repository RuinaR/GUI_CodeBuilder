part of '../pyqt_code_exporter.dart';

// PyQt 위젯별 코드 생성 전략이다.
abstract class PyQtWidgetGenerator {
  const PyQtWidgetGenerator();
  bool supports(String type);
  String create(PyQtCodeExporter exporter, WidgetNode node, String parent);
}

class PyQtTypedGenerator extends PyQtWidgetGenerator {
  const PyQtTypedGenerator(this.types, this.builder);
  final Set<String> types;
  final String Function(
      PyQtCodeExporter exporter, WidgetNode node, String parent) builder;

  @override
  bool supports(String type) => types.isEmpty || types.contains(type);

  @override
  String create(PyQtCodeExporter exporter, WidgetNode node, String parent) =>
      builder(exporter, node, parent);
}

final _pyqtWidgetGenerators = <PyQtWidgetGenerator>[
  PyQtTypedGenerator({'label', 'text'}, (e, n, p) {
    final name = e._memberName(n);
    return 'self.$name = QtWidgets.QLabel(${e._quote(n.payload.string('text'))}, $p)\n        self.$name.setTextFormat(QtCore.Qt.TextFormat.PlainText)\n        self.$name.setWordWrap(True)\n        self.$name.setAlignment(QtCore.Qt.AlignmentFlag.AlignLeft | QtCore.Qt.AlignmentFlag.AlignVCenter)';
  }),
  PyQtTypedGenerator({'button'}, (e, n, p) {
    final name = e._memberName(n);
    return 'self.$name = QtWidgets.QPushButton(${e._quote(n.payload.string('text', fallback: 'Button'))}, $p)\n        self.$name.clicked.connect(self.${e._eventHandlerName(n, 'on_clicked')})';
  }),
  PyQtTypedGenerator({'radioButton'}, (e, n, p) => e._createRadioControl(n, p)),
  PyQtTypedGenerator({'checkBox'}, (e, n, p) {
    final name = e._memberName(n);
    return 'self.$name = QtWidgets.QCheckBox(${e._quote(n.payload.string('text', fallback: 'Check'))}, $p)\n        self.$name.setChecked(${n.payload.boolean('checked') ? 'True' : 'False'})\n        self.$name.stateChanged.connect(self.${e._eventHandlerName(n, 'on_state_changed')})';
  }),
  PyQtTypedGenerator({'spinBox'}, (e, n, p) {
    final name = e._memberName(n);
    return 'self.$name = QtWidgets.QSpinBox($p)\n        self.$name.setRange(${e._formatNumber(n.payload.number('min'))}, ${e._formatNumber(n.payload.number('max', fallback: 100))})\n        self.$name.setValue(${e._formatNumber(n.payload.number('value'))})\n        self.$name.valueChanged.connect(self.${e._eventHandlerName(n, 'on_value_changed')})';
  }),
  PyQtTypedGenerator({'doubleSpinBox'}, (e, n, p) {
    final name = e._memberName(n);
    return 'self.$name = QtWidgets.QDoubleSpinBox($p)\n        self.$name.setRange(${e._formatNumber(n.payload.number('min'))}, ${e._formatNumber(n.payload.number('max', fallback: 100))})\n        self.$name.setValue(${e._formatNumber(n.payload.number('value'))})\n        self.$name.valueChanged.connect(self.${e._eventHandlerName(n, 'on_value_changed')})';
  }),
  PyQtTypedGenerator({'comboBox'}, (e, n, p) {
    final name = e._memberName(n);
    final value = n.payload.string('value');
    final selectedLine = value.isEmpty
        ? ''
        : '\n        self.$name.setCurrentText(${e._quote(value)})';
    return 'self.$name = QtWidgets.QComboBox($p)\n        self.$name.addItems([${e._items(n).map(e._quote).join(', ')}])$selectedLine\n        self.$name.currentTextChanged.connect(self.${e._eventHandlerName(n, 'on_current_text_changed')})';
  }),
  PyQtTypedGenerator({'textBox'}, (e, n, p) {
    final name = e._memberName(n);
    return 'self.$name = QtWidgets.QTextEdit(${e._quote(n.payload.string('text'))}, $p)\n        self.$name.textChanged.connect(self.${e._eventHandlerName(n, 'on_text_changed')})';
  }),
  PyQtTypedGenerator({'lineEdit'}, (e, n, p) {
    final name = e._memberName(n);
    return 'self.$name = QtWidgets.QLineEdit($p)\n        self.$name.setText(${e._quote(n.payload.string('text'))})\n        self.$name.setPlaceholderText(${e._quote(n.payload.string('placeholder'))})\n        self.$name.textChanged.connect(self.${e._eventHandlerName(n, 'on_text_changed')})';
  }),
  PyQtTypedGenerator({'listBox'}, (e, n, p) {
    final name = e._memberName(n);
    return 'self.$name = QtWidgets.QListWidget($p)\n        self.$name.addItems([${e._items(n).map(e._quote).join(', ')}])';
  }),
  PyQtTypedGenerator({'progressBar'}, (e, n, p) {
    final name = e._memberName(n);
    return 'self.$name = QtWidgets.QProgressBar($p)\n        self.$name.setValue(${e._formatNumber(n.payload.number('value'))})';
  }),
  PyQtTypedGenerator(
      {'horizontalSlider'}, (e, n, p) => _pyqtSlider(e, n, p, 'Horizontal')),
  PyQtTypedGenerator(
      {'verticalSlider'}, (e, n, p) => _pyqtSlider(e, n, p, 'Vertical')),
  PyQtTypedGenerator({'table'}, (e, n, p) => e._createTableControl(n, p)),
  PyQtTypedGenerator({'image'}, (e, n, p) => e._createImageControl(n, p)),
  PyQtTypedGenerator({'groupBox'}, (e, n, p) {
    final name = e._memberName(n);
    return 'self.$name = QtWidgets.QGroupBox(${e._quote(n.payload.string('title', fallback: 'Group'))}, $p)';
  }),
  PyQtTypedGenerator({'tabs'}, (e, n, p) => e._createTabsControl(n, p)),
  PyQtTypedGenerator(
      {'scrollArea'}, (e, n, p) => e._createScrollAreaControl(n, p)),
  PyQtTypedGenerator({'container', 'row', 'column'}, (e, n, p) {
    final name = e._memberName(n);
    return 'self.$name = QtWidgets.QFrame($p)';
  }),
  PyQtTypedGenerator(<String>{}, (e, n, p) {
    final name = e._memberName(n);
    return 'self.$name = QtWidgets.QLabel(${e._quote(n.displayName)}, $p)';
  }),
];

String _pyqtSlider(
  PyQtCodeExporter exporter,
  WidgetNode node,
  String parent,
  String orientation,
) {
  final name = exporter._memberName(node);
  return 'self.$name = QtWidgets.QSlider(QtCore.Qt.Orientation.$orientation, $parent)\n        self.$name.setRange(${exporter._formatNumber(node.payload.number('min'))}, ${exporter._formatNumber(node.payload.number('max', fallback: 100))})\n        self.$name.setValue(${exporter._formatNumber(node.payload.number('value'))})\n        self.$name.valueChanged.connect(self.${exporter._eventHandlerName(node, 'on_value_changed')})';
}
