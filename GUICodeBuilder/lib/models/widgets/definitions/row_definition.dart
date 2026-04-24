import '../../layout_mode.dart';
import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class RowDefinition extends WidgetDefinition {
  const RowDefinition();
  @override
  String get typeId => 'row';
  @override
  String get label => 'Row';
  @override
  String get description => '가로 레이아웃';
  @override
  bool get canHaveChildren => true;
  @override
  LayoutMode get layoutMode => LayoutMode.row;
  @override
  double get defaultWidth => 320;
  @override
  double get defaultHeight => 110;
  @override
  List<WidgetPropertyDefinition> get properties => const [
        ...commonBoxProperties,
        ...flexProperties,
      ];
  @override
  Map<String, dynamic> defaultProps(String id) => baseProps(id)
    ..addAll({
      'gap': 8,
      'mainAxisAlignment': 'start',
      'crossAxisAlignment': 'start',
    });
}
