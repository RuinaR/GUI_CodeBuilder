import '../models/export_format.dart';
import '../models/ir_document.dart';
import '../models/widget_node.dart';
import 'code_exporter.dart';

part 'widget_generators/flutter_widget_generators.dart';

// JSON IR을 Flutter 위젯 코드로 변환한다.
class FlutterCodeExporter implements CodeExporter {
  @override
  ExportFormat get format => ExportFormat.flutter;

  @override
  Map<String, String> exportFiles(Map<String, dynamic> irJson) {
    return {
      format.fileName: exportPage(irJson),
      'test_mains/flutter_test_main.dart': _exportTestMain(irJson),
      'test_mains/run_flutter_test.cmd': _exportRunFlutterTestCmd(),
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
import 'package:flutter/material.dart';

// GUI Code Builder에서 생성된 Flutter 페이지이다.
class $className extends StatefulWidget {
  const $className({super.key, this.autoInitialize = false});

  final bool autoInitialize;

  @override
  State<$className> createState() => _${className}State();
}

class _${className}State extends State<$className> {
${_exportMembers(nodes)}

  @override
  void initState() {
    super.initState();
    if (widget.autoInitialize) {
      initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaleX = constraints.maxWidth / $width;
            final scaleY = constraints.maxHeight / $height;
            final scale = scaleX < scaleY ? scaleX : scaleY;

            return Center(
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: $width,
                  height: $height,
                  child: Stack(
                    children: [
${nodes.where((node) => node.type != 'radioButton').map((node) => _exportPositionedNode(node, 22)).join('\n')}
${_exportRadioGroups(nodes, 22)}
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void initialize() {
${nodes.map((node) => _exportMemberAssignment(node, 4)).join('\n')}
  }

  void release() {
    Navigator.of(context).maybePop();
  }

${_exportEventHandlers(nodes)}
}
''';
  }

  String _exportTestMain(Map<String, dynamic> irJson) {
    final document = IrDocument.fromJson(irJson);
    final className = _safeClassName(document.className);
    return '''
import 'package:flutter/material.dart';

import '../${format.fileName}';

// 생성된 Flutter 페이지를 바로 실행하는 테스트 main이다.
void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: $className(autoInitialize: true)));
}
''';
  }

  String _exportRunFlutterTestCmd() {
    return r'''
@echo off
setlocal

for %%I in ("%~dp0..\..") do set "ROOT=%%~fI\"
set "APPDATA=%ROOT%.dart-home\AppData"
set "LOCALAPPDATA=%ROOT%.dart-home\LocalAppData"
set "PUB_CACHE=%ROOT%.dart-home\PubCache"
set "FLUTTER_ROOT=%ROOT%.flutter-sdk\flutter"

if not exist "%ROOT%.dart_tool\package_config.json" (
  "%ROOT%.flutter-sdk\flutter\bin\cache\dart-sdk\bin\dart.exe" ^
    --packages="%ROOT%.flutter-sdk\flutter\packages\flutter_tools\.dart_tool\package_config.json" ^
    "%ROOT%.flutter-sdk\flutter\bin\cache\flutter_tools.snapshot" pub get
)

"%ROOT%.flutter-sdk\flutter\bin\cache\dart-sdk\bin\dart.exe" ^
  --packages="%ROOT%.flutter-sdk\flutter\packages\flutter_tools\.dart_tool\package_config.json" ^
  "%ROOT%.flutter-sdk\flutter\bin\cache\flutter_tools.snapshot" run -d windows -t "exports\test_mains\flutter_test_main.dart"

pause
''';
  }

  String _exportPositionedNode(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final memberName = _memberName(node);
    return '''${space}Positioned(
$space  left: ${_formatNumber(node.x)},
$space  top: ${_formatNumber(node.y)},
$space  width: ${_formatNumber(node.width)},
$space  height: ${_formatNumber(node.height)},
$space  child: $memberName,
$space),''';
  }

  String _exportMembers(List<WidgetNode> nodes) {
    final lines = <String>[
      '  final Map<String, String?> radioGroupValues = <String, String?>{};',
      '  final Map<String, bool> checkBoxValues = <String, bool>{};',
      '  final Map<String, double> sliderValues = <String, double>{};',
    ];
    void collect(WidgetNode node) {
      lines.add('  Widget ${_memberName(node)} = const SizedBox.shrink();');
      for (final child in node.children) {
        collect(child);
      }
    }

    for (final node in nodes) {
      collect(node);
    }
    return lines.join('\n');
  }

  String _exportMemberAssignment(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final lines = <String>[];
    for (final child in node.children) {
      lines.add(_exportMemberAssignment(child, indent));
    }
    if (node.type == 'radioButton') {
      lines.add(_exportRadioDefault(node, indent));
    }
    if (node.type == 'checkBox') {
      lines.add(_exportCheckBoxDefault(node, indent));
    }
    if (node.type == 'horizontalSlider' || node.type == 'verticalSlider') {
      lines.add(_exportSliderDefault(node, indent));
    }
    lines.add('$space${_memberName(node)} = ${_exportWidget(node, indent)};');
    return lines.join('\n');
  }

  String _exportWidget(WidgetNode node, int indent) {
    return _flutterWidgetGenerators
        .firstWhere((generator) => generator.supports(node.type))
        .export(this, node, indent);
  }

  String _exportRadioDefault(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final groupName = _quote(_radioGroupName(node));
    final value = _quote(_radioValue(node));
    final selected = node.props['selected'] == true;
    return selected
        ? '${space}radioGroupValues.putIfAbsent($groupName, () => $value);'
        : '${space}radioGroupValues.putIfAbsent($groupName, () => null);';
  }

  String _exportCheckBoxDefault(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final member = _quote(_memberName(node));
    final checked = node.props['checked'] == true;
    return '${space}checkBoxValues.putIfAbsent($member, () => $checked);';
  }

  String _exportSliderDefault(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final member = _quote(_memberName(node));
    final value = _formatNumber(node.props['value'] ?? 0);
    return '${space}sliderValues.putIfAbsent($member, () => $value);';
  }

  String _exportRadio(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final value = _quote(_radioValue(node));
    final text = _quote(node.props['text']?.toString() ?? 'Radio');
    return '''Row(
$space  children: [
$space    SizedBox(
$space      width: 32,
$space      height: 32,
$space      child: Radio<String>(value: $value),
$space    ),
$space    Expanded(child: Text($text, overflow: TextOverflow.ellipsis)),
$space  ],
$space)''';
  }

  String _exportRadioGroups(List<WidgetNode> nodes, int indent) {
    final grouped = <String, List<WidgetNode>>{};
    for (final node in nodes.where((node) => node.type == 'radioButton')) {
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
      final children = entry.value
          .map((node) => _exportRelativePositionedNode(
                node,
                indent + 6,
                offsetX: minX,
                offsetY: minY,
              ))
          .join('\n');
      blocks.add('''${space}Positioned(
$space  left: ${_formatNumber(minX)},
$space  top: ${_formatNumber(minY)},
$space  width: ${_formatNumber(maxX - minX)},
$space  height: ${_formatNumber(maxY - minY)},
$space  child: StatefulBuilder(
$space    builder: (context, setControlState) => RadioGroup<String>(
$space      groupValue: radioGroupValues[$groupName],
$space      onChanged: (value) {
$space        setControlState(() => radioGroupValues[$groupName] = value);
$space        ${_radioGroupHandlerName(entry.key)}(value);
$space      },
$space      child: Stack(
$space        children: [
$children
$space        ],
$space      ),
$space    ),
$space  ),
$space),''');
    }
    return blocks.join('\n');
  }

  String _exportRelativePositionedNode(
    WidgetNode node,
    int indent, {
    required double offsetX,
    required double offsetY,
  }) {
    final space = ' ' * indent;
    final memberName = _memberName(node);
    return '''${space}Positioned(
$space  left: ${_formatNumber(node.x - offsetX)},
$space  top: ${_formatNumber(node.y - offsetY)},
$space  width: ${_formatNumber(node.width)},
$space  height: ${_formatNumber(node.height)},
$space  child: $memberName,
$space),''';
  }

  String _exportCheckBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final member = _quote(_memberName(node));
    final text = _quote(node.props['text']?.toString() ?? 'Check');
    return '''StatefulBuilder(
$space  builder: (context, setControlState) => CheckboxListTile(
$space    dense: true,
$space    contentPadding: EdgeInsets.zero,
$space    title: Text($text, overflow: TextOverflow.ellipsis),
$space    value: checkBoxValues[$member] ?? false,
$space    onChanged: (value) => setControlState(() => checkBoxValues[$member] = value ?? false),
$space  ),
$space)''';
  }

  String _exportNumberInput(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final value = _quote((node.props['value'] ?? 0).toString());
    return '''TextField(
$space  controller: TextEditingController(text: $value),
$space  keyboardType: TextInputType.number,
$space  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
$space)''';
  }

  String _exportComboBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final items = _items(node);
    final selected = _quote(node.props['value']?.toString().isNotEmpty == true
        ? node.props['value'].toString()
        : (items.isEmpty ? '' : items.first));
    final entries = items
        .map((item) =>
            '${' ' * (indent + 4)}DropdownMenuItem<String>(value: ${_quote(item)}, child: Text(${_quote(item)})),')
        .join('\n');
    return '''DropdownButtonFormField<String>(
$space  value: $selected,
$space  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
$space  items: [
$entries
$space  ],
$space  onChanged: (_) {},
$space)''';
  }

  String _exportTextBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final text = _quote(node.props['text']?.toString() ?? '');
    return '''TextField(
$space  controller: TextEditingController(text: $text),
$space  maxLines: null,
$space  expands: true,
$space  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
$space)''';
  }

  String _exportLineEdit(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final text = _quote(node.props['text']?.toString() ?? '');
    final placeholder = _quote(node.props['placeholder']?.toString() ?? '');
    return '''TextField(
$space  controller: TextEditingController(text: $text),
$space  decoration: InputDecoration(border: const OutlineInputBorder(), isDense: true, hintText: $placeholder),
$space)''';
  }

  String _exportListBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final rows = _items(node)
        .map((item) =>
            '${' ' * (indent + 6)}Text(${_quote(item)}, overflow: TextOverflow.ellipsis),')
        .join('\n');
    return '''Container(
$space  padding: const EdgeInsets.all(6),
$space  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1))),
$space  child: ListView(
$space    children: [
$rows
$space    ],
$space  ),
$space)''';
  }

  String _exportProgressBar(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final value = _progressValue(node);
    return '''Center(
$space  child: LinearProgressIndicator(value: $value),
$space)''';
  }

  String _exportSlider(WidgetNode node, int indent, bool vertical) {
    final space = ' ' * indent;
    final member = _quote(_memberName(node));
    final min = _formatNumber(node.props['min'] ?? 0);
    final max = _formatNumber(node.props['max'] ?? 100);
    final slider = '''StatefulBuilder(
$space  builder: (context, setControlState) => Slider(
$space    value: sliderValues[$member]!.clamp($min, $max).toDouble(),
$space    min: $min,
$space    max: $max,
$space    onChanged: (value) => setControlState(() => sliderValues[$member] = value),
$space  ),
$space)''';
    if (!vertical) {
      return slider;
    }
    return '''RotatedBox(
$space  quarterTurns: 3,
$space  child: $slider,
$space)''';
  }

  String _exportTable(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final columns = _csv(node.props['columns']?.toString() ?? 'Name,Value');
    final rows = _tableRows(node);
    final header = columns
        .map((item) =>
            '${' ' * (indent + 6)}DataColumn(label: Text(${_quote(item)})),')
        .join('\n');
    final body = rows.map((row) {
      final cells = columns.asMap().entries.map((entry) {
        final value = entry.key < row.length ? row[entry.key] : '';
        return 'DataCell(Text(${_quote(value)}))';
      }).join(', ');
      return '${' ' * (indent + 6)}DataRow(cells: [$cells]),';
    }).join('\n');
    return '''SingleChildScrollView(
$space  scrollDirection: Axis.horizontal,
$space  child: DataTable(
$space    columns: [
$header
$space    ],
$space    rows: [
$body
$space    ],
$space  ),
$space)''';
  }

  String _exportImage(WidgetNode node, int indent) {
    final src = node.props['src']?.toString() ?? '';
    if (src.isEmpty) {
      return _exportSimple(
          node, indent, node.props['text']?.toString() ?? 'Image');
    }
    return 'Image.network(${_quote(src)}, fit: BoxFit.cover)';
  }

  String _exportSimple(WidgetNode node, int indent, String label) {
    final space = ' ' * indent;
    final text = _quote(node.props['text']?.toString() ?? label);
    return '''Container(
$space  alignment: Alignment.centerLeft,
$space  padding: const EdgeInsets.all(8),
$space  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1))),
$space  child: Text($text),
$space)''';
  }

  String _exportText(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final text = _quote(node.props['text']?.toString() ?? '');
    final fontSize = _formatNumber(node.props['fontSize'] ?? 16);
    final fontFamily = _quote(node.props['fontFamily']?.toString() ?? 'Arial');
    final color = _exportColor(node.props['color']?.toString() ?? '#111827');
    final weight = node.props['fontWeight'] == 'bold'
        ? 'FontWeight.bold'
        : 'FontWeight.normal';
    return '''Text(
$space  $text,
$space  overflow: TextOverflow.ellipsis,
$space  style: TextStyle(
$space    fontSize: $fontSize,
$space    fontFamily: $fontFamily,
$space    fontWeight: $weight,
$space    color: $color,
$space  ),
$space)''';
  }

  String _exportButton(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final text = _quote(node.props['text']?.toString() ?? 'Button');
    final background = _exportColor(
      node.props['backgroundColor']?.toString() ?? '#2563EB',
    );
    final foreground = _exportColor(
      node.props['foregroundColor']?.toString() ?? '#FFFFFF',
    );
    final radius = _formatNumber(node.props['borderRadius'] ?? 6);
    return '''ElevatedButton(
$space  style: ElevatedButton.styleFrom(
$space    backgroundColor: $background,
$space    foregroundColor: $foreground,
$space    shape: RoundedRectangleBorder(
$space      borderRadius: BorderRadius.circular($radius),
$space    ),
$space  ),
$space  onPressed: ${_eventHandlerName(node, 'OnPressed')},
$space  child: FittedBox(fit: BoxFit.scaleDown, child: Text($text)),
$space)''';
  }

  String _exportGroupBox(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final title = _quote(node.props['title']?.toString() ?? 'Group');
    final childCode = _stackChildren(node, indent + 6);
    return '''InputDecorator(
$space  decoration: InputDecoration(
$space    labelText: $title,
$space    border: const OutlineInputBorder(),
$space    contentPadding: const EdgeInsets.all(8),
$space  ),
$space  child: $childCode,
$space)''';
  }

  String _exportTabs(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final tabs = _csv(node.props['tabs']?.toString() ?? 'Tab 1,Tab 2');
    final labels = tabs
        .map((tab) => '${' ' * (indent + 6)}Tab(text: ${_quote(tab)}),')
        .join('\n');
    final childCode = _stackChildren(node, indent + 8);
    final views =
        tabs.map((_) => '${' ' * (indent + 6)}$childCode,').join('\n');
    return '''DefaultTabController(
$space  length: ${tabs.isEmpty ? 1 : tabs.length},
$space  child: Column(
$space    children: [
$space      TabBar(
$space        labelColor: Colors.black,
$space        tabs: [
$labels
$space        ],
$space      ),
$space      Expanded(
$space        child: TabBarView(
$space          children: [
$views
$space          ],
$space        ),
$space      ),
$space    ],
$space  ),
$space)''';
  }

  String _exportScrollArea(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final childCode = _stackChildren(node, indent + 4);
    return '''SingleChildScrollView(
$space  child: SizedBox(
$space    width: ${_formatNumber(node.width)},
$space    height: ${_formatNumber(node.height)},
$space    child: $childCode,
$space  ),
$space)''';
  }

  String _stackChildren(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final children = [
      node.children
          .where((child) => child.type != 'radioButton')
          .map((child) => _exportPositionedNode(child, indent + 4))
          .join('\n'),
      _exportRadioGroups(node.children, indent + 4),
    ].where((part) => part.trim().isNotEmpty).join('\n');
    return '''Stack(
$space  children: [
$children
$space  ],
$space)''';
  }

  String _exportContainer(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final background = _exportColor(
      node.props['backgroundColor']?.toString() ?? '#F8FAFC',
    );
    final borderColor = _exportColor(
      node.props['borderColor']?.toString() ?? '#94A3B8',
    );
    final borderRadius = _formatNumber(node.props['borderRadius'] ?? 6);
    final padding = _formatNumber(node.props['padding'] ?? 0);
    final childCode = node.children.isEmpty
        ? 'null'
        : '''Padding(
$space    padding: const EdgeInsets.all($padding),
$space    child: ${_stackChildren(node, indent + 4)},
$space  )''';
    return '''Container(
$space  decoration: BoxDecoration(
$space    color: $background,
$space    border: Border.all(color: $borderColor),
$space    borderRadius: BorderRadius.circular($borderRadius),
$space  ),
$space  child: $childCode,
$space)''';
  }

  String _exportFlex(WidgetNode node, int indent, String widgetName) {
    final space = ' ' * indent;
    final background = _exportColor(
      node.props['backgroundColor']?.toString() ?? '#FFFFFF',
    );
    final borderColor = _exportColor(
      node.props['borderColor']?.toString() ?? '#CBD5E1',
    );
    final gap = _formatNumber(node.props['gap'] ?? 8);
    final padding = _formatNumber(node.props['padding'] ?? 8);
    final children = <String>[];
    final visibleChildren =
        node.children.where((child) => child.type != 'radioButton').toList();
    for (var i = 0; i < visibleChildren.length; i += 1) {
      final child = visibleChildren[i];
      children.add(
        '${' ' * (indent + 6)}SizedBox(width: ${_formatNumber(child.width)}, height: ${_formatNumber(child.height)}, child: ${_memberName(child)}),',
      );
      if (i < visibleChildren.length - 1) {
        children.add(
          '${' ' * (indent + 6)}SizedBox(${widgetName == 'Row' ? 'width' : 'height'}: $gap),',
        );
      }
    }
    final inlineRadioGroups =
        _exportInlineRadioGroups(node.children, indent + 6);
    if (inlineRadioGroups.trim().isNotEmpty) {
      children.add(inlineRadioGroups);
    }
    return '''Container(
$space  padding: const EdgeInsets.all($padding),
$space  decoration: BoxDecoration(
$space    color: $background,
$space    border: Border.all(color: $borderColor),
$space  ),
$space  child: $widgetName(
$space    mainAxisAlignment: ${_mainAxis(node.props['mainAxisAlignment'])},
$space    crossAxisAlignment: ${_crossAxis(node.props['crossAxisAlignment'])},
$space    children: [
${children.join('\n')}
$space    ],
$space  ),
$space)''';
  }

  String _exportInlineRadioGroups(List<WidgetNode> nodes, int indent) {
    final grouped = <String, List<WidgetNode>>{};
    for (final node in nodes.where((node) => node.type == 'radioButton')) {
      grouped.putIfAbsent(_radioGroupName(node), () => []).add(node);
    }
    final space = ' ' * indent;
    return grouped.entries.map((entry) {
      final groupName = _quote(entry.key);
      final controls = entry.value
          .map((node) =>
              '${' ' * (indent + 4)}SizedBox(width: ${_formatNumber(node.width)}, height: ${_formatNumber(node.height)}, child: ${_memberName(node)}),')
          .join('\n');
      return '''${space}StatefulBuilder(
$space  builder: (context, setControlState) => RadioGroup<String>(
$space    groupValue: radioGroupValues[$groupName],
$space    onChanged: (value) {
$space      setControlState(() => radioGroupValues[$groupName] = value);
$space      ${_radioGroupHandlerName(entry.key)}(value);
$space    },
$space    child: Column(
$space      mainAxisSize: MainAxisSize.min,
$space      children: [
$controls
$space      ],
$space    ),
$space  ),
$space),''';
    }).join('\n');
  }

  String _exportEventHandlers(List<WidgetNode> nodes) {
    final lines = <String>[];
    void collect(WidgetNode node) {
      if (node.type == 'button') {
        lines.add('''
  void ${_eventHandlerName(node, 'OnPressed')}() {
    // 여기에 ${_memberName(node)}의 클릭 이벤트를 구현합니다.
  }
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
      final quotedGroupName = _quote(groupName);
      lines.add('''
  void ${_radioGroupHandlerName(groupName)}(String? value) {
    // 여기에 $groupName 라디오 그룹의 변경 이벤트를 구현합니다.
    radioGroupValues[$quotedGroupName] = value;
  }
''');
    }
    return lines.join('\n');
  }

  List<WidgetNode> _flattenRadioNodes(List<WidgetNode> nodes) {
    final result = <WidgetNode>[];
    void collect(WidgetNode node) {
      if (node.type == 'radioButton') {
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
      '${groupName.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')}RadioGroupOnChanged';

  String _mainAxis(dynamic value) {
    return switch (value?.toString()) {
      'center' => 'MainAxisAlignment.center',
      'end' => 'MainAxisAlignment.end',
      'spaceBetween' => 'MainAxisAlignment.spaceBetween',
      _ => 'MainAxisAlignment.start',
    };
  }

  String _crossAxis(dynamic value) {
    return switch (value?.toString()) {
      'center' => 'CrossAxisAlignment.center',
      'end' => 'CrossAxisAlignment.end',
      'stretch' => 'CrossAxisAlignment.stretch',
      _ => 'CrossAxisAlignment.start',
    };
  }

  String _safeClassName(String name) {
    final compact = name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
    if (compact.isEmpty) {
      return 'GeneratedPage';
    }
    return '${compact.substring(0, 1).toUpperCase()}${compact.substring(1)}';
  }

  String _memberName(WidgetNode node) {
    final raw = node.props['memberName']?.toString() ??
        node.props['name']?.toString() ??
        node.id;
    final compact = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    final safe = compact.isEmpty ? node.id : compact;
    final prefixed = RegExp(r'^[0-9]').hasMatch(safe) ? 'control_$safe' : safe;
    return '${prefixed}Control';
  }

  String _radioGroupName(WidgetNode node) =>
      node.props['groupName']?.toString().isNotEmpty == true
          ? node.props['groupName'].toString()
          : 'default';

  String _radioValue(WidgetNode node) =>
      node.props['radioValue']?.toString().isNotEmpty == true
          ? node.props['radioValue'].toString()
          : node.id;

  String _eventHandlerName(WidgetNode node, String suffix) =>
      '${_memberName(node)}$suffix';

  List<String> _items(WidgetNode node) =>
      _csv(node.props['items']?.toString() ?? '');

  List<String> _csv(String text) => text
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  List<List<String>> _tableRows(WidgetNode node) =>
      (node.props['rows']?.toString() ?? '')
          .split(';')
          .where((row) => row.trim().isNotEmpty)
          .map(_csv)
          .toList();

  String _progressValue(WidgetNode node) {
    final value = double.tryParse((node.props['value'] ?? 0).toString()) ?? 0;
    final max = double.tryParse((node.props['max'] ?? 100).toString()) ?? 100;
    if (max <= 0) {
      return '0';
    }
    return (value / max).clamp(0, 1).toStringAsFixed(3);
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
    return "'${text.replaceAll('\\', '\\\\').replaceAll("'", "\\'")}'";
  }

  String _exportColor(String hexColor) {
    final normalized = hexColor.replaceAll('#', '').toUpperCase();
    final value =
        normalized.length == 6 ? 'FF$normalized' : normalized.padLeft(8, 'F');
    return 'const Color(0x$value)';
  }
}
