import '../widget_node.dart';

class NodeTreeOperations {
  const NodeTreeOperations();

  WidgetNode? findNodeById(List<WidgetNode> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) {
        return node;
      }
      final childNode = findNodeById(node.children, id);
      if (childNode != null) {
        return childNode;
      }
    }
    return null;
  }

  WidgetNode? findParentOf(List<WidgetNode> nodes, String id) {
    for (final node in nodes) {
      if (node.children.any((child) => child.id == id)) {
        return node;
      }
      final parent = findParentOf(node.children, id);
      if (parent != null) {
        return parent;
      }
    }
    return null;
  }

  List<WidgetNode> flattenNodes(List<WidgetNode> nodes) {
    final result = <WidgetNode>[];
    void collect(WidgetNode node) {
      result.add(node);
      for (final child in node.children) {
        collect(child);
      }
    }

    for (final node in nodes) {
      collect(node);
    }
    return result;
  }

  bool removeNodeById(List<WidgetNode> nodes, String id) {
    final index = nodes.indexWhere((node) => node.id == id);
    if (index >= 0) {
      nodes.removeAt(index);
      return true;
    }
    for (final node in nodes) {
      if (removeNodeById(node.children, id)) {
        return true;
      }
    }
    return false;
  }

  bool containsNode(WidgetNode root, String id) {
    if (root.id == id) {
      return true;
    }
    return root.children.any((child) => containsNode(child, id));
  }

  bool reorderNode(List<WidgetNode> nodes, String id, int direction) {
    final siblings = _findSiblingList(id, nodes);
    if (siblings == null) {
      return false;
    }
    final index = siblings.indexWhere((node) => node.id == id);
    final targetIndex = (index + direction).clamp(0, siblings.length - 1);
    if (index == targetIndex) {
      return false;
    }
    final node = siblings.removeAt(index);
    siblings.insert(targetIndex, node);
    return true;
  }

  int collectMaxId(List<WidgetNode> nodes) {
    var maxId = 0;
    for (final node in nodes) {
      final number = int.tryParse(node.id.replaceFirst('node_', '')) ?? 0;
      if (number > maxId) {
        maxId = number;
      }
      final childMaxId = collectMaxId(node.children);
      if (childMaxId > maxId) {
        maxId = childMaxId;
      }
    }
    return maxId;
  }

  List<WidgetNode>? _findSiblingList(String id, List<WidgetNode> nodes) {
    if (nodes.any((node) => node.id == id)) {
      return nodes;
    }
    for (final node in nodes) {
      final found = _findSiblingList(id, node.children);
      if (found != null) {
        return found;
      }
    }
    return null;
  }
}
