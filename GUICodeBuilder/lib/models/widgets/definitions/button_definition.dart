import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class ButtonDefinition extends WidgetDefinition {
  const ButtonDefinition();
  @override
  String get typeId => 'button';
  @override
  String get label => 'Button';
  @override
  String get description => '클릭 버튼';
  @override
  double get defaultWidth => 160;
  @override
  double get defaultHeight => 48;
  @override
  List<WidgetPropertyDefinition> get properties => const [
        ...commonTextProperties,
        ...commonBoxProperties,
        WidgetPropertyDefinition(
            key: 'foregroundColor',
            label: 'foreground color',
            kind: WidgetPropertyKind.text,
            fallback: '#FFFFFF'),
        WidgetPropertyDefinition(
            key: 'onClick',
            label: 'on click action',
            kind: WidgetPropertyKind.text),
      ];
  @override
  Map<String, dynamic> defaultProps(String id) => baseProps(id)
    ..addAll({
      'text': 'Button',
      'backgroundColor': '#2563EB',
      'foregroundColor': '#FFFFFF'
    });
}
