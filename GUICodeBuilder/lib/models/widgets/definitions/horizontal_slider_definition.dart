import '../widget_definition_base.dart';

class HorizontalSliderDefinition extends WidgetDefinition {
  const HorizontalSliderDefinition();
  @override
  String get typeId => 'horizontalSlider';
  @override
  String get label => 'Horizontal slider';
  @override
  String get description => '가로 슬라이더';
  @override
  double get defaultWidth => 220;
  @override
  double get defaultHeight => 44;
  @override
  get properties => rangeProperties;
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'value': 40, 'min': 0, 'max': 100});
}
