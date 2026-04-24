import '../widget_definition_base.dart';

class VerticalSliderDefinition extends WidgetDefinition {
  const VerticalSliderDefinition();
  @override
  String get typeId => 'verticalSlider';
  @override
  String get label => 'Vertical slider';
  @override
  String get description => '세로 슬라이더';
  @override
  double get defaultWidth => 56;
  @override
  double get defaultHeight => 180;
  @override
  get properties => rangeProperties;
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'value': 40, 'min': 0, 'max': 100});
}
