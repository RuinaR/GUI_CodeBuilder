class PickedTextFile {
  const PickedTextFile({required this.name, required this.text});

  final String name;
  final String text;
}

typedef BrowserJsonDropHandler = Future<void> Function(PickedTextFile file);

bool get supportsBrowserFilePicker => false;

void setBrowserJsonDropHandler(
  BrowserJsonDropHandler? handler, {
  void Function(bool isDragging)? onDraggingChanged,
}) {}

Future<PickedTextFile?> pickJsonFile() async {
  return null;
}

Future<String> readDroppedJsonFile(List<String> paths) {
  throw UnsupportedError('File loading is not supported on this platform.');
}

String baseName(String path) {
  return path;
}
