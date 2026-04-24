import 'layout_mode.dart';
import 'widget_definition.dart';

enum WidgetType {
  button('button'),
  radioButton('radioButton'),
  checkBox('checkBox'),
  spinBox('spinBox'),
  doubleSpinBox('doubleSpinBox'),
  label('label'),
  comboBox('comboBox'),
  textBox('textBox'),
  lineEdit('lineEdit'),
  listBox('listBox'),
  progressBar('progressBar'),
  horizontalSlider('horizontalSlider'),
  verticalSlider('verticalSlider'),
  table('table'),
  image('image'),
  groupBox('groupBox'),
  tabs('tabs'),
  scrollArea('scrollArea'),
  container('container'),
  row('row'),
  column('column');

  const WidgetType(this.id);

  final String id;

  static WidgetType fromId(String? id) {
    if (id == 'text') {
      return label;
    }
    for (final type in values) {
      if (type.id == id) {
        return type;
      }
    }
    return container;
  }
}

class NodeFrame {
  const NodeFrame({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.responsive = true,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final bool responsive;

  NodeFrame copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    bool? responsive,
  }) {
    return NodeFrame(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      responsive: responsive ?? this.responsive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'responsive': responsive,
    };
  }

  static NodeFrame fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> payload,
  ) {
    final frame = Map<String, dynamic>.from(
      json['frame'] as Map? ?? <String, dynamic>{},
    );
    return NodeFrame(
      x: readDouble(frame['x'] ?? json['x'], 0),
      y: readDouble(frame['y'] ?? json['y'], 0),
      width: readDouble(frame['width'] ?? json['width'], 120),
      height: readDouble(frame['height'] ?? json['height'], 44),
      responsive: readBool(
        frame['responsive'] ?? json['responsive'] ?? payload['responsive'],
        true,
      ),
    );
  }
}

class NodeStyle {
  const NodeStyle({
    this.color,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
  });

  final String? color;
  final String? backgroundColor;
  final String? foregroundColor;
  final String? borderColor;
  final double? borderRadius;
  final double? padding;

  Map<String, dynamic> toJson() {
    return {
      if (color != null) 'color': color,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (foregroundColor != null) 'foregroundColor': foregroundColor,
      if (borderColor != null) 'borderColor': borderColor,
      if (borderRadius != null) 'borderRadius': borderRadius,
      if (padding != null) 'padding': padding,
    };
  }
}

class NodeBehavior {
  const NodeBehavior({required this.memberName, this.onClick = ''});

  final String memberName;
  final String onClick;

  Map<String, dynamic> toJson() {
    return {
      'memberName': memberName,
      'onClick': onClick,
    };
  }
}

class WidgetPayload {
  WidgetPayload(Map<String, dynamic>? values)
      : values = Map<String, dynamic>.from(values ?? <String, dynamic>{});

  final Map<String, dynamic> values;

  dynamic operator [](String key) => values[key];

  void operator []=(String key, dynamic value) {
    values[key] = value;
  }

  bool containsKey(String key) => values.containsKey(key);

  String string(String key, {String fallback = ''}) {
    final value = values[key];
    return value == null ? fallback : value.toString();
  }

  double number(String key, {double fallback = 0}) {
    return readDouble(values[key], fallback);
  }

  bool boolean(String key, {bool fallback = false}) {
    return readBool(values[key], fallback);
  }

  List<String> csv(String key) {
    return string(key)
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(values);

  Map<String, dynamic> contentJson() {
    return _only(const {
      'name',
      'text',
      'title',
      'items',
      'columns',
      'rows',
      'src',
      'placeholder',
      'groupName',
      'radioValue',
      'fontFamily',
      'fontSize',
      'fontWeight',
      'textAlign',
    });
  }

  NodeStyle toStyle() {
    return NodeStyle(
      color: _optionalString('color'),
      backgroundColor: _optionalString('backgroundColor'),
      foregroundColor: _optionalString('foregroundColor'),
      borderColor: _optionalString('borderColor'),
      borderRadius: containsKey('borderRadius') ? number('borderRadius') : null,
      padding: containsKey('padding') ? number('padding') : null,
    );
  }

  Map<String, dynamic> layoutJson(LayoutMode mode) {
    return {
      'mode': mode.name,
      ..._only(const {
        'gap',
        'mainAxisAlignment',
        'crossAxisAlignment',
      }),
    };
  }

  NodeBehavior behavior(String fallbackMemberName) {
    return NodeBehavior(
      memberName: _safeMemberName(
        string(
          'memberName',
          fallback: string('name', fallback: fallbackMemberName),
        ),
        fallbackMemberName,
      ),
      onClick: string('onClick'),
    );
  }

  Map<String, dynamic> _only(Set<String> keys) {
    return {
      for (final key in keys)
        if (containsKey(key)) key: values[key],
    };
  }

  String? _optionalString(String key) {
    if (!containsKey(key)) {
      return null;
    }
    return string(key);
  }
}

class WidgetNode {
  WidgetNode({
    required this.id,
    required String type,
    required double x,
    required double y,
    required double width,
    required double height,
    Map<String, dynamic>? props,
    List<WidgetNode>? children,
  })  : widgetType = WidgetType.fromId(type),
        frame = NodeFrame(
          x: x,
          y: y,
          width: width,
          height: height,
          responsive: readBool(props?['responsive'], true),
        ),
        payload = WidgetPayload(props),
        children = children ?? <WidgetNode>[];

  WidgetNode._({
    required this.id,
    required this.widgetType,
    required this.frame,
    required this.payload,
    required this.children,
  });

  final String id;
  WidgetType widgetType;
  NodeFrame frame;
  WidgetPayload payload;
  List<WidgetNode> children;

  String get type => widgetType.id;

  set type(String value) {
    widgetType = WidgetType.fromId(value);
  }

  double get x => frame.x;

  set x(double value) {
    frame = frame.copyWith(x: value);
  }

  double get y => frame.y;

  set y(double value) {
    frame = frame.copyWith(y: value);
  }

  double get width => frame.width;

  set width(double value) {
    frame = frame.copyWith(width: value);
  }

  double get height => frame.height;

  set height(double value) {
    frame = frame.copyWith(height: value);
  }

  Map<String, dynamic> get props => payload.values;

  set props(Map<String, dynamic> value) {
    payload = WidgetPayload(value);
    frame = frame.copyWith(
        responsive: payload.boolean('responsive', fallback: true));
  }

  String get displayName {
    final name = payload.string('name');
    return name.isNotEmpty ? name : '$type($id)';
  }

  bool get isButton => widgetType == WidgetType.button;
  bool get isRadioButton => widgetType == WidgetType.radioButton;
  bool get isCheckBox => widgetType == WidgetType.checkBox;
  bool get isSlider =>
      widgetType == WidgetType.horizontalSlider ||
      widgetType == WidgetType.verticalSlider;

  bool get canHaveChildren {
    return definitionFor(type).canHaveChildren;
  }

  LayoutMode get layoutMode {
    return definitionFor(type).layoutMode;
  }

  bool get responsive => frame.responsive;

  set responsive(bool value) {
    frame = frame.copyWith(responsive: value);
    payload['responsive'] = value;
  }

  WidgetNode cloneWithNewIds(String Function() createId, {double offset = 16}) {
    final newNode = WidgetNode(
      id: createId(),
      type: type,
      x: x + offset,
      y: y + offset,
      width: width,
      height: height,
      props: payload.toJson(),
      children: <WidgetNode>[],
    );
    newNode.payload['name'] = newNode.id;
    newNode.payload['memberName'] = newNode.id;
    newNode.children = children
        .map((child) => child.cloneWithNewIds(createId, offset: offset))
        .toList();
    return newNode;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'role': canHaveChildren ? 'layout' : 'control',
      'frame': frame.toJson(),
      'content': payload.contentJson(),
      'style': payload.toStyle().toJson(),
      'layout': payload.layoutJson(layoutMode),
      'behavior': payload.behavior(id).toJson(),
      'props': payload.toJson(),
      'children': children.map((child) => child.toJson()).toList(),
    };
  }

  Map<String, dynamic> toLegacyJson() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'props': payload.toJson(),
      'children': children.map((child) => child.toJson()).toList(),
    };
  }

  factory WidgetNode.fromJson(Map<String, dynamic> json) {
    final payload = <String, dynamic>{};
    payload.addAll(Map<String, dynamic>.from(json['props'] as Map? ?? {}));
    payload.addAll(Map<String, dynamic>.from(json['content'] as Map? ?? {}));
    payload.addAll(Map<String, dynamic>.from(json['style'] as Map? ?? {}));
    payload.addAll(Map<String, dynamic>.from(json['layout'] as Map? ?? {}));
    payload.addAll(Map<String, dynamic>.from(json['behavior'] as Map? ?? {}));

    return WidgetNode._(
      id: json['id']?.toString() ?? 'node_0',
      widgetType: WidgetType.fromId(json['type']?.toString()),
      frame: NodeFrame.fromJson(json, payload),
      payload: WidgetPayload(payload),
      children: (json['children'] as List? ?? <dynamic>[])
          .whereType<Map>()
          .map(
            (childJson) =>
                WidgetNode.fromJson(Map<String, dynamic>.from(childJson)),
          )
          .toList(),
    );
  }
}

double readDouble(dynamic value, double fallback) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool readBool(dynamic value, bool fallback) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return fallback;
}

String _safeMemberName(String value, String fallback) {
  final compact = value.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  if (compact.isEmpty) {
    return fallback;
  }
  return RegExp(r'^[0-9]').hasMatch(compact) ? 'control_$compact' : compact;
}
