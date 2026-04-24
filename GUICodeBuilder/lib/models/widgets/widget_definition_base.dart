import '../layout_mode.dart';
import 'widget_property_definition.dart';

// 위젯/컨트롤 정의가 제공해야 하는 공통 계약이다.
abstract class WidgetDefinition {
  const WidgetDefinition();

  String get typeId;
  String get label;
  String get description;
  bool get canHaveChildren => false;
  LayoutMode get layoutMode => LayoutMode.absolute;
  double get defaultWidth;
  double get defaultHeight;
  List<WidgetPropertyDefinition> get properties;
  Map<String, dynamic> defaultProps(String id);
}

Map<String, dynamic> baseProps(String id) {
  return {
    'name': id,
    'memberName': id,
    'responsive': true,
    'fontSize': 14,
    'fontFamily': 'Arial',
    'color': '#111827',
    'backgroundColor': '#FFFFFF',
    'foregroundColor': '#111827',
    'borderColor': '#CBD5E1',
    'borderRadius': 4,
    'padding': 8,
    'onClick': '',
  };
}

const commonTextProperties = <WidgetPropertyDefinition>[
  WidgetPropertyDefinition(
      key: 'text', label: 'text', kind: WidgetPropertyKind.text),
  WidgetPropertyDefinition(
      key: 'fontSize',
      label: 'font size',
      kind: WidgetPropertyKind.number,
      fallback: 14),
  WidgetPropertyDefinition(
      key: 'fontFamily',
      label: 'font family',
      kind: WidgetPropertyKind.text,
      fallback: 'Arial'),
  WidgetPropertyDefinition(
      key: 'fontWeight',
      label: 'font weight',
      kind: WidgetPropertyKind.choice,
      choices: ['normal', 'bold'],
      fallback: 'normal'),
  WidgetPropertyDefinition(
      key: 'color',
      label: 'text color',
      kind: WidgetPropertyKind.text,
      fallback: '#111827'),
];

const commonBoxProperties = <WidgetPropertyDefinition>[
  WidgetPropertyDefinition(
      key: 'backgroundColor',
      label: 'background color',
      kind: WidgetPropertyKind.text,
      fallback: '#FFFFFF'),
  WidgetPropertyDefinition(
      key: 'borderColor',
      label: 'border color',
      kind: WidgetPropertyKind.text,
      fallback: '#CBD5E1'),
  WidgetPropertyDefinition(
      key: 'borderRadius',
      label: 'border radius',
      kind: WidgetPropertyKind.number,
      fallback: 4),
  WidgetPropertyDefinition(
      key: 'padding',
      label: 'padding',
      kind: WidgetPropertyKind.number,
      fallback: 8),
];

const rangeProperties = <WidgetPropertyDefinition>[
  WidgetPropertyDefinition(
      key: 'value',
      label: 'value',
      kind: WidgetPropertyKind.number,
      fallback: 0),
  WidgetPropertyDefinition(
      key: 'min', label: 'min', kind: WidgetPropertyKind.number, fallback: 0),
  WidgetPropertyDefinition(
      key: 'max', label: 'max', kind: WidgetPropertyKind.number, fallback: 100),
];

const flexProperties = <WidgetPropertyDefinition>[
  WidgetPropertyDefinition(
      key: 'gap', label: 'gap', kind: WidgetPropertyKind.number, fallback: 8),
  WidgetPropertyDefinition(
      key: 'mainAxisAlignment',
      label: 'main axis',
      kind: WidgetPropertyKind.choice,
      choices: ['start', 'center', 'end', 'spaceBetween'],
      fallback: 'start'),
  WidgetPropertyDefinition(
      key: 'crossAxisAlignment',
      label: 'cross axis',
      kind: WidgetPropertyKind.choice,
      choices: ['start', 'center', 'end', 'stretch'],
      fallback: 'start'),
];
