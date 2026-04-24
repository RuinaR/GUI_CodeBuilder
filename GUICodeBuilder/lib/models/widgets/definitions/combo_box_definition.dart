import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class ComboBoxDefinition extends WidgetDefinition {
  const ComboBoxDefinition();
  @override
  String get typeId => 'comboBox';
  @override
  String get label => 'Combo box';
  @override
  String get description => '드롭다운 선택';
  @override
  double get defaultWidth => 180;
  @override
  double get defaultHeight => 44;
  @override
  List<WidgetPropertyDefinition> get properties => const [
        WidgetPropertyDefinition(
            key: 'items',
            label: 'items (comma separated)',
            kind: WidgetPropertyKind.multilineText,
            fallback: 'One,Two,Three'),
        WidgetPropertyDefinition(
            key: 'value',
            label: 'selected value',
            kind: WidgetPropertyKind.text),
      ];
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'items': 'One,Two,Three', 'value': 'One'});
}
