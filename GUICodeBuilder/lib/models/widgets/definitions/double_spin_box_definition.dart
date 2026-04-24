import '../widget_definition_base.dart';

class DoubleSpinBoxDefinition extends WidgetDefinition {
  const DoubleSpinBoxDefinition();
  @override
  String get typeId => 'doubleSpinBox';
  @override
  String get label => 'Double spin box';
  @override
  String get description => '실수 입력';
  @override
  double get defaultWidth => 140;
  @override
  double get defaultHeight => 40;
  @override
  get properties => rangeProperties;
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'value': 0.0, 'min': 0.0, 'max': 100.0});
}
