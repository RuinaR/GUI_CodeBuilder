import '../layout_mode.dart';
import 'widget_definition_base.dart';
import 'widget_property_definition.dart';
import 'definitions/button_definition.dart';
import 'definitions/check_box_definition.dart';
import 'definitions/combo_box_definition.dart';
import 'definitions/image_widget_definition.dart';
import 'definitions/label_definition.dart';
import 'definitions/radio_button_definition.dart';

class SimpleWidgetDefinition extends WidgetDefinition {
  const SimpleWidgetDefinition({
    required this.typeId,
    required this.label,
    required this.description,
    required this.defaultWidth,
    required this.defaultHeight,
    this.canHaveChildren = false,
    this.layoutMode = LayoutMode.absolute,
    required this.properties,
    required this.propsBuilder,
  });

  @override
  final String typeId;
  @override
  final String label;
  @override
  final String description;
  @override
  final double defaultWidth;
  @override
  final double defaultHeight;
  @override
  final bool canHaveChildren;
  @override
  final LayoutMode layoutMode;
  @override
  final List<WidgetPropertyDefinition> properties;
  final Map<String, dynamic> Function(String id) propsBuilder;

  @override
  Map<String, dynamic> defaultProps(String id) => propsBuilder(id);
}

final widgetDefinitions = <WidgetDefinition>[
  const ButtonDefinition(),
  const RadioButtonDefinition(),
  const CheckBoxDefinition(),
  SimpleWidgetDefinition(
    typeId: 'spinBox',
    label: 'Spin box',
    description: '정수 입력',
    defaultWidth: 120,
    defaultHeight: 40,
    properties: rangeProperties,
    propsBuilder: (id) =>
        baseProps(id)..addAll({'value': 0, 'min': 0, 'max': 100}),
  ),
  SimpleWidgetDefinition(
    typeId: 'doubleSpinBox',
    label: 'Double spin box',
    description: '실수 입력',
    defaultWidth: 140,
    defaultHeight: 40,
    properties: rangeProperties,
    propsBuilder: (id) =>
        baseProps(id)..addAll({'value': 0.0, 'min': 0.0, 'max': 100.0}),
  ),
  const LabelDefinition(),
  const ComboBoxDefinition(),
  SimpleWidgetDefinition(
    typeId: 'textBox',
    label: 'Ordinary text box',
    description: '여러 줄 텍스트',
    defaultWidth: 220,
    defaultHeight: 110,
    properties: const [
      WidgetPropertyDefinition(
        key: 'text',
        label: 'text',
        kind: WidgetPropertyKind.multilineText,
      ),
      ...commonTextProperties,
    ],
    propsBuilder: (id) => baseProps(id)..addAll({'text': 'Text box'}),
  ),
  SimpleWidgetDefinition(
    typeId: 'lineEdit',
    label: 'Line text box',
    description: '한 줄 입력',
    defaultWidth: 220,
    defaultHeight: 42,
    properties: const [
      WidgetPropertyDefinition(
        key: 'placeholder',
        label: 'placeholder',
        kind: WidgetPropertyKind.text,
      ),
      WidgetPropertyDefinition(
        key: 'text',
        label: 'text',
        kind: WidgetPropertyKind.text,
      ),
    ],
    propsBuilder: (id) =>
        baseProps(id)..addAll({'text': '', 'placeholder': 'Input'}),
  ),
  SimpleWidgetDefinition(
    typeId: 'listBox',
    label: 'List text box',
    description: '목록 표시',
    defaultWidth: 220,
    defaultHeight: 130,
    properties: const [
      WidgetPropertyDefinition(
        key: 'items',
        label: 'items (comma separated)',
        kind: WidgetPropertyKind.multilineText,
      ),
    ],
    propsBuilder: (id) =>
        baseProps(id)..addAll({'items': 'Item 1,Item 2,Item 3'}),
  ),
  SimpleWidgetDefinition(
    typeId: 'progressBar',
    label: 'Progress bar',
    description: '진행률 표시',
    defaultWidth: 220,
    defaultHeight: 32,
    properties: rangeProperties,
    propsBuilder: (id) => baseProps(id)..addAll({'value': 40, 'max': 100}),
  ),
  SimpleWidgetDefinition(
    typeId: 'horizontalSlider',
    label: 'Horizontal slider',
    description: '가로 슬라이더',
    defaultWidth: 220,
    defaultHeight: 44,
    properties: rangeProperties,
    propsBuilder: (id) =>
        baseProps(id)..addAll({'value': 40, 'min': 0, 'max': 100}),
  ),
  SimpleWidgetDefinition(
    typeId: 'verticalSlider',
    label: 'Vertical slider',
    description: '세로 슬라이더',
    defaultWidth: 56,
    defaultHeight: 180,
    properties: rangeProperties,
    propsBuilder: (id) =>
        baseProps(id)..addAll({'value': 40, 'min': 0, 'max': 100}),
  ),
  SimpleWidgetDefinition(
    typeId: 'table',
    label: 'Table widget',
    description: '표 형태 데이터',
    defaultWidth: 300,
    defaultHeight: 180,
    properties: const [
      WidgetPropertyDefinition(
        key: 'columns',
        label: 'columns (comma separated)',
        kind: WidgetPropertyKind.text,
      ),
      WidgetPropertyDefinition(
        key: 'rows',
        label: 'rows (semicolon separated)',
        kind: WidgetPropertyKind.multilineText,
      ),
    ],
    propsBuilder: (id) =>
        baseProps(id)..addAll({'columns': 'Name,Value', 'rows': 'A,1;B,2'}),
  ),
  const ImageWidgetDefinition(),
  SimpleWidgetDefinition(
    typeId: 'groupBox',
    label: 'Group box',
    description: '그룹 컨테이너',
    defaultWidth: 280,
    defaultHeight: 180,
    canHaveChildren: true,
    properties: const [
      WidgetPropertyDefinition(
        key: 'title',
        label: 'title',
        kind: WidgetPropertyKind.text,
      ),
      ...commonBoxProperties,
    ],
    propsBuilder: (id) =>
        baseProps(id)..addAll({'title': 'Group', 'backgroundColor': '#F8FAFC'}),
  ),
  SimpleWidgetDefinition(
    typeId: 'tabs',
    label: 'Tab widget',
    description: '탭 컨테이너',
    defaultWidth: 320,
    defaultHeight: 220,
    canHaveChildren: true,
    properties: const [
      WidgetPropertyDefinition(
        key: 'tabs',
        label: 'tabs (comma separated)',
        kind: WidgetPropertyKind.multilineText,
      ),
      ...commonBoxProperties,
    ],
    propsBuilder: (id) => baseProps(id)..addAll({'tabs': 'Tab 1,Tab 2'}),
  ),
  SimpleWidgetDefinition(
    typeId: 'scrollArea',
    label: 'Scroll widget',
    description: '스크롤 컨테이너',
    defaultWidth: 300,
    defaultHeight: 220,
    canHaveChildren: true,
    properties: commonBoxProperties,
    propsBuilder: (id) => baseProps(id)..addAll({'backgroundColor': '#FFFFFF'}),
  ),
  SimpleWidgetDefinition(
    typeId: 'container',
    label: 'Container',
    description: '절대 배치 컨테이너',
    defaultWidth: 240,
    defaultHeight: 150,
    canHaveChildren: true,
    properties: commonBoxProperties,
    propsBuilder: (id) => baseProps(id)..addAll({'backgroundColor': '#F8FAFC'}),
  ),
  SimpleWidgetDefinition(
    typeId: 'row',
    label: 'Row',
    description: '가로 레이아웃',
    defaultWidth: 320,
    defaultHeight: 110,
    canHaveChildren: true,
    layoutMode: LayoutMode.row,
    properties: const [...commonBoxProperties, ...flexProperties],
    propsBuilder: (id) => baseProps(id)
      ..addAll({
        'gap': 8,
        'mainAxisAlignment': 'start',
        'crossAxisAlignment': 'start',
      }),
  ),
  SimpleWidgetDefinition(
    typeId: 'column',
    label: 'Column',
    description: '세로 레이아웃',
    defaultWidth: 260,
    defaultHeight: 200,
    canHaveChildren: true,
    layoutMode: LayoutMode.column,
    properties: const [...commonBoxProperties, ...flexProperties],
    propsBuilder: (id) => baseProps(id)
      ..addAll({
        'gap': 8,
        'mainAxisAlignment': 'start',
        'crossAxisAlignment': 'start',
      }),
  ),
];

WidgetDefinition definitionFor(String typeId) {
  return widgetDefinitions.firstWhere(
    (definition) => definition.typeId == typeId,
    orElse: () => widgetDefinitions.firstWhere(
      (definition) => definition.typeId == 'container',
    ),
  );
}
