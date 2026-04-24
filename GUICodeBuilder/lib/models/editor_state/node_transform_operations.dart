import '../widget_node.dart';

class NodeTransformOperations {
  const NodeTransformOperations();

  void moveNodes(
    Iterable<WidgetNode> nodes,
    double deltaX,
    double deltaY, {
    required double Function(num value) snap,
  }) {
    for (final node in nodes) {
      node.x = snap(node.x + deltaX);
      node.y = snap(node.y + deltaY);
    }
  }

  void resizeNode(
    WidgetNode node,
    double deltaX,
    double deltaY, {
    required double Function(num value) snap,
  }) {
    node.width = snap((node.width + deltaX).clamp(24, 4000));
    node.height = snap((node.height + deltaY).clamp(24, 4000));
  }

  void updateFrame(
    WidgetNode node, {
    double? x,
    double? y,
    double? width,
    double? height,
    required double Function(num value) snap,
  }) {
    if (x != null) {
      node.x = snap(x);
    }
    if (y != null) {
      node.y = snap(y);
    }
    if (width != null) {
      node.width = snap(width.clamp(24, 4000));
    }
    if (height != null) {
      node.height = snap(height.clamp(24, 4000));
    }
  }

  void alignNodes(
    List<WidgetNode> nodes,
    String mode, {
    required double Function(num value) snap,
  }) {
    if (nodes.length < 2) {
      return;
    }
    switch (mode) {
      case 'left':
        final left = nodes.map((node) => node.x).reduce(_min);
        for (final node in nodes) {
          node.x = snap(left);
        }
      case 'right':
        final right = nodes.map((node) => node.x + node.width).reduce(_max);
        for (final node in nodes) {
          node.x = snap(right - node.width);
        }
      case 'top':
        final top = nodes.map((node) => node.y).reduce(_min);
        for (final node in nodes) {
          node.y = snap(top);
        }
      case 'bottom':
        final bottom = nodes.map((node) => node.y + node.height).reduce(_max);
        for (final node in nodes) {
          node.y = snap(bottom - node.height);
        }
      case 'hCenter':
        final center =
            nodes.map((node) => node.x + node.width / 2).reduce(_min);
        for (final node in nodes) {
          node.x = snap(center - node.width / 2);
        }
      case 'vCenter':
        final center =
            nodes.map((node) => node.y + node.height / 2).reduce(_min);
        for (final node in nodes) {
          node.y = snap(center - node.height / 2);
        }
    }
  }

  static double _min(double a, double b) => a < b ? a : b;

  static double _max(double a, double b) => a > b ? a : b;
}
