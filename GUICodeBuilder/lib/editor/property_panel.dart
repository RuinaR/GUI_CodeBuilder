import 'package:flutter/material.dart';

import '../models/editor_state.dart';
import '../models/widget_definition.dart';
import '../models/widget_node.dart';

// 선택된 노드와 캔버스의 속성을 편집한다.
class PropertyPanel extends StatelessWidget {
  const PropertyPanel({
    required this.editorState,
    required this.onChanged,
    required this.width,
    super.key,
  });

  final EditorState editorState;
  final VoidCallback onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final node = editorState.primarySelectedNode;
    return Container(
      width: width,
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
        _textField('class name', editorState.pageClassName, (value) {
          editorState.pageClassName = value.isEmpty ? 'GeneratedPage' : value;
        }),
        _textField('page title', editorState.pageTitle, (value) {
          editorState.pageTitle = value.isEmpty ? 'Generated Page' : value;
        }),
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
          subtitle: const Text('미리보기와 export IR에서 화면 크기 대응 여부를 표시합니다.'),
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
    final definition = definitionFor(node.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Properties',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          '${definition.label} / ${node.id}',
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
          subtitle: const Text('이 위젯을 반응형 대상으로 표시합니다.'),
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
        _textField(
          'member variable',
          node.props['memberName']?.toString() ?? node.id,
          (value) => editorState.updateNodeProp(node, 'memberName', value),
        ),
        for (final property in definition.properties)
          _propertyField(node, property),
      ],
    );
  }

  Widget _propertyField(WidgetNode node, WidgetPropertyDefinition property) {
    final rawValue = node.props[property.key] ?? property.fallback ?? '';
    switch (property.kind) {
      case WidgetPropertyKind.number:
        return _numberField(property.label, _readDouble(rawValue, 0), (value) {
          editorState.updateNodeProp(node, property.key, value);
        });
      case WidgetPropertyKind.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(property.label),
          value:
              rawValue == true || rawValue.toString().toLowerCase() == 'true',
          onChanged: (value) {
            editorState.updateNodeProp(node, property.key, value);
            onChanged();
          },
        );
      case WidgetPropertyKind.choice:
        return _choiceField(
          property.label,
          rawValue,
          property.choices,
          (value) => editorState.updateNodeProp(node, property.key, value),
        );
      case WidgetPropertyKind.multilineText:
        return _textField(
          property.label,
          rawValue.toString(),
          (value) => editorState.updateNodeProp(node, property.key, value),
          minLines: 3,
        );
      case WidgetPropertyKind.text:
        return _textField(
          property.label,
          rawValue.toString(),
          (value) => editorState.updateNodeProp(node, property.key, value),
        );
    }
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
        onChanged: (text) {
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
    ValueChanged<String> onValueChanged, {
    int minLines = 1,
  }) {
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
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : 6,
        onChanged: (text) {
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
