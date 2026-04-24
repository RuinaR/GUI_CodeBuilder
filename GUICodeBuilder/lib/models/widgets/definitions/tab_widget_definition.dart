import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class TabWidgetDefinition extends WidgetDefinition {
  const TabWidgetDefinition();
  @override
  String get typeId => 'tabs';
  @override
  String get label => 'Tab widget';
  @override
  String get description => '탭 컨테이너';
  @override
  bool get canHaveChildren => true;
  @override
  double get defaultWidth => 320;
  @override
  double get defaultHeight => 220;
  @override
  List<WidgetPropertyDefinition> get properties => const [
        WidgetPropertyDefinition(
          key: 'tabs',
          label: 'tabs (comma separated)',
          kind: WidgetPropertyKind.multilineText,
        ),
        ...commonBoxProperties,
      ];
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'tabs': 'Tab 1,Tab 2'});
}
