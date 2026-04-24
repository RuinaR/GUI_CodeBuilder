import '../widget_definition_base.dart';

class SpinBoxDefinition extends WidgetDefinition {
  const SpinBoxDefinition();
  @override
  String get typeId => 'spinBox';
  @override
  String get label => 'Spin box';
  @override
  String get description => '정수 입력';
  @override
  double get defaultWidth => 120;
  @override
  double get defaultHeight => 40;
  @override
  get properties => rangeProperties;
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'value': 0, 'min': 0, 'max': 100});
}
