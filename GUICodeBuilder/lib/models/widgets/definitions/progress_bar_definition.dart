import '../widget_definition_base.dart';

class ProgressBarDefinition extends WidgetDefinition {
  const ProgressBarDefinition();
  @override
  String get typeId => 'progressBar';
  @override
  String get label => 'Progress bar';
  @override
  String get description => '진행률 표시';
  @override
  double get defaultWidth => 220;
  @override
  double get defaultHeight => 32;
  @override
  get properties => rangeProperties;
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'value': 40, 'max': 100});
}
