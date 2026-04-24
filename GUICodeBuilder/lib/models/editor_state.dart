import 'widget_definition.dart';
import 'widget_node.dart';

// 편집기의 선택, 트리, 배치 규칙을 관리한다.
class EditorState {
  EditorState();

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
  final List<Map<String, dynamic>> _undoStack = <Map<String, dynamic>>[];

  bool get canUndo => _undoStack.isNotEmpty;

  List<WidgetNode> get selectedNodes {
    return selectedIds.map(findNodeById).whereType<WidgetNode>().toList();
  }

  WidgetNode? get primarySelectedNode {
    if (selectedIds.isEmpty) {
      return null;
    }
    return findNodeById(selectedIds.last);
  }

  // 팔레트에서 새 노드를 만들고 선택 상태로 전환한다.
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

  // 단일 선택을 설정한다.
  void selectOnly(String id) {
    selectedIds
      ..clear()
      ..add(id);
  }

  // 다중 선택 토글을 처리한다.
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

  // 트리에서 루트를 선택하면 새 노드는 루트에 추가된다.
  void selectRootForInsert() {
    treeInsertParentId = null;
    clearSelection();
  }

  // 트리에서 컨테이너 노드를 선택하면 새 노드는 해당 노드의 자식으로 추가된다.
  void selectTreeNodeForInsert(String id) {
    selectOnly(id);
    final node = findNodeById(id);
    if (node != null && node.canHaveChildren) {
      treeInsertParentId = id;
    }
  }

  // 선택된 노드를 스냅 규칙에 맞춰 이동한다.
  void moveSelected(double deltaX, double deltaY) {
    _pushUndo();
    for (final node in selectedNodes) {
      node.x = _snap(node.x + deltaX);
      node.y = _snap(node.y + deltaY);
    }
  }

  // 선택 노드의 크기를 변경한다.
  void resizeNode(WidgetNode node, double deltaX, double deltaY) {
    _pushUndo();
    node.width = _snap((node.width + deltaX).clamp(24, 4000));
    node.height = _snap((node.height + deltaY).clamp(24, 4000));
  }

  void updateNodeProp(WidgetNode node, String key, dynamic value) {
    _pushUndo();
    node.props[key] = value;
  }

  // 위치와 크기 값을 한 곳에서 검증하고 반영한다.
  void updateNodeFrame(
    WidgetNode node, {
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    if (x != null) {
      node.x = _snap(x);
    }
    if (y != null) {
      node.y = _snap(y);
    }
    if (width != null) {
      node.width = _snap(width.clamp(24, 4000));
    }
    if (height != null) {
      node.height = _snap(height.clamp(24, 4000));
    }
  }

  // 선택된 모든 노드를 같은 부모 아래에 복제한다.
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

  // 선택된 노드를 트리에서 제거한다.
  void deleteSelected() {
    _pushUndo();
    final ids = selectedIds.toList();
    for (final id in ids) {
      _removeNodeById(nodes, id);
    }
    selectedIds.clear();
  }

  // 선택된 노드를 부모 컨테이너 아래로 이동한다.
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
        moving.any((node) => _containsNode(node, parent.id))) {
      return false;
    }

    for (final node in moving) {
      _removeNodeById(nodes, node.id);
    }
    if (parent == null) {
      nodes.addAll(moving);
    } else {
      parent.children.addAll(moving);
    }
    return true;
  }

  // 선택 노드를 부모의 앞뒤 순서 안에서 이동한다.
  void reorderNode(String id, int direction) {
    _pushUndo();
    final siblings = _findSiblingList(id, nodes);
    if (siblings == null) {
      return;
    }
    final index = siblings.indexWhere((node) => node.id == id);
    final targetIndex = (index + direction).clamp(0, siblings.length - 1);
    if (index == targetIndex) {
      return;
    }
    final node = siblings.removeAt(index);
    siblings.insert(targetIndex, node);
  }

  // 선택된 노드를 기준선에 맞춰 정렬한다.
  void alignSelected(String mode) {
    _pushUndo();
    final items = selectedNodes;
    if (items.length < 2) {
      return;
    }
    switch (mode) {
      case 'left':
        final left = items.map((node) => node.x).reduce(_min);
        for (final node in items) {
          node.x = _snap(left);
        }
      case 'right':
        final right = items.map((node) => node.x + node.width).reduce(_max);
        for (final node in items) {
          node.x = _snap(right - node.width);
        }
      case 'top':
        final top = items.map((node) => node.y).reduce(_min);
        for (final node in items) {
          node.y = _snap(top);
        }
      case 'bottom':
        final bottom = items.map((node) => node.y + node.height).reduce(_max);
        for (final node in items) {
          node.y = _snap(bottom - node.height);
        }
      case 'hCenter':
        final center =
            items.map((node) => node.x + node.width / 2).reduce(_min);
        for (final node in items) {
          node.x = _snap(center - node.width / 2);
        }
      case 'vCenter':
        final center =
            items.map((node) => node.y + node.height / 2).reduce(_min);
        for (final node in items) {
          node.y = _snap(center - node.height / 2);
        }
    }
  }

  // 단일 노드를 지정한 부모 아래로 옮긴다.
  bool moveNodeToParent(String nodeId, String? parentId) {
    if (nodeId == parentId) {
      return false;
    }
    final node = findNodeById(nodeId);
    final parent = parentId == null ? null : findNodeById(parentId);
    if (node == null || (parent != null && !parent.canHaveChildren)) {
      return false;
    }
    if (parent != null && _containsNode(node, parent.id)) {
      return false;
    }
    _pushUndo();
    _removeNodeById(nodes, node.id);
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

  // 마지막 편집 전 상태로 되돌린다.
  bool undo() {
    if (_undoStack.isEmpty) {
      return false;
    }
    final snapshot = _undoStack.removeLast();
    _restoreSnapshot(snapshot);
    return true;
  }

  WidgetNode? findNodeById(String id) {
    return _findNodeById(nodes, id);
  }

  WidgetNode? findParentOf(String id) {
    return _findParentOf(nodes, id);
  }

  // 현재 편집 상태를 JSON IR로 변환한다.
  Map<String, dynamic> toIrJson() {
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

  // JSON IR을 편집 상태로 불러온다.
  void loadIrJson(Map<String, dynamic> json) {
    final page = Map<String, dynamic>.from(json['page'] ?? <String, dynamic>{});
    pageClassName = page['className']?.toString() ?? 'GeneratedPage';
    pageTitle = page['title']?.toString() ?? 'Generated Page';
    canvasWidth = _readDouble(page['width'], 960);
    canvasHeight = _readDouble(page['height'], 640);
    responsivePreview = _readBool(page['responsive'], true);
    nodes
      ..clear()
      ..addAll(
        (json['nodes'] as List? ?? <dynamic>[]).whereType<Map>().map(
              (nodeJson) =>
                  WidgetNode.fromJson(Map<String, dynamic>.from(nodeJson)),
            ),
      );
    selectedIds.clear();
    _nextId = _collectMaxId(nodes) + 1;
  }

  void _pushUndo() {
    _undoStack.add(toIrJson());
    if (_undoStack.length > 80) {
      _undoStack.removeAt(0);
    }
  }

  void _restoreSnapshot(Map<String, dynamic> snapshot) {
    final page = Map<String, dynamic>.from(
      snapshot['page'] ?? <String, dynamic>{},
    );
    pageClassName = page['className']?.toString() ?? 'GeneratedPage';
    pageTitle = page['title']?.toString() ?? 'Generated Page';
    canvasWidth = _readDouble(page['width'], 960);
    canvasHeight = _readDouble(page['height'], 640);
    responsivePreview = _readBool(page['responsive'], true);
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
    _nextId = _collectMaxId(nodes) + 1;
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

  WidgetNode? _findNodeById(List<WidgetNode> targetNodes, String id) {
    for (final node in targetNodes) {
      if (node.id == id) {
        return node;
      }
      final childNode = _findNodeById(node.children, id);
      if (childNode != null) {
        return childNode;
      }
    }
    return null;
  }

  WidgetNode? _findParentOf(List<WidgetNode> targetNodes, String id) {
    for (final node in targetNodes) {
      if (node.children.any((child) => child.id == id)) {
        return node;
      }
      final parent = _findParentOf(node.children, id);
      if (parent != null) {
        return parent;
      }
    }
    return null;
  }

  List<WidgetNode>? _findSiblingList(String id, List<WidgetNode> targetNodes) {
    if (targetNodes.any((node) => node.id == id)) {
      return targetNodes;
    }
    for (final node in targetNodes) {
      final found = _findSiblingList(id, node.children);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  bool _removeNodeById(List<WidgetNode> targetNodes, String id) {
    final index = targetNodes.indexWhere((node) => node.id == id);
    if (index >= 0) {
      targetNodes.removeAt(index);
      return true;
    }
    for (final node in targetNodes) {
      if (_removeNodeById(node.children, id)) {
        return true;
      }
    }
    return false;
  }

  bool _containsNode(WidgetNode root, String id) {
    if (root.id == id) {
      return true;
    }
    return root.children.any((child) => _containsNode(child, id));
  }

  int _collectMaxId(List<WidgetNode> targetNodes) {
    int maxId = 0;
    for (final node in targetNodes) {
      final number = int.tryParse(node.id.replaceFirst('node_', '')) ?? 0;
      if (number > maxId) {
        maxId = number;
      }
      final childMaxId = _collectMaxId(node.children);
      if (childMaxId > maxId) {
        maxId = childMaxId;
      }
    }
    return maxId;
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

  static double _min(double a, double b) => a < b ? a : b;

  static double _max(double a, double b) => a > b ? a : b;
}
