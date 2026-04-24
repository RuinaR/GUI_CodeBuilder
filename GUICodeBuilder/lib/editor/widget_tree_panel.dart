import 'package:flutter/material.dart';

import '../models/editor_state.dart';
import '../models/widget_node.dart';

// 부모-자식 노드 구조를 보여주고 선택/재배치를 돕는다.
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
      height: 180,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 260,
            child: _buildTreeList(editorState.nodes, 0),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildTreeActions()),
        ],
      ),
    );
  }

  Widget _buildTreeList(List<WidgetNode> nodes, int depth) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (depth == 0)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Widget Tree',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        for (final node in nodes) ...[
          _TreeNodeTile(
            node: node,
            depth: depth,
            selected: editorState.selectedIds.contains(node.id),
            onTap: () {
              editorState.selectOnly(node.id);
              onChanged();
            },
            onToggle: () {
              editorState.toggleSelect(node.id);
              onChanged();
            },
          ),
          if (node.children.isNotEmpty)
            _buildTreeList(node.children, depth + 1),
        ],
      ],
    );
  }

  Widget _buildTreeActions() {
    final selected = editorState.primarySelectedNode;
    final containers = _collectContainers(editorState.nodes);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.tonal(
            onPressed: selected == null
                ? null
                : () {
                    editorState.moveSelectionToParent(null);
                    onChanged();
                  },
            child: const Text('Move Root'),
          ),
          FilledButton.tonal(
            onPressed: selected == null
                ? null
                : () {
                    editorState.reorderNode(selected.id, -1);
                    onChanged();
                  },
            child: const Text('Up'),
          ),
          FilledButton.tonal(
            onPressed: selected == null
                ? null
                : () {
                    editorState.reorderNode(selected.id, 1);
                    onChanged();
                  },
            child: const Text('Down'),
          ),
          DropdownMenu<String>(
            width: 260,
            hintText: 'Move to parent',
            enabled: selected != null,
            onSelected: (parentId) {
              if (parentId == null) {
                return;
              }
              editorState.moveSelectionToParent(parentId);
              onChanged();
            },
            dropdownMenuEntries: [
              for (final node in containers)
                if (node.id != selected?.id)
                  DropdownMenuEntry(value: node.id, label: node.displayName),
            ],
          ),
        ],
      ),
    );
  }

  List<WidgetNode> _collectContainers(List<WidgetNode> nodes) {
    final result = <WidgetNode>[];
    for (final node in nodes) {
      if (node.canHaveChildren) {
        result.add(node);
      }
      result.addAll(_collectContainers(node.children));
    }
    return result;
  }
}

// 트리의 한 줄을 그리는 작은 타일이다.
class _TreeNodeTile extends StatelessWidget {
  const _TreeNodeTile({
    required this.node,
    required this.depth,
    required this.selected,
    required this.onTap,
    required this.onToggle,
  });

  final WidgetNode node;
  final int depth;
  final bool selected;
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
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
            border: Border.all(
              color:
                  selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            '${node.type.name}  ${node.displayName}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
