import 'package:flutter_test/flutter_test.dart';
import 'package:gui_code_builder/exporters/flet_code_exporter.dart';
import 'package:gui_code_builder/exporters/flutter_code_exporter.dart';
import 'package:gui_code_builder/exporters/html_css_exporter.dart';
import 'package:gui_code_builder/exporters/pyqt_code_exporter.dart';

void main() {
  group('FlutterCodeExporter', () {
    test('generates lifecycle, controls, and grouped radio code', () {
      final files = FlutterCodeExporter().exportFiles(_representativeIr());
      final code = _normalized(files['flutter_generated_page.dart']!);

      expect(
          files, containsPair('test_mains/flutter_test_main.dart', isNotEmpty));
      expect(code, contains('class ExporterSmokePage extends StatefulWidget'));
      expect(code, contains('void initialize()'));
      expect(code, contains('void release()'));
      expect(code, contains('ElevatedButton('));
      expect(code, contains("radioGroupValues.putIfAbsent('choices'"));
      expect(code, contains('RadioGroup<String>('));
      expect(
          code, contains("checkBoxValues.putIfAbsent('enableFeatureControl'"));
      expect(code, contains('enableFeatureControlOnChanged(checked)'));
      expect(code, contains('final Map<String, String?> dropdownValues'));
      expect(code, contains("dropdownValues.putIfAbsent('modeSelectControl'"));
      expect(code, contains('modeSelectControlOnChanged(value)'));
      expect(code, contains('usernameInputControlOnChanged'));
      expect(code, contains('notesBoxControlOnChanged'));
      expect(code, contains('countSpinControlOnChanged'));
      expect(code, contains("sliderValues.putIfAbsent('volumeSliderControl'"));
      expect(code, contains('volumeSliderControlOnChanged(value)'));
      expect(code, contains('DataTable('));
      expect(code, contains('DefaultTabController('));
      expect(code, contains('SingleChildScrollView('));
    });
  });

  group('FletCodeExporter', () {
    test('generates lifecycle, positioned controls, and radio group code', () {
      final files = FletCodeExporter().exportFiles(_representativeIr());
      final code = _normalized(files['flet_generated_page.py']!);

      expect(files, containsPair('test_mains/flet_test_main.py', isNotEmpty));
      expect(code, contains('class ExporterSmokePage:'));
      expect(code, contains('def initialize(self):'));
      expect(code, contains('def build(self, page: ft.Page):'));
      expect(code, contains('ft.Stack('));
      expect(code, contains('ft.ElevatedButton('));
      expect(code, contains('ft.RadioGroup('));
      expect(code, contains('data="choices"'));
      expect(code, contains('on_change=self.enableFeature_on_change'));
      expect(code, contains('on_select=self.modeSelect_on_select'));
      expect(code, contains('on_change=self.usernameInput_on_change'));
      expect(code, contains('on_change=self.volumeSlider_on_change'));
      expect(code, contains('min=0'));
      expect(code, contains('max=100'));
      expect(code, contains('width=260'));
      expect(code, contains('alignment=ft.Alignment(0, 0)'));
      expect(code, contains('clip_behavior=ft.ClipBehavior.NONE'));
      expect(
          code,
          contains(
              'rotate=ft.Rotate(angle=-1.5708, alignment=ft.Alignment(0, 0))'));
      expect(code, contains('width=140'));
      expect(code, contains('ft.DataTable('));
      expect(code, contains('ft.Tabs('));
      expect(code, contains('ft.TabBarView('));
      expect(code, contains('scroll=ft.ScrollMode.AUTO'));
    });
  });

  group('PyQtCodeExporter', () {
    test('generates window, widgets, handlers, and radio grouping code', () {
      final files = PyQtCodeExporter().exportFiles(_representativeIr());
      final code = _normalized(files['pyqt_generated_page.py']!);

      expect(files, containsPair('test_mains/pyqt_test_main.py', isNotEmpty));
      expect(files, containsPair('requirements_export.txt', contains('PyQt6')));
      expect(
        files,
        containsPair('requirements_export.txt', contains('flet==0.82.2')),
      );
      expect(code,
          contains('class ExporterSmokePagePyQtWindow(QtWidgets.QWidget):'));
      expect(code, contains('def initialize(self):'));
      expect(code, contains('QtWidgets.QPushButton("Run"'));
      expect(code, contains('QtWidgets.QButtonGroup(self)'));
      expect(code, contains('self.radio_groups["choices"].setExclusive(True)'));
      expect(code, contains('self.setFont(QtGui.QFont("Segoe UI", 10))'));
      expect(code, contains('self.setStyleSheet('));
      expect(code, contains('QPushButton:hover'));
      expect(code, contains('QPushButton:pressed'));
      expect(code, contains('-qt-font-smoothing-type: antialias'));
      expect(code, contains('font-family: "Segoe UI", Arial, sans-serif'));
      expect(code, contains('setTextFormat(QtCore.Qt.TextFormat.PlainText)'));
      expect(code, contains('setWordWrap(True)'));
      expect(code, contains('QtCore.Qt.AlignmentFlag.AlignVCenter'));
      expect(code, contains('QCheckBox::indicator:checked'));
      expect(code, contains('QRadioButton::indicator:checked'));
      expect(code, contains('QLineEdit:focus'));
      expect(code, contains('self.enableFeature.setChecked(True)'));
      expect(code, contains('self.modeSelect.setCurrentText("Manual")'));
      expect(
          code,
          contains(
              'self.countSpin.valueChanged.connect(self.countSpin_on_value_changed)'));
      expect(
          code,
          contains(
              'self.ratioSpin.valueChanged.connect(self.ratioSpin_on_value_changed)'));
      expect(
          code,
          contains(
              'self.notesBox.textChanged.connect(self.notesBox_on_text_changed)'));
      expect(code, contains('QtWidgets.QTableWidget(self)'));
      expect(code, contains('QtWidgets.QTabWidget(self)'));
      expect(code, contains('QtWidgets.QScrollArea(self)'));
      expect(code, contains('QtWidgets.QFrame(self)'));
      expect(code, contains('def runButton_on_clicked(self, checked=False):'));
    });
  });

  group('HtmlCssExporter', () {
    test('generates HTML, CSS, controls, and event bindings', () {
      final exporter = HtmlCssExporter();
      final files = exporter.exportFiles(_representativeIr());
      final html = _normalized(files['html_generated_page.html']!);
      final css = _normalized(files['html_generated_page.css']!);

      expect(files, containsPair('test_mains/run_html_test.cmd', isNotEmpty));
      expect(html, contains('<title>Exporter Smoke Page</title>'));
      expect(html, contains('class ExporterSmokePageHtmlPage'));
      expect(html, contains('data-member="runButton"'));
      expect(html, contains('<button>Run</button>'));
      expect(html, contains('input type="radio"'));
      expect(html, contains('<input type="checkbox" checked>'));
      expect(html, contains('<option value="Manual" selected>Manual</option>'));
      expect(html, contains('<textarea>Ready</textarea>'));
      expect(html, contains('input type="number"'));
      expect(html, contains("addEventListener('click'"));
      expect(html, contains("addEventListener('change'"));
      expect(html, contains("addEventListener('input'"));
      expect(html, contains('<table>'));
      expect(html, contains('data-member="settingsPanel"'));
      expect(html, contains('data-member="mainTabs"'));
      expect(html, contains('data-member="scrollRegion"'));
      expect(css, contains('.page {'));
      expect(css, contains('.generated-label'));
      expect(css, contains('input.vertical-slider'));
      expect(css, contains('button:hover'));
      expect(css, contains('button:active'));
      expect(css, contains('focus-visible'));
      expect(css, contains('accent-color: #2563eb'));
      expect(css, contains('tbody tr:hover'));
      expect(css, contains('.tabs button:hover'));
    });
  });

  test('exporters treat label and legacy text nodes as labels', () {
    final ir = _labelCompatibilityIr();

    final flutterCode = _normalized(FlutterCodeExporter().exportPage(ir));
    final fletCode = _normalized(FletCodeExporter().exportPage(ir));
    final pyqtCode = _normalized(PyQtCodeExporter().exportPage(ir));
    final htmlCode = _normalized(HtmlCssExporter().exportPage(ir));

    expect(flutterCode, contains("Text( 'Modern label'"));
    expect(flutterCode, contains("Text( 'Legacy text label'"));
    expect(fletCode, contains('ft.Text('));
    expect(fletCode, contains('value="Modern label"'));
    expect(fletCode, contains('value="Legacy text label"'));
    expect(pyqtCode, contains('QtWidgets.QLabel("Modern label"'));
    expect(pyqtCode, contains('QtWidgets.QLabel("Legacy text label"'));
    expect(htmlCode, contains('class="generated-label">Modern label</div>'));
    expect(
      htmlCode,
      contains('class="generated-label">Legacy text label</div>'),
    );
  });
}

Map<String, dynamic> _representativeIr() {
  return {
    'schemaVersion': 3,
    'generator': {
      'name': 'GUI Code Builder',
      'irPurpose':
          'single source for Flutter, Flet, PyQt, and HTML/CSS exporters',
    },
    'page': {
      'className': 'ExporterSmokePage',
      'title': 'Exporter Smoke Page',
      'width': 640,
      'height': 680,
      'responsive': true,
      'coordinateSystem': 'logicalPixels',
    },
    'exportTargets': ['flutter', 'flet', 'pyqt', 'html'],
    'nodes': [
      _node(
        id: 'node_1',
        type: 'button',
        memberName: 'runButton',
        x: 24,
        y: 24,
        width: 120,
        height: 44,
        props: {
          'text': 'Run',
          'backgroundColor': '#2563EB',
          'foregroundColor': '#FFFFFF',
          'borderRadius': 6,
        },
      ),
      _node(
        id: 'node_2',
        type: 'radioButton',
        memberName: 'choiceA',
        x: 24,
        y: 88,
        width: 180,
        height: 36,
        props: {
          'text': 'Choice A',
          'groupName': 'choices',
          'radioValue': 'a',
          'selected': true,
        },
      ),
      _node(
        id: 'node_3',
        type: 'radioButton',
        memberName: 'choiceB',
        x: 24,
        y: 128,
        width: 180,
        height: 36,
        props: {
          'text': 'Choice B',
          'groupName': 'choices',
          'radioValue': 'b',
          'selected': false,
        },
      ),
      _node(
        id: 'node_4',
        type: 'checkBox',
        memberName: 'enableFeature',
        x: 24,
        y: 184,
        width: 180,
        height: 40,
        props: {'text': 'Enabled', 'checked': true},
      ),
      _node(
        id: 'node_5',
        type: 'horizontalSlider',
        memberName: 'volumeSlider',
        x: 24,
        y: 244,
        width: 260,
        height: 48,
        props: {'value': 35, 'min': 0, 'max': 100},
      ),
      _node(
        id: 'node_6',
        type: 'verticalSlider',
        memberName: 'heightSlider',
        x: 296,
        y: 220,
        width: 44,
        height: 140,
        props: {'value': 60, 'min': 0, 'max': 100},
      ),
      _node(
        id: 'node_7',
        type: 'comboBox',
        memberName: 'modeSelect',
        x: 220,
        y: 88,
        width: 180,
        height: 44,
        props: {'items': 'Auto,Manual,Off', 'value': 'Manual'},
      ),
      _node(
        id: 'node_8',
        type: 'lineEdit',
        memberName: 'usernameInput',
        x: 420,
        y: 88,
        width: 180,
        height: 44,
        props: {'text': 'admin', 'placeholder': 'User name'},
      ),
      _node(
        id: 'node_9',
        type: 'textBox',
        memberName: 'notesBox',
        x: 420,
        y: 144,
        width: 180,
        height: 80,
        props: {'text': 'Ready'},
      ),
      _node(
        id: 'node_10',
        type: 'spinBox',
        memberName: 'countSpin',
        x: 420,
        y: 236,
        width: 84,
        height: 40,
        props: {'value': 3, 'min': 0, 'max': 10},
      ),
      _node(
        id: 'node_11',
        type: 'doubleSpinBox',
        memberName: 'ratioSpin',
        x: 516,
        y: 236,
        width: 84,
        height: 40,
        props: {'value': 1.5, 'min': 0, 'max': 5},
      ),
      _node(
        id: 'node_12',
        type: 'listBox',
        memberName: 'itemList',
        x: 24,
        y: 308,
        width: 160,
        height: 80,
        props: {'items': 'One,Two,Three'},
      ),
      _node(
        id: 'node_13',
        type: 'progressBar',
        memberName: 'buildProgress',
        x: 200,
        y: 312,
        width: 160,
        height: 32,
        props: {'value': 45, 'max': 100},
      ),
      _node(
        id: 'node_14',
        type: 'image',
        memberName: 'logoImage',
        x: 380,
        y: 300,
        width: 100,
        height: 80,
        props: {'src': 'https://example.com/logo.png', 'text': 'Image'},
      ),
      _node(
        id: 'node_15',
        type: 'table',
        memberName: 'resultTable',
        x: 320,
        y: 24,
        width: 260,
        height: 52,
        props: {
          'columns': 'Name,Value',
          'rows': 'Speed,Fast;Status,Ready',
        },
      ),
      _node(
        id: 'node_16',
        type: 'groupBox',
        memberName: 'settingsPanel',
        x: 24,
        y: 400,
        width: 260,
        height: 120,
        props: {'title': 'Settings'},
        children: [
          _node(
            id: 'node_16_1',
            type: 'button',
            memberName: 'nestedButton',
            x: 12,
            y: 28,
            width: 120,
            height: 36,
            props: {'text': 'Nested'},
          ),
        ],
      ),
      _node(
        id: 'node_17',
        type: 'tabs',
        memberName: 'mainTabs',
        x: 304,
        y: 400,
        width: 280,
        height: 120,
        props: {'tabs': 'First,Second'},
        children: [
          _node(
            id: 'node_17_1',
            type: 'label',
            memberName: 'tabLabel',
            x: 12,
            y: 44,
            width: 140,
            height: 28,
            props: {'text': 'Tab content'},
          ),
        ],
      ),
      _node(
        id: 'node_18',
        type: 'scrollArea',
        memberName: 'scrollRegion',
        x: 24,
        y: 536,
        width: 240,
        height: 100,
        props: {},
        children: [
          _node(
            id: 'node_18_1',
            type: 'column',
            memberName: 'scrollColumn',
            x: 8,
            y: 8,
            width: 180,
            height: 80,
            props: {'gap': 4},
            children: [
              _node(
                id: 'node_18_1_1',
                type: 'label',
                memberName: 'scrollLabel',
                x: 0,
                y: 0,
                width: 120,
                height: 24,
                props: {'text': 'Scrollable'},
              ),
            ],
          ),
        ],
      ),
      _node(
        id: 'node_19',
        type: 'container',
        memberName: 'plainContainer',
        x: 288,
        y: 536,
        width: 144,
        height: 80,
        props: {},
      ),
      _node(
        id: 'node_20',
        type: 'row',
        memberName: 'actionRow',
        x: 448,
        y: 536,
        width: 160,
        height: 80,
        props: {'gap': 6},
        children: [
          _node(
            id: 'node_20_1',
            type: 'button',
            memberName: 'rowButton',
            x: 0,
            y: 0,
            width: 72,
            height: 36,
            props: {'text': 'Row'},
          ),
        ],
      ),
    ],
  };
}

Map<String, dynamic> _labelCompatibilityIr() {
  return {
    'page': {
      'className': 'LabelCompatibilityPage',
      'title': 'Label Compatibility Page',
      'width': 320,
      'height': 160,
    },
    'nodes': [
      _node(
        id: 'label_modern',
        type: 'label',
        memberName: 'modernLabel',
        x: 16,
        y: 16,
        width: 180,
        height: 32,
        props: {'text': 'Modern label', 'fontSize': 18},
      ),
      _node(
        id: 'label_legacy',
        type: 'text',
        memberName: 'legacyTextLabel',
        x: 16,
        y: 64,
        width: 180,
        height: 32,
        props: {'text': 'Legacy text label', 'fontSize': 18},
      ),
    ],
  };
}

Map<String, dynamic> _node({
  required String id,
  required String type,
  required String memberName,
  required num x,
  required num y,
  required num width,
  required num height,
  required Map<String, dynamic> props,
  List<Map<String, dynamic>> children = const <Map<String, dynamic>>[],
}) {
  final mergedProps = {
    'name': memberName,
    'memberName': memberName,
    'responsive': true,
    'fontSize': 14,
    'fontFamily': 'Arial',
    'color': '#111827',
    'backgroundColor': '#FFFFFF',
    'foregroundColor': '#111827',
    'borderColor': '#CBD5E1',
    'borderRadius': 4,
    'padding': 8,
    'onClick': '',
    ...props,
  };
  return {
    'id': id,
    'type': type,
    'role': 'control',
    'frame': {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'responsive': true,
    },
    'content': {
      'name': memberName,
      if (mergedProps.containsKey('text')) 'text': mergedProps['text'],
      if (mergedProps.containsKey('columns')) 'columns': mergedProps['columns'],
      if (mergedProps.containsKey('rows')) 'rows': mergedProps['rows'],
      if (mergedProps.containsKey('items')) 'items': mergedProps['items'],
      if (mergedProps.containsKey('value')) 'value': mergedProps['value'],
      if (mergedProps.containsKey('placeholder'))
        'placeholder': mergedProps['placeholder'],
      if (mergedProps.containsKey('src')) 'src': mergedProps['src'],
      if (mergedProps.containsKey('title')) 'title': mergedProps['title'],
      if (mergedProps.containsKey('tabs')) 'tabs': mergedProps['tabs'],
      if (mergedProps.containsKey('groupName'))
        'groupName': mergedProps['groupName'],
      if (mergedProps.containsKey('radioValue'))
        'radioValue': mergedProps['radioValue'],
    },
    'style': {
      'color': mergedProps['color'],
      'backgroundColor': mergedProps['backgroundColor'],
      'foregroundColor': mergedProps['foregroundColor'],
      'borderColor': mergedProps['borderColor'],
      'borderRadius': mergedProps['borderRadius'],
      'padding': mergedProps['padding'],
    },
    'layout': {'mode': 'absolute'},
    'behavior': {'memberName': memberName, 'onClick': ''},
    'props': mergedProps,
    'children': children,
  };
}

String _normalized(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
