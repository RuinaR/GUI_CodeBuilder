// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

class PickedTextFile {
  const PickedTextFile({required this.name, required this.text});

  final String name;
  final String text;
}

typedef BrowserJsonDropHandler = Future<void> Function(PickedTextFile file);

StreamSubscription<html.MouseEvent>? _dragOverSubscription;
StreamSubscription<html.MouseEvent>? _dragLeaveSubscription;
StreamSubscription<html.MouseEvent>? _dropSubscription;

bool get supportsBrowserFilePicker => true;

void setBrowserJsonDropHandler(
  BrowserJsonDropHandler? handler, {
  void Function(bool isDragging)? onDraggingChanged,
}) {
  _clearBrowserJsonDropHandler();
  if (handler == null) {
    return;
  }

  _dragOverSubscription = html.document.onDragOver.listen((event) {
    event.preventDefault();
    onDraggingChanged?.call(true);
  });
  _dragLeaveSubscription = html.document.onDragLeave.listen((event) {
    event.preventDefault();
    onDraggingChanged?.call(false);
  });
  _dropSubscription = html.document.onDrop.listen((event) {
    event.preventDefault();
    onDraggingChanged?.call(false);
    final files = event.dataTransfer.files;
    if (files == null || files.isEmpty) {
      return;
    }

    final jsonFiles = files.where((file) {
      return file.name.toLowerCase().endsWith('.json');
    }).toList();
    if (jsonFiles.length != 1) {
      return;
    }

    _readBrowserFile(jsonFiles.single).then(handler);
  });
}

Future<PickedTextFile?> pickJsonFile() {
  final completer = Completer<PickedTextFile?>();
  final input = html.FileUploadInputElement()
    ..accept = '.json,application/json'
    ..style.display = 'none';

  input.onChange.first.then((_) {
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      input.remove();
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onLoad.first.then((_) {
      input.remove();
      completer.complete(
        PickedTextFile(name: file.name, text: reader.result?.toString() ?? ''),
      );
    });
    reader.onError.first.then((_) {
      input.remove();
      completer.completeError(
        FormatException('Could not read ${file.name}.'),
      );
    });
    reader.readAsText(file);
  });

  html.document.body?.append(input);
  input.click();
  return completer.future;
}

void _clearBrowserJsonDropHandler() {
  _dragOverSubscription?.cancel();
  _dragLeaveSubscription?.cancel();
  _dropSubscription?.cancel();
  _dragOverSubscription = null;
  _dragLeaveSubscription = null;
  _dropSubscription = null;
}

Future<PickedTextFile> _readBrowserFile(html.File file) {
  final completer = Completer<PickedTextFile>();
  final reader = html.FileReader();
  reader.onLoad.first.then((_) {
    completer.complete(
      PickedTextFile(name: file.name, text: reader.result?.toString() ?? ''),
    );
  });
  reader.onError.first.then((_) {
    completer.completeError(FormatException('Could not read ${file.name}.'));
  });
  reader.readAsText(file);
  return completer.future;
}

Future<String> readDroppedJsonFile(List<String> paths) {
  throw const FormatException(
    'Browser drops do not expose local file paths. Use Choose JSON File or paste JSON.',
  );
}

String baseName(String path) {
  return path.split('/').last.split('\\').last;
}
