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
    _initializeControls();
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

  void _initializeControls() {
${nodes.map((node) => _exportMemberAssignment(node, 4)).join('\n')}
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
    final lines = <String>[];
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
    lines.add('$space${_memberName(node)} = ${_exportWidget(node, indent)};');
    return lines.join('\n');
  }

  String _exportWidget(WidgetNode node, int indent) {
    switch (node.type) {
      case WidgetNodeType.text:
        return _exportText(node, indent);
      case WidgetNodeType.button:
        return _exportButton(node, indent);
      case WidgetNodeType.container:
        return _exportContainer(node, indent);
      case WidgetNodeType.row:
        return _exportFlex(node, indent, 'Row');
      case WidgetNodeType.column:
        return _exportFlex(node, indent, 'Column');
    }
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
$space  child: Text($text),
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
    final raw = node.props['name']?.toString() ?? node.id;
    final compact = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    final safe = compact.isEmpty ? node.id : compact;
    final prefixed = RegExp(r'^[0-9]').hasMatch(safe) ? 'control_$safe' : safe;
    return '${prefixed}Control';
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
