import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../exporters/code_exporter.dart';
import '../exporters/flet_code_exporter.dart';
import '../exporters/flutter_code_exporter.dart';
import '../exporters/html_css_exporter.dart';
import '../exporters/pyqt_code_exporter.dart';
import '../models/editor_state.dart';
import '../models/export_format.dart';
import '../renderers/canvas_widget_renderer.dart';
import '../services/json_document_service.dart';
import '../services/platform_file_access.dart' as file_access;
import 'canvas_area.dart';
import 'property_panel.dart';
import 'resize_handle.dart';
import 'widget_palette.dart';
import 'widget_tree_panel.dart';

// 편집 화면 전체를 조립하고 사용자 명령을 상태 객체로 전달한다.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  static const MethodChannel _fileDropChannel = MethodChannel(
    'gui_code_builder/file_drop',
  );

  final EditorState _editorState = EditorState();
  final CanvasWidgetRenderer _renderer = CanvasWidgetRenderer();
  final JsonDocumentService _jsonService = JsonDocumentService();
  final List<CodeExporter> _exporters = [
    FlutterCodeExporter(),
    FletCodeExporter(),
    PyQtCodeExporter(),
    HtmlCssExporter(),
  ];

  ExportFormat _previewFormat = ExportFormat.flutter;
  double _leftPaneWidth = 320;
  double _rightPaneWidth = 340;
  double _exportPreviewHeight = 190;
  double _treePaneHeight = 320;
  void Function(List<String> paths)? _activeJsonDropHandler;

  @override
  void initState() {
    super.initState();
    _fileDropChannel.setMethodCallHandler(_handleFileDropMethodCall);
  }

  @override
  void dispose() {
    _fileDropChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _handleFileDropMethodCall(MethodCall call) async {
    if (call.method != 'filesDropped') {
      return;
    }
    final paths = (call.arguments as List? ?? <dynamic>[])
        .whereType<String>()
        .toList(growable: false);
    final handler = _activeJsonDropHandler;
    if (handler != null) {
      handler(paths);
      return;
    }
    if (paths.any((path) => path.toLowerCase().endsWith('.json')) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Press Load JSON, then drop the file.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            _buildToolbar(),
            Expanded(child: _buildEditorWorkspace()),
            if (_editorState.exportedJson.isNotEmpty ||
                _editorState.exportedCodes.isNotEmpty)
              ResizeHandle(
                axis: Axis.vertical,
                onDrag: (delta) {
                  setState(() {
                    _exportPreviewHeight =
                        (_exportPreviewHeight - delta.dy).clamp(120, 420);
                  });
                },
              ),
            _buildExportPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxLeft = (constraints.maxWidth - _rightPaneWidth - 260).clamp(
          220,
          520,
        );
        final maxRight = (constraints.maxWidth - _leftPaneWidth - 260).clamp(
          260,
          560,
        );
        _leftPaneWidth = _leftPaneWidth.clamp(240, maxLeft.toDouble());
        _rightPaneWidth = _rightPaneWidth.clamp(280, maxRight.toDouble());

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: _leftPaneWidth, child: _buildLeftPane()),
            ResizeHandle(
              axis: Axis.horizontal,
              onDrag: (delta) {
                setState(() {
                  _leftPaneWidth = (_leftPaneWidth + delta.dx).clamp(240, 520);
                });
              },
            ),
            CanvasArea(
              editorState: _editorState,
              renderer: _renderer,
              onChanged: _refresh,
            ),
            ResizeHandle(
              axis: Axis.horizontal,
              onDrag: (delta) {
                setState(() {
                  _rightPaneWidth = (_rightPaneWidth - delta.dx).clamp(
                    280,
                    560,
                  );
                });
              },
            ),
            PropertyPanel(
              editorState: _editorState,
              onChanged: _refresh,
              width: _rightPaneWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeftPane() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _treePaneHeight = _treePaneHeight.clamp(
          180,
          constraints.maxHeight - 180,
        );
        return Column(
          children: [
            Expanded(child: WidgetPalette(onAddNode: _addNode)),
            ResizeHandle(
              axis: Axis.vertical,
              onDrag: (delta) {
                setState(() {
                  _treePaneHeight = (_treePaneHeight - delta.dy).clamp(
                    180,
                    constraints.maxHeight - 180,
                  );
                });
              },
            ),
            SizedBox(
              height: _treePaneHeight,
              child: WidgetTreePanel(
                editorState: _editorState,
                onChanged: _refresh,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 58,
      color: const Color(0xFF111827),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Text(
            'GUI Code Builder',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          _toolbarButton('Export', _exportDocument),
          _toolbarButton('Load JSON', _showLoadJsonDialog),
          _toolbarButton('Duplicate', _duplicateSelected),
          _toolbarButton('Delete', _deleteSelected),
          _toolbarButton('Back', _undo),
          const SizedBox(width: 10),
          _alignButton('L', 'left'),
          _alignButton('T', 'top'),
          _alignButton('R', 'right'),
          _alignButton('B', 'bottom'),
          const Spacer(),
          Row(
            children: [
              const Text('Snap', style: TextStyle(color: Colors.white)),
              Switch(
                value: _editorState.snapEnabled,
                onChanged: (value) {
                  setState(() => _editorState.snapEnabled = value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton.tonal(onPressed: onPressed, child: Text(label)),
    );
  }

  Widget _alignButton(String label, String mode) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: SizedBox(
        width: 36,
        height: 36,
        child: FilledButton.tonal(
          onPressed: _editorState.selectedIds.length < 2
              ? null
              : () {
                  _editorState.alignSelected(mode);
                  _refresh();
                },
          style: FilledButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildExportPreview() {
    if (_editorState.exportedJson.isEmpty &&
        _editorState.exportedCodes.isEmpty) {
      return const SizedBox.shrink();
    }

    final code = _editorState.exportedCodes[_previewFormat.name] ?? '';
    return SizedBox(
      height: _exportPreviewHeight,
      child: Row(
        children: [
          Expanded(child: _previewText('JSON IR', _editorState.exportedJson)),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<ExportFormat>(
                    segments: [
                      for (final format in ExportFormat.values)
                        ButtonSegment(value: format, label: Text(format.label)),
                    ],
                    selected: {_previewFormat},
                    onSelectionChanged: (values) {
                      setState(() => _previewFormat = values.first);
                    },
                  ),
                ),
                Expanded(child: _previewText(_previewFormat.label, code)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewText(String title, String text) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                text,
                style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _undo() {
    if (_editorState.undo()) {
      _refresh();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      _deleteSelected();
      return;
    }
    final isUndo = event.logicalKey == LogicalKeyboardKey.keyZ &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed);
    if (isUndo) {
      _undo();
    }
  }

  void _addNode(String type) {
    _editorState.addNode(type);
    _refresh();
  }

  void _duplicateSelected() {
    _editorState.duplicateSelected();
    _refresh();
  }

  void _deleteSelected() {
    _editorState.deleteSelected();
    _refresh();
  }

  Future<void> _exportDocument() async {
    final irJson = _editorState.toIrJson();
    final jsonText = _jsonService.encodePretty(irJson);
    final generatedFiles = {
      for (final exporter in _exporters)
        exporter.format: exporter.exportFiles(irJson),
    };
    final generatedCodes = {
      for (final exporter in _exporters)
        exporter.format: generatedFiles[exporter.format]!.values.first,
    };
    await _jsonService.saveExportFiles(
      jsonText: jsonText,
      generatedFiles: generatedFiles,
    );
    setState(() {
      _editorState.exportedJson = jsonText;
      _editorState.exportedCodes
        ..clear()
        ..addEntries(
          generatedCodes.entries.map(
            (entry) => MapEntry(entry.key.name, entry.value),
          ),
        );
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            file_access.supportsBrowserFilePicker
                ? 'Export files downloaded.'
                : 'Export files saved to exports.',
          ),
        ),
      );
    }
  }

  Future<void> _loadJsonText(String jsonText) async {
    final trimmed = jsonText.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('JSON content is empty.');
    }
    final document = _jsonService.decode(trimmed);
    setState(() {
      _editorState.loadIrJson(document);
      _editorState.exportedJson = _jsonService.encodePretty(document);
      _editorState.exportedCodes.clear();
      _previewFormat = ExportFormat.flutter;
    });
  }

  Future<String> _readDroppedJsonFile(List<String> paths) async {
    return file_access.readDroppedJsonFile(paths);
  }

  void _showLoadJsonDialog() {
    final controller = TextEditingController(text: _editorState.exportedJson);
    showDialog<void>(
      context: context,
      builder: (context) {
        var isDragging = false;
        var isLoading = false;
        String? errorText;
        String? loadedFileName;
        var browserDropHandlerInstalled = false;

        Future<bool> loadText(
          String jsonText,
          StateSetter setDialogState,
        ) async {
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(this.context);
          setDialogState(() {
            isLoading = true;
            errorText = null;
          });
          try {
            await _loadJsonText(jsonText);
            setDialogState(() => isLoading = false);
            if (mounted) {
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content:
                      Text('JSON loaded. Press Export when you need files.'),
                ),
              );
            }
            return true;
          } on FormatException catch (error) {
            setDialogState(() {
              errorText = error.message;
              isLoading = false;
            });
            return false;
          } on Exception catch (error) {
            setDialogState(() {
              errorText = error.toString();
              isLoading = false;
            });
            return false;
          }
        }

        Future<void> loadDroppedFiles(
          List<String> paths,
          StateSetter setDialogState,
        ) async {
          setDialogState(() {
            isLoading = true;
            errorText = null;
            loadedFileName = null;
          });
          try {
            final jsonFiles = paths
                .where((path) => path.toLowerCase().endsWith('.json'))
                .toList();
            final jsonText = await _readDroppedJsonFile(paths);
            loadedFileName = file_access.baseName(jsonFiles.single);
            controller.text = jsonText;
            final didLoad = await loadText(jsonText, setDialogState);
            if (didLoad) {
              return;
            }
          } on FormatException catch (error) {
            setDialogState(() => errorText = error.message);
          } on Exception catch (error) {
            setDialogState(() => errorText = error.toString());
          }
          setDialogState(() {
            isDragging = false;
            isLoading = false;
          });
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            _activeJsonDropHandler = (paths) {
              loadDroppedFiles(paths, setDialogState);
            };
            if (file_access.supportsBrowserFilePicker &&
                !browserDropHandlerInstalled) {
              browserDropHandlerInstalled = true;
              file_access.setBrowserJsonDropHandler(
                (picked) async {
                  setDialogState(() {
                    isLoading = true;
                    errorText = null;
                    loadedFileName = picked.name;
                    controller.text = picked.text;
                  });
                  await loadText(picked.text, setDialogState);
                },
                onDraggingChanged: (value) {
                  setDialogState(() => isDragging = value);
                },
              );
            }
            final borderColor = errorText != null
                ? const Color(0xFFDC2626)
                : isDragging
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFCBD5E1);
            return AlertDialog(
              title: const Text('Load JSON IR'),
              content: SizedBox(
                width: 760,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDragging
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF8FAFC),
                        border: Border.all(color: borderColor, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isLoading
                                ? 'Loading JSON...'
                                : 'Drop a page_ir.json file here',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loadedFileName == null
                                ? 'The page is rebuilt from JSON. Export is not run automatically.'
                                : loadedFileName!,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (file_access.supportsBrowserFilePicker) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isLoading = true;
                                    errorText = null;
                                    loadedFileName = null;
                                  });
                                  try {
                                    final picked =
                                        await file_access.pickJsonFile();
                                    if (picked == null) {
                                      setDialogState(() {
                                        isLoading = false;
                                      });
                                      return;
                                    }
                                    loadedFileName = picked.name;
                                    controller.text = picked.text;
                                    final didLoad = await loadText(
                                      picked.text,
                                      setDialogState,
                                    );
                                    if (didLoad) {
                                      return;
                                    }
                                  } on FormatException catch (error) {
                                    setDialogState(() {
                                      errorText = error.message;
                                      isLoading = false;
                                    });
                                  } on Exception catch (error) {
                                    setDialogState(() {
                                      errorText = error.toString();
                                      isLoading = false;
                                    });
                                  }
                                },
                          child: const Text('Choose JSON File'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      minLines: 12,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Or paste JSON IR here',
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorText!,
                          style: const TextStyle(color: Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () => loadText(controller.text, setDialogState),
                  child: const Text('Load'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      _activeJsonDropHandler = null;
      file_access.setBrowserJsonDropHandler(null);
    });
  }

  void _refresh() {
    setState(() {});
  }
}
