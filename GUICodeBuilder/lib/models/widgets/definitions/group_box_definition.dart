import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class GroupBoxDefinition extends WidgetDefinition {
  const GroupBoxDefinition();
  @override
  String get typeId => 'groupBox';
  @override
  String get label => 'Group box';
  @override
  String get description => '그룹 컨테이너';
  @override
  bool get canHaveChildren => true;
  @override
  double get defaultWidth => 280;
  @override
  double get defaultHeight => 180;
  @override
  List<WidgetPropertyDefinition> get properties => const [
        WidgetPropertyDefinition(
          key: 'title',
          label: 'title',
          kind: WidgetPropertyKind.text,
        ),
        ...commonBoxProperties,
      ];
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'title': 'Group', 'backgroundColor': '#F8FAFC'});
}
