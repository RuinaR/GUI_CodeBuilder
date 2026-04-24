import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class TextBoxDefinition extends WidgetDefinition {
  const TextBoxDefinition();
  @override
  String get typeId => 'textBox';
  @override
  String get label => 'Ordinary text box';
  @override
  String get description => '여러 줄 텍스트';
  @override
  double get defaultWidth => 220;
  @override
  double get defaultHeight => 110;
  @override
  List<WidgetPropertyDefinition> get properties => const [
        WidgetPropertyDefinition(
          key: 'text',
          label: 'text',
          kind: WidgetPropertyKind.multilineText,
        ),
        ...commonTextProperties,
      ];
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'text': 'Text box'});
}
