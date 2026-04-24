import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class LineEditDefinition extends WidgetDefinition {
  const LineEditDefinition();
  @override
  String get typeId => 'lineEdit';
  @override
  String get label => 'Line text box';
  @override
  String get description => '한 줄 입력';
  @override
  double get defaultWidth => 220;
  @override
  double get defaultHeight => 42;
  @override
  List<WidgetPropertyDefinition> get properties => const [
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
      ];
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'text': '', 'placeholder': 'Input'});
}
