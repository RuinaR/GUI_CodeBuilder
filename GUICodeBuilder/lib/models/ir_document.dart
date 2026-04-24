import 'widget_node.dart';

// 저장된 JSON IR을 exporter가 사용하기 쉬운 형태로 해석한다.
class IrDocument {
  IrDocument({
    required this.className,
    required this.title,
    required this.width,
    required this.height,
    required this.responsive,
    required this.nodes,
  });

  final String className;
  final String title;
  final double width;
  final double height;
  final bool responsive;
  final List<WidgetNode> nodes;

  factory IrDocument.fromJson(Map<String, dynamic> json) {
    final page = Map<String, dynamic>.from(json['page'] as Map? ?? {});
    return IrDocument(
      className: page['className']?.toString() ?? 'GeneratedPage',
      title: page['title']?.toString() ?? 'Generated Page',
      width: _readDouble(page['width'], 960),
      height: _readDouble(page['height'], 640),
      responsive: _readBool(page['responsive'], true),
      nodes: (json['nodes'] as List? ?? <dynamic>[]).whereType<Map>().map((
        nodeJson,
      ) {
        return WidgetNode.fromJson(Map<String, dynamic>.from(nodeJson));
      }).toList(),
    );
  }

  static double _readDouble(dynamic value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _readBool(dynamic value, bool fallback) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return fallback;
  }
}
