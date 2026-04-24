import 'editor_state/node_name_normalizer.dart';
import 'editor_state/node_transform_operations.dart';
import 'editor_state/node_tree_operations.dart';
import 'editor_state/snapshot_history.dart';
import 'widget_definition.dart';
import 'widget_node.dart';

class EditorState {
  EditorState() : _normalizer = const NodeNameNormalizer(_treeOperations);

  static const NodeTreeOperations _treeOperations = NodeTreeOperations();
  static const NodeTransformOperations _transformOperations =
      NodeTransformOperations();

  final NodeNameNormalizer _normalizer;
  final SnapshotHistory _history = SnapshotHistory();

  final List<WidgetNode> nodes = <WidgetNode>[];
  final Set<String> selectedIds = <String>{};
  String exportedJson = '';
  final Map<String, String> exportedCodes = <String, String>{};
  String pageClassName = 'GeneratedPage';
  String pageTitle = 'Generated Page';

  int _nextId = 1;
  double canvasWidth = 960;
  double canvasHeight = 640;
  double snapSize = 8;
  bool snapEnabled = true;
  bool responsivePreview = true;
  String? treeInsertParentId;

  bool get canUndo => _history.canUndo;

  List<WidgetNode> get selectedNodes {
    return selectedIds.map(findNodeById).whereType<WidgetNode>().toList();
  }

  WidgetNode? get primarySelectedNode {
    if (selectedIds.isEmpty) {
      return null;
    }
    return findNodeById(selectedIds.last);
  }

  WidgetNode addNode(String type, {String? parentId}) {
    _pushUndo();
    final node = _createDefaultNode(type);
    final resolvedParentId = parentId ?? treeInsertParentId;
    final parentNode =
        resolvedParentId == null ? null : findNodeById(resolvedParentId);

    if (parentNode != null && parentNode.canHaveChildren) {
      final childIndex = parentNode.children.length;
      node.x = _snap(16 + (childIndex * 16) % 160);
      node.y = _snap(32 + (childIndex * 18) % 120);
      parentNode.children.add(node);
    } else {
      nodes.add(node);
    }

    selectOnly(node.id);
    return node;
  }

  void selectOnly(String id) {
    selectedIds
      ..clear()
      ..add(id);
  }

  void toggleSelect(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
      return;
    }
    selectedIds.add(id);
  }

  void clearSelection() {
    selectedIds.clear();
  }

  void selectRootForInsert() {
    treeInsertParentId = null;
    clearSelection();
  }

  void selectTreeNodeForInsert(String id) {
    selectOnly(id);
    final node = findNodeById(id);
    if (node != null && node.canHaveChildren) {
      treeInsertParentId = id;
    }
  }

  void moveSelected(double deltaX, double deltaY) {
    _pushUndo();
    _transformOperations.moveNodes(
      selectedNodes,
      deltaX,
      deltaY,
      snap: _snap,
    );
  }

  void resizeNode(WidgetNode node, double deltaX, double deltaY) {
    _pushUndo();
    _transformOperations.resizeNode(node, deltaX, deltaY, snap: _snap);
  }

  void updateNodeProp(WidgetNode node, String key, dynamic value) {
    _pushUndo();
    if (key == 'name' || key == 'memberName') {
      node.payload[key] = _normalizer.uniquePayloadValue(
        nodes,
        node,
        key,
        value.toString(),
      );
      return;
    }
    node.payload[key] = value;
  }

  void updateNodeFrame(
    WidgetNode node, {
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    _transformOperations.updateFrame(
      node,
      x: x,
      y: y,
      width: width,
      height: height,
      snap: _snap,
    );
  }

  void duplicateSelected() {
    _pushUndo();
    final copiedNodes = <WidgetNode>[];
    for (final node in selectedNodes) {
      final parent = findParentOf(node.id);
      final copy = node.cloneWithNewIds(_createId);
      if (parent == null) {
        nodes.add(copy);
      } else {
        parent.children.add(copy);
      }
      copiedNodes.add(copy);
    }

    selectedIds
      ..clear()
      ..addAll(copiedNodes.map((node) => node.id));
  }

  void deleteSelected() {
    _pushUndo();
    final ids = selectedIds.toList();
    for (final id in ids) {
      _treeOperations.removeNodeById(nodes, id);
    }
    selectedIds.clear();
  }

  bool moveSelectionToParent(String? parentId) {
    _pushUndo();
    final moving = selectedNodes.where((node) => node.id != parentId).toList();
    if (moving.isEmpty) {
      return false;
    }

    final parent = parentId == null ? null : findNodeById(parentId);
    if (parent != null && !parent.canHaveChildren) {
      return false;
    }
    if (parent != null &&
        moving.any((node) => _treeOperations.containsNode(node, parent.id))) {
      return false;
    }

    for (final node in moving) {
      _treeOperations.removeNodeById(nodes, node.id);
    }
    if (parent == null) {
      nodes.addAll(moving);
    } else {
      parent.children.addAll(moving);
    }
    return true;
  }

  void reorderNode(String id, int direction) {
    _pushUndo();
    _treeOperations.reorderNode(nodes, id, direction);
  }

  void alignSelected(String mode) {
    _pushUndo();
    _transformOperations.alignNodes(selectedNodes, mode, snap: _snap);
  }

  bool moveNodeToParent(String nodeId, String? parentId) {
    if (nodeId == parentId) {
      return false;
    }
    final node = findNodeById(nodeId);
    final parent = parentId == null ? null : findNodeById(parentId);
    if (node == null || (parent != null && !parent.canHaveChildren)) {
      return false;
    }
    if (parent != null && _treeOperations.containsNode(node, parent.id)) {
      return false;
    }

    _pushUndo();
    _treeOperations.removeNodeById(nodes, node.id);
    if (parent == null) {
      nodes.add(node);
      treeInsertParentId = null;
    } else {
      node.x = _snap(16 + (parent.children.length * 16) % 160);
      node.y = _snap(32 + (parent.children.length * 18) % 120);
      parent.children.add(node);
      treeInsertParentId = parent.id;
    }
    selectOnly(node.id);
    return true;
  }

  bool undo() {
    final snapshot = _history.pop();
    if (snapshot == null) {
      return false;
    }
    _restoreSnapshot(snapshot);
    return true;
  }

  WidgetNode? findNodeById(String id) {
    return _treeOperations.findNodeById(nodes, id);
  }

  WidgetNode? findParentOf(String id) {
    return _treeOperations.findParentOf(nodes, id);
  }

  Map<String, dynamic> toIrJson() {
    _normalizer.normalize(nodes);
    return {
      'schemaVersion': 3,
      'generator': {
        'name': 'GUI Code Builder',
        'irPurpose':
            'single source for Flutter, Flet, PyQt, and HTML/CSS exporters',
      },
      'page': {
        'className': pageClassName,
        'title': pageTitle,
        'width': canvasWidth,
        'height': canvasHeight,
        'responsive': responsivePreview,
        'coordinateSystem': 'logicalPixels',
      },
      'exportTargets': ['flutter', 'flet', 'pyqt', 'html'],
      'nodes': nodes.map((node) => node.toJson()).toList(),
    };
  }

  void loadIrJson(Map<String, dynamic> json) {
    _restoreSnapshot(json);
  }

  void _pushUndo() {
    _history.push(toIrJson());
  }

  void _restoreSnapshot(Map<String, dynamic> snapshot) {
    final page = Map<String, dynamic>.from(
      snapshot['page'] ?? <String, dynamic>{},
    );
    pageClassName = page['className']?.toString() ?? 'GeneratedPage';
    pageTitle = page['title']?.toString() ?? 'Generated Page';
    canvasWidth = readDouble(page['width'], 960);
    canvasHeight = readDouble(page['height'], 640);
    responsivePreview = readBool(page['responsive'], true);
    nodes
      ..clear()
      ..addAll(
        (snapshot['nodes'] as List? ?? <dynamic>[]).whereType<Map>().map(
              (nodeJson) =>
                  WidgetNode.fromJson(Map<String, dynamic>.from(nodeJson)),
            ),
      );
    selectedIds.clear();
    treeInsertParentId = null;
    _nextId = _treeOperations.collectMaxId(nodes) + 1;
  }

  WidgetNode _createDefaultNode(String type) {
    final id = _createId();
    final definition = definitionFor(type);
    return WidgetNode(
      id: id,
      type: type,
      x: 80 + (nodes.length * 24) % 360,
      y: 80 + (nodes.length * 32) % 280,
      width: definition.defaultWidth,
      height: definition.defaultHeight,
      props: definition.defaultProps(id),
    );
  }

  String _createId() {
    return 'node_${_nextId++}';
  }

  double _snap(num value) {
    final doubleValue = value.toDouble();
    if (!snapEnabled || snapSize <= 0) {
      return doubleValue;
    }
    return (doubleValue / snapSize).round() * snapSize;
  }
}
