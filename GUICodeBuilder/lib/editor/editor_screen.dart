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
                  _rightPaneWidth =
                      (_rightPaneWidth - delta.dx).clamp(280, 560);
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
        _treePaneHeight =
            _treePaneHeight.clamp(180, constraints.maxHeight - 180);
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
                        ButtonSegment(
                          value: format,
                          label: Text(format.label),
                        ),
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
        exporter.format:
            generatedFiles[exporter.format]![exporter.format.fileName]!,
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
  }

  void _showLoadJsonDialog() {
    final controller = TextEditingController(text: _editorState.exportedJson);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Load JSON IR'),
          content: SizedBox(
            width: 720,
            child: TextField(
              controller: controller,
              minLines: 14,
              maxLines: 14,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final document = _jsonService.decode(controller.text);
                setState(() {
                  _editorState.loadIrJson(document);
                  _editorState.exportedJson = controller.text;
                  _editorState.exportedCodes
                    ..clear()
                    ..addEntries(
                      _exporters.map(
                        (exporter) => MapEntry(
                          exporter.format.name,
                          exporter.exportPage(document),
                        ),
                      ),
                    );
                });
                Navigator.of(context).pop();
              },
              child: const Text('Load'),
            ),
          ],
        );
      },
    );
  }

  void _refresh() {
    setState(() {});
  }
}
