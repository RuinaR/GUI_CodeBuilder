import 'package:flutter/material.dart';

import '../models/editor_state.dart';
import '../models/widget_node.dart';

// 부모-자식 노드 구조를 보여주고 드래그앤드롭 재배치를 처리한다.
class WidgetTreePanel extends StatelessWidget {
  const WidgetTreePanel({
    required this.editorState,
    required this.onChanged,
    super.key,
  });

  final EditorState editorState;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: _buildTreeList(),
    );
  }

  Widget _buildTreeList() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'Widget Tree',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        _RootDropTile(
          active: editorState.treeInsertParentId == null,
          onTap: () {
            editorState.selectRootForInsert();
            onChanged();
          },
          onAccept: (nodeId) {
            editorState.moveNodeToParent(nodeId, null);
            onChanged();
          },
        ),
        for (final row in _flattenRows(editorState.nodes, 0))
          _TreeNodeTile(
            node: row.node,
            depth: row.depth,
            selected: editorState.selectedIds.contains(row.node.id),
            insertTarget: editorState.treeInsertParentId == row.node.id,
            onTap: () {
              editorState.selectTreeNodeForInsert(row.node.id);
              onChanged();
            },
            onToggle: () {
              editorState.toggleSelect(row.node.id);
              onChanged();
            },
            onAccept: row.node.canHaveChildren
                ? (draggedId) {
                    editorState.moveNodeToParent(draggedId, row.node.id);
                    onChanged();
                  }
                : null,
          ),
      ],
    );
  }

  List<_TreeRow> _flattenRows(List<WidgetNode> nodes, int depth) {
    final rows = <_TreeRow>[];
    for (final node in nodes) {
      rows.add(_TreeRow(node, depth));
      rows.addAll(_flattenRows(node.children, depth + 1));
    }
    return rows;
  }
}

class _TreeRow {
  const _TreeRow(this.node, this.depth);

  final WidgetNode node;
  final int depth;
}

class _TreeNodeTile extends StatelessWidget {
  const _TreeNodeTile({
    required this.node,
    required this.depth,
    required this.selected,
    required this.insertTarget,
    required this.onTap,
    required this.onToggle,
    required this.onAccept,
  });

  final WidgetNode node;
  final int depth;
  final bool selected;
  final bool insertTarget;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final ValueChanged<String>? onAccept;

  @override
  Widget build(BuildContext context) {
    final tile = _TreeTileBody(
      node: node,
      depth: depth,
      selected: selected,
      insertTarget: insertTarget,
      onTap: onTap,
      onToggle: onToggle,
    );

    final draggable = Draggable<String>(
      data: node.id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 260, child: tile),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );

    if (onAccept == null) {
      return draggable;
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != node.id,
      onAcceptWithDetails: (details) => onAccept!(details.data),
      builder: (context, candidates, rejects) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: candidates.isEmpty
                ? Colors.transparent
                : const Color(0xFFEFF6FF),
          ),
          child: draggable,
        );
      },
    );
  }
}

class _TreeTileBody extends StatelessWidget {
  const _TreeTileBody({
    required this.node,
    required this.depth,
    required this.selected,
    required this.insertTarget,
    required this.onTap,
    required this.onToggle,
  });

  final WidgetNode node;
  final int depth;
  final bool selected;
  final bool insertTarget;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 14, bottom: 4),
      child: InkWell(
        onTap: onTap,
        onSecondaryTap: onToggle,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
            border: Border.all(
              color: insertTarget
                  ? const Color(0xFF16A34A)
                  : selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE5E7EB),
              width: insertTarget ? 2 : 1,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  node.children.isEmpty ? '' : '▾',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              Expanded(
                child: Text(
                  '${node.type}  ${node.displayName}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (node.canHaveChildren)
                const Text(
                  '+drop',
                  style: TextStyle(fontSize: 10, color: Color(0xFF16A34A)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RootDropTile extends StatelessWidget {
  const _RootDropTile({
    required this.active,
    required this.onTap,
    required this.onAccept,
  });

  final bool active;
  final VoidCallback onTap;
  final ValueChanged<String> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, rejects) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: candidates.isNotEmpty
                    ? const Color(0xFFEFF6FF)
                    : active
                    ? const Color(0xFFF0FDF4)
                    : Colors.transparent,
                border: Border.all(
                  color: active || candidates.isNotEmpty
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFE5E7EB),
                  width: active || candidates.isNotEmpty ? 2 : 1,
                ),
              ),
              alignment: Alignment.centerLeft,
              child: const Text(
                'ROOT  여기로 드롭하면 최상위로 이동',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      },
    );
  }
}
