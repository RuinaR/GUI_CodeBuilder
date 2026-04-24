import 'widget_node.dart';

class IrPage {
  const IrPage({
    required this.className,
    required this.title,
    required this.width,
    required this.height,
    required this.responsive,
  });

  final String className;
  final String title;
  final double width;
  final double height;
  final bool responsive;

  factory IrPage.fromJson(Map<String, dynamic> json) {
    final page = Map<String, dynamic>.from(json['page'] as Map? ?? {});
    return IrPage(
      className: page['className']?.toString() ?? 'GeneratedPage',
      title: page['title']?.toString() ?? 'Generated Page',
      width: readDouble(page['width'], 960),
      height: readDouble(page['height'], 640),
      responsive: readBool(page['responsive'], true),
    );
  }
}

class IrDocument {
  IrDocument({
    required this.page,
    required this.nodes,
  });

  final IrPage page;
  final List<WidgetNode> nodes;

  String get className => page.className;
  String get title => page.title;
  double get width => page.width;
  double get height => page.height;
  bool get responsive => page.responsive;

  factory IrDocument.fromJson(Map<String, dynamic> json) {
    return IrDocument(
      page: IrPage.fromJson(json),
      nodes: (json['nodes'] as List? ?? <dynamic>[]).whereType<Map>().map((
        nodeJson,
      ) {
        return WidgetNode.fromJson(Map<String, dynamic>.from(nodeJson));
      }).toList(),
    );
  }
}
