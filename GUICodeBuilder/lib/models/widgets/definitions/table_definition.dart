import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class TableDefinition extends WidgetDefinition {
  const TableDefinition();
  @override
  String get typeId => 'table';
  @override
  String get label => 'Table widget';
  @override
  String get description => '표 형태 데이터';
  @override
  double get defaultWidth => 300;
  @override
  double get defaultHeight => 180;
  @override
  List<WidgetPropertyDefinition> get properties => const [
        WidgetPropertyDefinition(
          key: 'columns',
          label: 'columns (comma separated)',
          kind: WidgetPropertyKind.text,
        ),
        WidgetPropertyDefinition(
          key: 'rows',
          label: 'rows (semicolon separated)',
          kind: WidgetPropertyKind.multilineText,
        ),
      ];
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'columns': 'Name,Value', 'rows': 'A,1;B,2'});
}
