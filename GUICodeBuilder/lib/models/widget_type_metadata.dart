import 'widget_node.dart';

// 팔레트와 속성 패널에서 쓰는 위젯 타입 설명을 제공한다.
class WidgetTypeMetadata {
  const WidgetTypeMetadata({
    required this.type,
    required this.label,
    required this.description,
  });

  final WidgetNodeType type;
  final String label;
  final String description;
}

const widgetTypeMetadata = <WidgetTypeMetadata>[
  WidgetTypeMetadata(
    type: WidgetNodeType.text,
    label: 'Text',
    description: '텍스트 라벨',
  ),
  WidgetTypeMetadata(
    type: WidgetNodeType.button,
    label: 'Button',
    description: '클릭 버튼',
  ),
  WidgetTypeMetadata(
    type: WidgetNodeType.container,
    label: 'Container',
    description: '자식 포함 박스',
  ),
  WidgetTypeMetadata(
    type: WidgetNodeType.row,
    label: 'Row',
    description: '가로 레이아웃',
  ),
  WidgetTypeMetadata(
    type: WidgetNodeType.column,
    label: 'Column',
    description: '세로 레이아웃',
  ),
];
