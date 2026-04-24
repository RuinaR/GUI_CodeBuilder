class SnapshotHistory {
  SnapshotHistory({this.limit = 80});

  final int limit;
  final List<Map<String, dynamic>> _undoStack = <Map<String, dynamic>>[];

  bool get canUndo => _undoStack.isNotEmpty;

  void push(Map<String, dynamic> snapshot) {
    _undoStack.add(snapshot);
    if (_undoStack.length > limit) {
      _undoStack.removeAt(0);
    }
  }

  Map<String, dynamic>? pop() {
    if (_undoStack.isEmpty) {
      return null;
    }
    return _undoStack.removeLast();
  }

  void clear() {
    _undoStack.clear();
  }
}
