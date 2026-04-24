// 자식 위젯을 배치하는 방식을 표현한다.
enum LayoutMode {
  absolute,
  row,
  column;

  bool get isFlex => this == LayoutMode.row || this == LayoutMode.column;
}
