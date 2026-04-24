import 'package:flutter/material.dart';

// 패널 경계를 드래그해서 영역 크기를 조정하는 공통 핸들이다.
class ResizeHandle extends StatelessWidget {
  const ResizeHandle({required this.axis, required this.onDrag, super.key});

  final Axis axis;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = axis == Axis.horizontal;
    return MouseRegion(
      cursor: isHorizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          width: isHorizontal ? 8 : double.infinity,
          height: isHorizontal ? double.infinity : 8,
          color: const Color(0xFFE5E7EB),
          alignment: Alignment.center,
          child: Container(
            width: isHorizontal ? 2 : 44,
            height: isHorizontal ? 44 : 2,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
