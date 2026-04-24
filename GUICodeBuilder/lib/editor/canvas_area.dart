import 'package:flutter/material.dart';

import '../models/editor_state.dart';
import '../models/widget_node.dart';
import '../renderers/canvas_widget_renderer.dart';

// 캔버스 영역에서 노드 선택, 이동, 크기 조절을 처리한다.
class CanvasArea extends StatelessWidget {
  const CanvasArea({
    required this.editorState,
    required this.renderer,
    required this.onChanged,
    super.key,
  });

  final EditorState editorState;
  final CanvasWidgetRenderer renderer;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: const Color(0xFFE5E7EB),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Container(
              width: editorState.canvasWidth,
              height: editorState.canvasHeight,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  editorState.clearSelection();
                  onChanged();
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildSnapGrid(),
                    for (final entry in _flattenCanvasNodes())
                      _buildNode(entry.node, entry.offset),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSnapGrid() {
    if (!editorState.snapEnabled) {
      return const SizedBox.expand();
    }

    return CustomPaint(
      size: Size(editorState.canvasWidth, editorState.canvasHeight),
      painter: _SnapGridPainter(editorState.snapSize),
    );
  }

  Widget _buildNode(WidgetNode node, Offset offset) {
    final selected = editorState.selectedIds.contains(node.id);
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: node.width,
      height: node.height,
      child: _DraggableNodeShell(
        node: node,
        selected: selected,
        renderer: renderer,
        onSelect: (multiSelect) {
          if (multiSelect) {
            editorState.toggleSelect(node.id);
          } else {
            editorState.selectOnly(node.id);
          }
          onChanged();
        },
        onMove: (delta) {
          editorState.moveSelected(delta.dx, delta.dy);
          onChanged();
        },
        onResize: (delta) {
          editorState.resizeNode(node, delta.dx, delta.dy);
          onChanged();
        },
      ),
    );
  }

  List<_CanvasNodeEntry> _flattenCanvasNodes() {
    final entries = <_CanvasNodeEntry>[];
    void collect(WidgetNode node, Offset parentOffset) {
      final offset = parentOffset + Offset(node.x, node.y);
      entries.add(_CanvasNodeEntry(node, offset));
      for (final child in node.children) {
        collect(child, offset);
      }
    }

    for (final node in editorState.nodes) {
      collect(node, Offset.zero);
    }
    return entries;
  }
}

class _CanvasNodeEntry {
  const _CanvasNodeEntry(this.node, this.offset);

  final WidgetNode node;
  final Offset offset;
}

// 단일 노드의 드래그/선택 테두리를 담당한다.
class _DraggableNodeShell extends StatefulWidget {
  const _DraggableNodeShell({
    required this.node,
    required this.selected,
    required this.renderer,
    required this.onSelect,
    required this.onMove,
    required this.onResize,
  });

  final WidgetNode node;
  final bool selected;
  final CanvasWidgetRenderer renderer;
  final ValueChanged<bool> onSelect;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset> onResize;

  @override
  State<_DraggableNodeShell> createState() => _DraggableNodeShellState();
}

class _DraggableNodeShellState extends State<_DraggableNodeShell> {
  Offset _moveDelta = Offset.zero;
  Offset _resizeDelta = Offset.zero;
  bool _isMoving = false;
  bool _isResizing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onSelect(false),
      onSecondaryTap: () => widget.onSelect(true),
      onPanStart: (_) {
        _moveDelta = Offset.zero;
        _isMoving = true;
        widget.onSelect(false);
      },
      onPanUpdate: (details) {
        setState(() => _moveDelta += details.delta);
      },
      onPanEnd: (_) {
        widget.onMove(_moveDelta);
        setState(() {
          _moveDelta = Offset.zero;
          _isMoving = false;
        });
      },
      onPanCancel: () {
        setState(() {
          _moveDelta = Offset.zero;
          _isMoving = false;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: widget.renderer.buildPreview(widget.node)),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.selected
                        ? const Color(0xFF2563EB)
                        : const Color(0x3394A3B8),
                    width: widget.selected ? 2 : 1,
                  ),
                ),
              ),
            ),
          ),
          if (widget.selected)
            Positioned(
              right: -6,
              bottom: -6,
              width: 18,
              height: 18,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) {
                  _resizeDelta = Offset.zero;
                  _isResizing = true;
                },
                onPanUpdate: (details) {
                  setState(() => _resizeDelta += details.delta);
                },
                onPanEnd: (_) {
                  widget.onResize(_resizeDelta);
                  setState(() {
                    _resizeDelta = Offset.zero;
                    _isResizing = false;
                  });
                },
                onPanCancel: () {
                  setState(() {
                    _resizeDelta = Offset.zero;
                    _isResizing = false;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          if (_isMoving || _isResizing) _buildGhostBox(),
        ],
      ),
    );
  }

  Widget _buildGhostBox() {
    final width = (widget.node.width + (_isResizing ? _resizeDelta.dx : 0))
        .clamp(24, 4000)
        .toDouble();
    final height = (widget.node.height + (_isResizing ? _resizeDelta.dy : 0))
        .clamp(24, 4000)
        .toDouble();
    return Positioned(
      left: _isMoving ? _moveDelta.dx : 0,
      top: _isMoving ? _moveDelta.dy : 0,
      width: width,
      height: height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x222563EB),
            border: Border.all(color: const Color(0xFF2563EB), width: 2),
          ),
        ),
      ),
    );
  }
}

// 스냅 간격을 캔버스 위에 격자로 표시한다.
class _SnapGridPainter extends CustomPainter {
  const _SnapGridPainter(this.snapSize);

  final double snapSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += snapSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += snapSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnapGridPainter oldDelegate) {
    return oldDelegate.snapSize != snapSize;
  }
}
