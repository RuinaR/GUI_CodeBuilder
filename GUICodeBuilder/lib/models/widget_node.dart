import 'layout_mode.dart';
import 'widget_definition.dart';

// 위젯 트리의 단일 노드와 화면 배치 정보를 가진다.
class WidgetNode {
  WidgetNode({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    Map<String, dynamic>? props,
    List<WidgetNode>? children,
  })  : props = props ?? <String, dynamic>{},
        children = children ?? <WidgetNode>[];

  final String id;
  String type;
  double x;
  double y;
  double width;
  double height;
  Map<String, dynamic> props;
  List<WidgetNode> children;

  String get displayName => props['name']?.toString().isNotEmpty == true
      ? props['name'].toString()
      : '$type($id)';

  bool get canHaveChildren {
    return definitionFor(type).canHaveChildren;
  }

  LayoutMode get layoutMode {
    return definitionFor(type).layoutMode;
  }

  bool get responsive {
    return _readBool(props['responsive'], true);
  }

  set responsive(bool value) {
    props['responsive'] = value;
  }

  // 선택된 노드를 복제할 때 하위 트리도 새 id로 복사한다.
  WidgetNode cloneWithNewIds(String Function() createId, {double offset = 16}) {
    final newNode = WidgetNode(
      id: createId(),
      type: type,
      x: x + offset,
      y: y + offset,
      width: width,
      height: height,
      props: Map<String, dynamic>.from(props),
      children: <WidgetNode>[],
    );
    newNode.props['name'] = newNode.id;
    newNode.props['memberName'] = newNode.id;
    newNode.children = children
        .map((child) => child.cloneWithNewIds(createId, offset: offset))
        .toList();
    return newNode;
  }

  // JSON IR로 저장하기 위한 Map 형태로 변환한다.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'role': canHaveChildren ? 'layout' : 'control',
      'frame': {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'responsive': responsive,
      },
      'content': _contentProps(),
      'style': _styleProps(),
      'layout': _layoutProps(),
      'behavior': _behaviorProps(),
      'props': props,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }

  // 예전 IR과의 호환을 위해 평면 구조도 필요할 때 사용할 수 있다.
  Map<String, dynamic> toLegacyJson() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'props': props,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }

  // JSON IR에서 노드 객체를 복원한다.
  factory WidgetNode.fromJson(Map<String, dynamic> json) {
    final frame = Map<String, dynamic>.from(
      json['frame'] as Map? ?? <String, dynamic>{},
    );
    final props = <String, dynamic>{};
    props.addAll(Map<String, dynamic>.from(json['props'] as Map? ?? {}));
    props.addAll(Map<String, dynamic>.from(json['content'] as Map? ?? {}));
    props.addAll(Map<String, dynamic>.from(json['style'] as Map? ?? {}));
    props.addAll(Map<String, dynamic>.from(json['layout'] as Map? ?? {}));
    props.addAll(Map<String, dynamic>.from(json['behavior'] as Map? ?? {}));
    return WidgetNode(
      id: json['id']?.toString() ?? 'node_0',
      type: json['type']?.toString() ?? 'container',
      x: _readDouble(frame['x'] ?? json['x'], 0),
      y: _readDouble(frame['y'] ?? json['y'], 0),
      width: _readDouble(frame['width'] ?? json['width'], 120),
      height: _readDouble(frame['height'] ?? json['height'], 44),
      props: props,
      children: (json['children'] as List? ?? <dynamic>[])
          .whereType<Map>()
          .map(
            (childJson) =>
                WidgetNode.fromJson(Map<String, dynamic>.from(childJson)),
          )
          .toList(),
    );
  }

  static double _readDouble(dynamic value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _readBool(dynamic value, bool fallback) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return fallback;
  }

  Map<String, dynamic> _contentProps() {
    return {
      if (props.containsKey('name')) 'name': props['name'],
      if (props.containsKey('text')) 'text': props['text'],
      if (props.containsKey('title')) 'title': props['title'],
      if (props.containsKey('items')) 'items': props['items'],
      if (props.containsKey('columns')) 'columns': props['columns'],
      if (props.containsKey('rows')) 'rows': props['rows'],
      if (props.containsKey('src')) 'src': props['src'],
      if (props.containsKey('placeholder')) 'placeholder': props['placeholder'],
      if (props.containsKey('groupName')) 'groupName': props['groupName'],
      if (props.containsKey('radioValue')) 'radioValue': props['radioValue'],
      if (props.containsKey('fontFamily')) 'fontFamily': props['fontFamily'],
      if (props.containsKey('fontSize')) 'fontSize': props['fontSize'],
      if (props.containsKey('fontWeight')) 'fontWeight': props['fontWeight'],
      if (props.containsKey('textAlign')) 'textAlign': props['textAlign'],
    };
  }

  Map<String, dynamic> _styleProps() {
    return {
      if (props.containsKey('color')) 'color': props['color'],
      if (props.containsKey('backgroundColor'))
        'backgroundColor': props['backgroundColor'],
      if (props.containsKey('foregroundColor'))
        'foregroundColor': props['foregroundColor'],
      if (props.containsKey('borderColor')) 'borderColor': props['borderColor'],
      if (props.containsKey('borderRadius'))
        'borderRadius': props['borderRadius'],
      if (props.containsKey('padding')) 'padding': props['padding'],
    };
  }

  Map<String, dynamic> _layoutProps() {
    return {
      'mode': layoutMode.name,
      if (props.containsKey('gap')) 'gap': props['gap'],
      if (props.containsKey('mainAxisAlignment'))
        'mainAxisAlignment': props['mainAxisAlignment'],
      if (props.containsKey('crossAxisAlignment'))
        'crossAxisAlignment': props['crossAxisAlignment'],
    };
  }

  Map<String, dynamic> _behaviorProps() {
    return {
      'memberName': _safeMemberName(
          props['memberName']?.toString() ?? props['name']?.toString() ?? id),
      'onClick': props['onClick']?.toString() ?? '',
    };
  }

  String _safeMemberName(String value) {
    final compact = value.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    if (compact.isEmpty) {
      return id;
    }
    final startsWithNumber = RegExp(r'^[0-9]').hasMatch(compact);
    return startsWithNumber ? 'control_$compact' : compact;
  }
}
