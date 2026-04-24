import '../../layout_mode.dart';
import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class ColumnDefinition extends WidgetDefinition {
  const ColumnDefinition();
  @override
  String get typeId => 'column';
  @override
  String get label => 'Column';
  @override
  String get description => '세로 레이아웃';
  @override
  bool get canHaveChildren => true;
  @override
  LayoutMode get layoutMode => LayoutMode.column;
  @override
  double get defaultWidth => 260;
  @override
  double get defaultHeight => 200;
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
