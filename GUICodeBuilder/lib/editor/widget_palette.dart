import 'package:flutter/material.dart';

import '../models/widget_definition.dart';

// 추가 가능한 위젯 목록을 보여주는 팔레트이다.
class WidgetPalette extends StatelessWidget {
  const WidgetPalette({required this.onAddNode, super.key});

  final ValueChanged<String> onAddNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Widget Palette',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                for (final meta in widgetDefinitions) _buildAddButton(meta),
              ],
            ),
          ),
          const Divider(height: 28),
          const Text(
            'Export pipeline',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Editor -> JSON IR -> Flutter/Flet/PyQt/HTML',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(WidgetDefinition meta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: () => onAddNode(meta.typeId),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meta.label),
              Text(
                meta.description,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
