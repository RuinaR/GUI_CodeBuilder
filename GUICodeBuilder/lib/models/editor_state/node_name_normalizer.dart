import '../widget_node.dart';
import 'node_tree_operations.dart';

class NodeNameNormalizer {
  const NodeNameNormalizer(this._tree);

  final NodeTreeOperations _tree;

  void normalize(List<WidgetNode> nodes) {
    _normalizePayloadKey(nodes, 'name');
    _normalizePayloadKey(nodes, 'memberName');
    _normalizeRadioValues(nodes);
  }

  String uniquePayloadValue(
    List<WidgetNode> nodes,
    WidgetNode target,
    String key,
    String value,
  ) {
    final used = <String>{};
    for (final node in _tree.flattenNodes(nodes)) {
      if (node.id == target.id) {
        continue;
      }
      final current = node.payload.string(key);
      if (current.isNotEmpty) {
        used.add(current);
      }
    }
    return _uniqueText(value.isEmpty ? target.id : value, used);
  }

  void _normalizePayloadKey(List<WidgetNode> nodes, String key) {
    final used = <String>{};
    for (final node in _tree.flattenNodes(nodes)) {
      final raw = node.payload.string(key, fallback: node.id);
      final unique = _uniqueText(raw.isEmpty ? node.id : raw, used);
      node.payload[key] = unique;
      used.add(unique);
    }
  }

  void _normalizeRadioValues(List<WidgetNode> nodes) {
    final usedByGroup = <String, Set<String>>{};
    for (final node in _tree.flattenNodes(nodes)) {
      if (!node.isRadioButton) {
        continue;
      }
      final rawGroupName = node.payload.string('groupName');
      final groupName = rawGroupName.isNotEmpty ? rawGroupName : 'default';
      final used = usedByGroup.putIfAbsent(groupName, () => <String>{});
      final raw = node.payload.string('radioValue', fallback: node.id);
      final unique = _uniqueText(raw.isEmpty ? node.id : raw, used);
      node.payload['radioValue'] = unique;
      used.add(unique);
    }
  }

  String _uniqueText(String value, Set<String> used) {
    if (!used.contains(value)) {
      return value;
    }
    var index = 1;
    var candidate = '${value}_$index';
    while (used.contains(candidate)) {
      index += 1;
      candidate = '${value}_$index';
    }
    return candidate;
  }
}
