import '../models/export_format.dart';
import '../models/ir_document.dart';
import '../models/widget_node.dart';
import 'code_exporter.dart';

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
  const $className({super.key});

  @override
  State<$className> createState() => _${className}State();
}

class _${className}State extends State<$className> {
${_exportMembers(nodes)}

  @override
  Widget build(BuildContext context) {
    initialize();
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
${nodes.map((node) => _exportPositionedNode(node, 22)).join('\n')}
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

  void onButtonPressed(String controlId) {}
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
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: $className()));
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
      '  final Map<String, String?> radioGroupValues = <String, String?>{};'
    ];
    void collect(WidgetNode node) {
      lines.add('  late Widget ${_memberName(node)};');
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
    lines.add('$space${_memberName(node)} = ${_exportWidget(node, indent)};');
    return lines.join('\n');
  }

  String _exportWidget(WidgetNode node, int indent) {
    switch (node.type) {
      case 'text':
        return _exportText(node, indent);
      case 'button':
        return _exportButton(node, indent);
      case 'container':
      case 'groupBox':
      case 'tabs':
      case 'scrollArea':
        return _exportContainer(node, indent);
      case 'row':
        return _exportFlex(node, indent, 'Row');
      case 'column':
        return _exportFlex(node, indent, 'Column');
      case 'radioButton':
        return _exportRadio(node, indent);
      case 'checkBox':
      case 'spinBox':
      case 'doubleSpinBox':
      case 'comboBox':
      case 'textBox':
      case 'lineEdit':
      case 'listBox':
      case 'progressBar':
      case 'horizontalSlider':
      case 'verticalSlider':
      case 'table':
      case 'image':
        return _exportSimple(node, indent, node.type);
      default:
        return _exportSimple(node, indent, node.type);
    }
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

  String _exportRadio(WidgetNode node, int indent) {
    final space = ' ' * indent;
    final groupName = _quote(_radioGroupName(node));
    final value = _quote(_radioValue(node));
    final text = _quote(node.props['text']?.toString() ?? 'Radio');
    return '''RadioGroup<String>(
$space  groupValue: radioGroupValues[$groupName],
$space  onChanged: (value) => setState(() => radioGroupValues[$groupName] = value),
$space  child: Row(
$space    children: [
$space      SizedBox(
$space        width: 32,
$space        height: 32,
$space        child: Radio<String>(value: $value),
$space      ),
$space      Expanded(child: Text($text, overflow: TextOverflow.ellipsis)),
$space    ],
$space  ),
$space)''';
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
$space  onPressed: () => onButtonPressed(${_quote(node.id)}),
$space  child: FittedBox(fit: BoxFit.scaleDown, child: Text($text)),
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
    final children = node.children
        .map((child) => _exportPositionedNode(child, indent + 12))
        .join('\n');
    final childCode = node.children.isEmpty
        ? 'null'
        : '''Padding(
$space    padding: const EdgeInsets.all($padding),
$space    child: Stack(
$space      children: [
$children
$space      ],
$space    ),
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
    for (var i = 0; i < node.children.length; i += 1) {
      final child = node.children[i];
      children.add(
        '${' ' * (indent + 6)}SizedBox(width: ${_formatNumber(child.width)}, height: ${_formatNumber(child.height)}, child: ${_memberName(child)}),',
      );
      if (i < node.children.length - 1) {
        children.add(
          '${' ' * (indent + 6)}SizedBox(${widgetName == 'Row' ? 'width' : 'height'}: $gap),',
        );
      }
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
