import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class CheckBoxDefinition extends WidgetDefinition {
  const CheckBoxDefinition();
  @override
  String get typeId => 'checkBox';
  @override
  String get label => 'Check box';
  @override
  String get description => '체크 선택';
  @override
  double get defaultWidth => 180;
  @override
  double get defaultHeight => 36;
  @override
  List<WidgetPropertyDefinition> get properties => const [
    WidgetPropertyDefinition(
      key: 'text',
      label: 'text',
      kind: WidgetPropertyKind.text,
    ),
    WidgetPropertyDefinition(
      key: 'checked',
      label: 'checked',
      kind: WidgetPropertyKind.boolean,
      fallback: false,
    ),
  ];
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'text': 'Check', 'checked': false});
}
