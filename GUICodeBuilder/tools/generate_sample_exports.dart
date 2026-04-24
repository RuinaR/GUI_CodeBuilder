import 'dart:io';

import 'package:gui_code_builder/exporters/code_exporter.dart';
import 'package:gui_code_builder/exporters/flet_code_exporter.dart';
import 'package:gui_code_builder/exporters/flutter_code_exporter.dart';
import 'package:gui_code_builder/exporters/html_css_exporter.dart';
import 'package:gui_code_builder/exporters/pyqt_code_exporter.dart';
import 'package:gui_code_builder/models/editor_state.dart';
import 'package:gui_code_builder/models/export_format.dart';
import 'package:gui_code_builder/services/json_document_service.dart';
import 'package:gui_code_builder/services/local_file_document_store.dart';

Future<void> main() async {
  final state = EditorState()
    ..pageClassName = 'SampleGeneratedPage'
    ..pageTitle = 'Sample Generated Page'
    ..canvasWidth = 720
    ..canvasHeight = 720;

  state.addNode('label')
    ..x = 32
    ..y = 28
    ..width = 260
    ..height = 40
    ..props['text'] = 'Sample generated UI';

  state.addNode('button')
    ..x = 32
    ..y = 88
    ..width = 160
    ..height = 48
    ..props['text'] = 'Run';

  state.addNode('lineEdit')
    ..x = 220
    ..y = 88
    ..width = 220
    ..height = 48
    ..props['text'] = 'admin'
    ..props['placeholder'] = 'Type here';

  state.addNode('comboBox')
    ..x = 472
    ..y = 88
    ..width = 160
    ..height = 48
    ..props['items'] = 'Auto,Manual,Off'
    ..props['value'] = 'Manual';

  state.addNode('checkBox')
    ..x = 32
    ..y = 160
    ..width = 180
    ..height = 40
    ..props['text'] = 'Enabled'
    ..props['checked'] = true;

  state.addNode('radioButton')
    ..x = 220
    ..y = 152
    ..width = 160
    ..height = 36
    ..props['text'] = 'Choice A'
    ..props['groupName'] = 'choices'
    ..props['radioValue'] = 'a'
    ..props['selected'] = true;

  state.addNode('radioButton')
    ..x = 220
    ..y = 188
    ..width = 160
    ..height = 36
    ..props['text'] = 'Choice B'
    ..props['groupName'] = 'choices'
    ..props['radioValue'] = 'b';

  state.addNode('horizontalSlider')
    ..x = 32
    ..y = 228
    ..width = 300
    ..height = 48
    ..props['value'] = 35;

  state.addNode('verticalSlider')
    ..x = 360
    ..y = 200
    ..width = 48
    ..height = 160
    ..props['value'] = 60
    ..props['min'] = 0
    ..props['max'] = 100;

  state.addNode('spinBox')
    ..x = 456
    ..y = 160
    ..width = 96
    ..height = 44
    ..props['value'] = 3
    ..props['min'] = 0
    ..props['max'] = 10;

  state.addNode('doubleSpinBox')
    ..x = 568
    ..y = 160
    ..width = 96
    ..height = 44
    ..props['value'] = 1.5
    ..props['min'] = 0
    ..props['max'] = 5;

  state.addNode('textBox')
    ..x = 456
    ..y = 220
    ..width = 208
    ..height = 96
    ..props['text'] = 'Ready';

  state.addNode('listBox')
    ..x = 32
    ..y = 304
    ..width = 160
    ..height = 96
    ..props['items'] = 'One,Two,Three';

  state.addNode('progressBar')
    ..x = 220
    ..y = 316
    ..width = 160
    ..height = 32
    ..props['value'] = 45
    ..props['max'] = 100;

  state.addNode('table')
    ..x = 456
    ..y = 336
    ..width = 220
    ..height = 128
    ..props['columns'] = 'Name,Value'
    ..props['rows'] = 'Speed,Fast;Status,Ready';

  state.addNode('image')
    ..x = 220
    ..y = 368
    ..width = 144
    ..height = 96
    ..props['text'] = 'Image';

  state.addNode('container')
    ..x = 32
    ..y = 440
    ..width = 160
    ..height = 80;

  state.addNode('groupBox')
    ..x = 220
    ..y = 500
    ..width = 180
    ..height = 96
    ..props['title'] = 'Group';

  state.addNode('tabs')
    ..x = 424
    ..y = 492
    ..width = 220
    ..height = 120
    ..props['tabs'] = 'First,Second';

  state.addNode('scrollArea')
    ..x = 32
    ..y = 560
    ..width = 160
    ..height = 96;

  state.addNode('row')
    ..x = 32
    ..y = 660
    ..width = 160
    ..height = 48
    ..props['gap'] = 6;

  state.addNode('column')
    ..x = 220
    ..y = 616
    ..width = 160
    ..height = 88
    ..props['gap'] = 6;

  final irJson = state.toIrJson();
  const documentStore = LocalFileDocumentStore();
  final jsonService = JsonDocumentService(documentStore: documentStore);
  final exporters = <CodeExporter>[
    FlutterCodeExporter(),
    FletCodeExporter(),
    PyQtCodeExporter(),
    HtmlCssExporter(),
  ];
  final generatedFiles = <ExportFormat, Map<String, String>>{
    for (final exporter in exporters)
      exporter.format: exporter.exportFiles(irJson),
  };

  await jsonService.saveExportFiles(
    jsonText: jsonService.encodePretty(irJson),
    generatedFiles: generatedFiles,
  );

  stdout.writeln(
    'Sample exports written to ${Directory(documentStore.exportDirectoryPath).absolute.path}',
  );
}
