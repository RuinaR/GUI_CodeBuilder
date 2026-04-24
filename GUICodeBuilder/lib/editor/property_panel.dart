import 'package:flutter/material.dart';

import '../models/editor_state.dart';
import '../models/widget_node.dart';

// 선택된 노드와 캔버스의 속성을 편집한다.
class PropertyPanel extends StatelessWidget {
  const PropertyPanel({
    required this.editorState,
    required this.onChanged,
    super.key,
  });

  final EditorState editorState;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final node = editorState.primarySelectedNode;
    return Container(
      width: 330,
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          _buildCanvasSection(),
          const Divider(height: 28),
          node == null ? _buildEmptyPanel() : _buildNodePanel(node),
        ],
      ),
    );
  }

  Widget _buildCanvasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Canvas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _numberField('canvas width', editorState.canvasWidth, (value) {
          editorState.canvasWidth = value.clamp(320, 4000);
        }),
        _numberField('canvas height', editorState.canvasHeight, (value) {
          editorState.canvasHeight = value.clamp(240, 4000);
        }),
        _numberField('snap size', editorState.snapSize, (value) {
          editorState.snapSize = value.clamp(1, 128);
        }),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Responsive preview'),
          value: editorState.responsivePreview,
          onChanged: (value) {
            editorState.responsivePreview = value;
            onChanged();
          },
        ),
      ],
    );
  }

  Widget _buildEmptyPanel() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Properties',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12),
        Text('Select a widget on the canvas or tree.'),
      ],
    );
  }

  Widget _buildNodePanel(WidgetNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Properties',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          '${node.type.name} / ${node.id}',
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 12),
        _numberField(
          'x',
          node.x,
          (value) => editorState.updateNodeFrame(node, x: value),
        ),
        _numberField(
          'y',
          node.y,
          (value) => editorState.updateNodeFrame(node, y: value),
        ),
        _numberField(
          'width',
          node.width,
          (value) => editorState.updateNodeFrame(node, width: value),
        ),
        _numberField(
          'height',
          node.height,
          (value) => editorState.updateNodeFrame(node, height: value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Responsive'),
          value: node.responsive,
          onChanged: (value) {
            node.responsive = value;
            onChanged();
          },
        ),
        const Divider(height: 28),
        _textField('name', node.props['name']?.toString() ?? node.id, (value) {
          editorState.updateNodeProp(node, 'name', value);
        }),
        if (_hasText(node)) ...[
          _textField('text', node.props['text']?.toString() ?? '', (value) {
            editorState.updateNodeProp(node, 'text', value);
          }),
          _numberField('font size', _readDouble(node.props['fontSize'], 16), (
            value,
          ) {
            editorState.updateNodeProp(node, 'fontSize', value);
          }),
          _textField(
            'font family',
            node.props['fontFamily']?.toString() ?? 'Arial',
            (value) => editorState.updateNodeProp(node, 'fontFamily', value),
          ),
          _choiceField(
              'font weight',
              node.props['fontWeight'],
              [
                'normal',
                'bold',
              ],
              (value) => editorState.updateNodeProp(node, 'fontWeight', value)),
        ],
        if (node.type == WidgetNodeType.text)
          _textField('text color', node.props['color']?.toString() ?? '#111827',
              (value) {
            editorState.updateNodeProp(node, 'color', value);
          }),
        if (node.type != WidgetNodeType.text) ...[
          _textField(
            'background color',
            node.props['backgroundColor']?.toString() ?? '#FFFFFF',
            (value) => editorState.updateNodeProp(
              node,
              'backgroundColor',
              value,
            ),
          ),
          _textField(
            'border color',
            node.props['borderColor']?.toString() ?? '#CBD5E1',
            (value) => editorState.updateNodeProp(node, 'borderColor', value),
          ),
        ],
        if (node.type == WidgetNodeType.button)
          _textField(
            'foreground color',
            node.props['foregroundColor']?.toString() ?? '#FFFFFF',
            (value) => editorState.updateNodeProp(
              node,
              'foregroundColor',
              value,
            ),
          ),
        if (node.canHaveChildren) ...[
          _numberField('padding', _readDouble(node.props['padding'], 0), (
            value,
          ) {
            editorState.updateNodeProp(node, 'padding', value);
          }),
          if (node.type != WidgetNodeType.container)
            _numberField('gap', _readDouble(node.props['gap'], 8), (value) {
              editorState.updateNodeProp(node, 'gap', value);
            }),
          if (node.type != WidgetNodeType.container) ...[
            _choiceField(
              'main axis',
              node.props['mainAxisAlignment'],
              ['start', 'center', 'end', 'spaceBetween'],
              (value) =>
                  editorState.updateNodeProp(node, 'mainAxisAlignment', value),
            ),
            _choiceField(
              'cross axis',
              node.props['crossAxisAlignment'],
              ['start', 'center', 'end', 'stretch'],
              (value) =>
                  editorState.updateNodeProp(node, 'crossAxisAlignment', value),
            ),
          ],
        ],
        if (node.type == WidgetNodeType.container ||
            node.type == WidgetNodeType.button)
          _numberField(
            'border radius',
            _readDouble(node.props['borderRadius'], 6),
            (value) => editorState.updateNodeProp(node, 'borderRadius', value),
          ),
      ],
    );
  }

  bool _hasText(WidgetNode node) {
    return node.type == WidgetNodeType.text ||
        node.type == WidgetNodeType.button;
  }

  Widget _choiceField(
    String label,
    dynamic value,
    List<String> choices,
    ValueChanged<String> onValueChanged,
  ) {
    final selected =
        choices.contains(value?.toString()) ? value.toString() : choices.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: selected,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final choice in choices)
            DropdownMenuItem(value: choice, child: Text(choice)),
        ],
        onChanged: (newValue) {
          if (newValue == null) {
            return;
          }
          onValueChanged(newValue);
          onChanged();
        },
      ),
    );
  }

  Widget _numberField(
    String label,
    double value,
    ValueChanged<double> onValueChanged,
  ) {
    final controller = TextEditingController(text: _formatNumber(value));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        onSubmitted: (text) {
          final parsed = double.tryParse(text);
          if (parsed != null) {
            onValueChanged(parsed);
            onChanged();
          }
        },
      ),
    );
  }

  Widget _textField(
    String label,
    String value,
    ValueChanged<String> onValueChanged,
  ) {
    final controller = TextEditingController(text: value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (text) {
          onValueChanged(text);
          onChanged();
        },
      ),
    );
  }

  double _readDouble(dynamic value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
