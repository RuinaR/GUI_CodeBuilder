// 속성 패널이 다형적으로 그릴 수 있는 속성 정의이다.
class WidgetPropertyDefinition {
  const WidgetPropertyDefinition({
    required this.key,
    required this.label,
    required this.kind,
    this.choices = const <String>[],
    this.fallback,
  });

  final String key;
  final String label;
  final WidgetPropertyKind kind;
  final List<String> choices;
  final dynamic fallback;
}

// 속성 편집기의 입력 형태이다.
enum WidgetPropertyKind { text, multilineText, number, boolean, choice }
