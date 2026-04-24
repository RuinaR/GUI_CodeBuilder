import '../widget_definition_base.dart';
import '../widget_property_definition.dart';

class ImageWidgetDefinition extends WidgetDefinition {
  const ImageWidgetDefinition();
  @override
  String get typeId => 'image';
  @override
  String get label => 'Image widget';
  @override
  String get description => '이미지 표시';
  @override
  double get defaultWidth => 180;
  @override
  double get defaultHeight => 120;
  @override
  List<WidgetPropertyDefinition> get properties => const [
        WidgetPropertyDefinition(
            key: 'src', label: 'image path/url', kind: WidgetPropertyKind.text),
        WidgetPropertyDefinition(
            key: 'text', label: 'fallback text', kind: WidgetPropertyKind.text),
      ];
  @override
  Map<String, dynamic> defaultProps(String id) =>
      baseProps(id)..addAll({'src': '', 'text': 'Image'});
}
