import 'package:flutter/material.dart';

import '../models/widget_node.dart';

// 노드 데이터를 Flutter 미리보기 위젯으로 렌더링한다.
class CanvasWidgetRenderer {
  Widget buildPreview(WidgetNode node) {
    switch (node.type) {
      case WidgetNodeType.text:
        return _buildText(node);
      case WidgetNodeType.button:
        return _buildButton(node);
      case WidgetNodeType.container:
        return _buildContainer(node);
      case WidgetNodeType.row:
        return _buildFlex(node, Axis.horizontal);
      case WidgetNodeType.column:
        return _buildFlex(node, Axis.vertical);
    }
  }

  Widget _buildText(WidgetNode node) {
    final align = switch (node.props['textAlign']?.toString()) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        node.props['text']?.toString() ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: TextStyle(
          fontSize: _readDouble(node.props['fontSize'], 16),
          fontFamily: node.props['fontFamily']?.toString(),
          fontWeight: node.props['fontWeight'] == 'bold'
              ? FontWeight.bold
              : FontWeight.normal,
          color: _readColor(node.props['color'], const Color(0xFF111827)),
        ),
      ),
    );
  }

  Widget _buildButton(WidgetNode node) {
    return SizedBox.expand(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _readColor(
            node.props['backgroundColor'],
            const Color(0xFF2563EB),
          ),
          foregroundColor: _readColor(
            node.props['foregroundColor'],
            Colors.white,
          ),
          textStyle: TextStyle(
            fontSize: _readDouble(node.props['fontSize'], 14),
            fontFamily: node.props['fontFamily']?.toString(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              _readDouble(node.props['borderRadius'], 6),
            ),
          ),
        ),
        onPressed: () {},
        child: Text(
          node.props['text']?.toString() ?? 'Button',
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildContainer(WidgetNode node) {
    return Container(
      padding: EdgeInsets.all(_readDouble(node.props['padding'], 0)),
      decoration: BoxDecoration(
        color: _readColor(
          node.props['backgroundColor'],
          const Color(0xFFF8FAFC),
        ),
        border: Border.all(
          color: _readColor(node.props['borderColor'], const Color(0xFF94A3B8)),
        ),
        borderRadius: BorderRadius.circular(
          _readDouble(node.props['borderRadius'], 6),
        ),
      ),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildFlex(WidgetNode node, Axis direction) {
    return Container(
      padding: EdgeInsets.all(_readDouble(node.props['padding'], 8)),
      decoration: BoxDecoration(
        color: _readColor(node.props['backgroundColor'], Colors.white),
        border: Border.all(
          color: _readColor(node.props['borderColor'], const Color(0xFFCBD5E1)),
        ),
      ),
      child: direction == Axis.horizontal
          ? Row(
              mainAxisAlignment: _mainAxis(node.props['mainAxisAlignment']),
              crossAxisAlignment: _crossAxis(node.props['crossAxisAlignment']),
              children: _buildFlexChildren(node, Axis.horizontal),
            )
          : Column(
              mainAxisAlignment: _mainAxis(node.props['mainAxisAlignment']),
              crossAxisAlignment: _crossAxis(node.props['crossAxisAlignment']),
              children: _buildFlexChildren(node, Axis.vertical),
            ),
    );
  }

  List<Widget> _buildFlexChildren(WidgetNode node, Axis direction) {
    final children = <Widget>[];
    final gap = _readDouble(node.props['gap'], 8);
    for (var i = 0; i < node.children.length; i += 1) {
      final child = node.children[i];
      children.add(
        SizedBox(
          width: child.width,
          height: child.height,
          child: buildPreview(child),
        ),
      );
      if (i < node.children.length - 1) {
        children.add(
          direction == Axis.horizontal
              ? SizedBox(width: gap)
              : SizedBox(height: gap),
        );
      }
    }
    return children;
  }

  MainAxisAlignment _mainAxis(dynamic value) {
    return switch (value?.toString()) {
      'center' => MainAxisAlignment.center,
      'end' => MainAxisAlignment.end,
      'spaceBetween' => MainAxisAlignment.spaceBetween,
      _ => MainAxisAlignment.start,
    };
  }

  CrossAxisAlignment _crossAxis(dynamic value) {
    return switch (value?.toString()) {
      'center' => CrossAxisAlignment.center,
      'end' => CrossAxisAlignment.end,
      'stretch' => CrossAxisAlignment.stretch,
      _ => CrossAxisAlignment.start,
    };
  }

  double _readDouble(dynamic value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Color _readColor(dynamic value, Color fallback) {
    final text = value?.toString().replaceAll('#', '') ?? '';
    final hex = text.length == 6 ? 'FF$text' : text;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}
