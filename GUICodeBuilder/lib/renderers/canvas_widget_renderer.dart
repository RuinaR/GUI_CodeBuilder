import 'package:flutter/material.dart';

import '../models/widget_node.dart';

// 노드 데이터를 Flutter 미리보기 위젯으로 렌더링한다.
class CanvasWidgetRenderer {
  Widget buildPreview(WidgetNode node) {
    switch (node.type) {
      case 'text':
        return _buildText(node);
      case 'button':
        return _buildButton(node);
      case 'radioButton':
        return _labeledBox(
          node,
          Icon(
            node.props['selected'] == true
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 20,
          ),
          trailing: '[${node.props['groupName'] ?? 'default'}]',
        );
      case 'checkBox':
        return _labeledBox(
          node,
          Checkbox(value: node.props['checked'] == true, onChanged: (_) {}),
        );
      case 'spinBox':
      case 'doubleSpinBox':
      case 'lineEdit':
        return _inputLike(
          node,
          node.props['placeholder']?.toString() ??
              node.props['value']?.toString() ??
              '',
        );
      case 'comboBox':
        return _comboLike(node);
      case 'textBox':
        return _inputLike(
          node,
          node.props['text']?.toString() ?? '',
          multiline: true,
        );
      case 'listBox':
        return _listLike(node);
      case 'progressBar':
        return LinearProgressIndicator(value: _ratio(node));
      case 'horizontalSlider':
        return Slider(value: _ratio(node), onChanged: (_) {});
      case 'verticalSlider':
        return RotatedBox(
          quarterTurns: 3,
          child: Slider(value: _ratio(node), onChanged: (_) {}),
        );
      case 'table':
        return _tableLike(node);
      case 'image':
        return _imageLike(node);
      case 'groupBox':
      case 'tabs':
      case 'scrollArea':
      case 'container':
        return _buildContainer(node);
      case 'row':
        return _buildFlex(node, Axis.horizontal);
      case 'column':
        return _buildFlex(node, Axis.vertical);
      default:
        return _inputLike(node, node.displayName);
    }
  }

  Widget _buildText(WidgetNode node) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        node.props['text']?.toString() ?? node.props['name']?.toString() ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
    final title = node.props['title']?.toString();
    final child = title == null || title.isEmpty
        ? const SizedBox.expand()
        : Align(
            alignment: Alignment.topLeft,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
    return Container(
      padding: EdgeInsets.all(_readDouble(node.props['padding'], 8)),
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
      child: child,
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
      alignment: Alignment.topLeft,
      child: Text(
        direction == Axis.horizontal ? 'Row' : 'Column',
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      ),
    );
  }

  Widget _labeledBox(WidgetNode node, Widget control, {String? trailing}) {
    return Row(
      children: [
        control,
        Expanded(
          child: Text(
            trailing == null
                ? (node.props['text']?.toString() ?? node.displayName)
                : '${node.props['text']?.toString() ?? node.displayName} $trailing',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _inputLike(WidgetNode node, String text, {bool multiline = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: multiline ? Alignment.topLeft : Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        color: Colors.white,
      ),
      child: Text(text, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _comboLike(WidgetNode node) =>
      _inputLike(node, '${node.props['value'] ?? 'Select'}  v');

  Widget _listLike(WidgetNode node) {
    final items = _items(node).take(4).join('\\n');
    return _inputLike(node, items, multiline: true);
  }

  Widget _tableLike(WidgetNode node) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: const Center(child: Text('Table')),
    );
  }

  Widget _imageLike(WidgetNode node) {
    return Container(
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: Text(node.props['text']?.toString() ?? 'Image'),
    );
  }

  List<String> _items(WidgetNode node) =>
      (node.props['items']?.toString() ?? '')
          .split(',')
          .where((item) => item.trim().isNotEmpty)
          .toList();

  double _ratio(WidgetNode node) {
    final value = _readDouble(node.props['value'], 0);
    final max = _readDouble(node.props['max'], 100);
    if (max <= 0) return 0;
    return (value / max).clamp(0, 1).toDouble();
  }

  double _readDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Color _readColor(dynamic value, Color fallback) {
    final text = value?.toString().replaceAll('#', '') ?? '';
    final hex = text.length == 6 ? 'FF$text' : text;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}
