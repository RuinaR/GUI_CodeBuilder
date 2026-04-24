import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class RadioButtonDefinition extends WidgetDefinition {
  const RadioButtonDefinition();
  @override
  String get typeId => 'radioButton';
  @override
  String get label => 'Radio button';
  @override
  String get description => '라디오 선택';
  @override
  double get defaultWidth => 190;
  @override
  double get defaultHeight => 40;
  @override
  List<WidgetPropertyDefinition> get properties => const [
        WidgetPropertyDefinition(
          key: 'text',
          label: 'text',
          kind: WidgetPropertyKind.text,
        ),
        WidgetPropertyDefinition(
          key: 'groupName',
          label: 'radio group name',
          kind: WidgetPropertyKind.text,
          fallback: 'default',
        ),
        WidgetPropertyDefinition(
          key: 'radioValue',
          label: 'radio value',
          kind: WidgetPropertyKind.text,
        ),
        WidgetPropertyDefinition(
          key: 'selected',
          label: 'selected by default',
          kind: WidgetPropertyKind.boolean,
          fallback: false,
        ),
      ];
  @override
  Map<String, dynamic> defaultProps(String id) => baseProps(id)
    ..addAll({
      'text': 'Radio',
      'selected': false,
      'groupName': 'default',
      'radioValue': id,
    });
}
