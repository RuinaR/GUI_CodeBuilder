import '../widget_definition_base.dart';

class ScrollAreaDefinition extends WidgetDefinition {
  const ScrollAreaDefinition();
  @override
  String get typeId => 'scrollArea';
  @override
  String get label => 'Scroll widget';
  @override
  String get description => '스크롤 컨테이너';
  @override
  bool get canHaveChildren => true;
  @override
  double get defaultWidth => 300;
  @override
  double get defaultHeight => 220;
  @override
  get properties => commonBoxProperties;
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'backgroundColor': '#FFFFFF'});
}
