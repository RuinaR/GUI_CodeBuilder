import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class ListBoxDefinition extends WidgetDefinition {
  const ListBoxDefinition();
  @override
  String get typeId => 'listBox';
  @override
  String get label => 'List text box';
  @override
  String get description => '목록 표시';
  @override
  double get defaultWidth => 220;
  @override
  double get defaultHeight => 130;
  @override
  List<WidgetPropertyDefinition> get properties => const [
        WidgetPropertyDefinition(
          key: 'items',
          label: 'items (comma separated)',
          kind: WidgetPropertyKind.multilineText,
        ),
      ];
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'items': 'Item 1,Item 2,Item 3'});
}
