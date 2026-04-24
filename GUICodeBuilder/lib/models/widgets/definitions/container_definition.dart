import '../widget_definition_base.dart';

class ContainerDefinition extends WidgetDefinition {
  const ContainerDefinition();
  @override
  String get typeId => 'container';
  @override
  String get label => 'Container';
  @override
  String get description => '절대 배치 컨테이너';
  @override
  bool get canHaveChildren => true;
  @override
  double get defaultWidth => 240;
  @override
  double get defaultHeight => 150;
  @override
  get properties => commonBoxProperties;
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'backgroundColor': '#F8FAFC'});
}
