import 'dart:io';

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

Future<String> readDroppedJsonFile(List<String> paths) async {
  if (paths.isEmpty) {
    throw const FormatException('Drop a JSON file to load.');
  }
  final jsonFiles = paths.where((path) {
    return path.toLowerCase().endsWith('.json');
  }).toList();
  if (jsonFiles.isEmpty) {
    throw const FormatException('Only .json files can be loaded.');
  }
  if (jsonFiles.length > 1) {
    throw const FormatException('Drop one JSON file at a time.');
  }
  final file = File(jsonFiles.single);
  if (!file.existsSync()) {
    throw const FileSystemException('JSON file does not exist.');
  }
  return file.readAsString();
}

String baseName(String path) {
  return path.split(Platform.pathSeparator).last;
}
