import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui_code_builder/editor/canvas_area.dart';
import 'package:gui_code_builder/models/editor_state.dart';
import 'package:gui_code_builder/models/widget_definition.dart';
import 'package:gui_code_builder/renderers/canvas_widget_renderer.dart';

void main() {
  test('label nodes expose editable text properties', () {
    final state = EditorState();
    final node = state.addNode('label');

    expect(node.type, 'label');
    expect(
      definitionFor(node.type).properties.map((property) => property.key),
      contains('text'),
    );

    state.updateNodeProp(node, 'text', 'Edited label');

    expect(node.payload.string('text'), 'Edited label');
  });

  testWidgets('slider previews do not capture editor drag gestures',
      (tester) async {
    final state = EditorState();
    state.addNode('horizontalSlider');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              CanvasArea(
                editorState: state,
                renderer: CanvasWidgetRenderer(),
                onChanged: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);
    final ignorePointerAncestors = tester.widgetList<IgnorePointer>(
      find.ancestor(of: sliderFinder, matching: find.byType(IgnorePointer)),
    );
    expect(ignorePointerAncestors.any((widget) => widget.ignoring), isTrue);
  });
}
