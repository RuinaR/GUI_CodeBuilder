import '../widget_definition_base.dart';

class LabelDefinition extends WidgetDefinition {
  const LabelDefinition();
  @override
  String get typeId => 'text';
  @override
  String get label => 'Label';
  @override
  String get description => '텍스트 라벨';
  @override
  double get defaultWidth => 180;
  @override
  double get defaultHeight => 44;
  @override
  get properties => commonTextProperties;
  @override
  Map<String, dynamic> defaultProps(String id) => baseProps(id)
    ..addAll({'text': 'Label', 'fontSize': 22, 'backgroundColor': '#FFFFFF00'});
}
