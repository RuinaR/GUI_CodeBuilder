import 'package:flutter_test/flutter_test.dart';
import 'package:gui_code_builder/models/editor_state.dart';

void main() {
  test('loadIrJson rebuilds page state without generating export code', () {
    final state = EditorState();

    state.loadIrJson({
      'page': {
        'className': 'LoadedPage',
        'title': 'Loaded Page',
        'width': 720,
        'height': 480,
      },
      'nodes': [
        {
          'id': 'node_1',
          'type': 'button',
          'frame': {'x': 10, 'y': 20, 'width': 120, 'height': 40},
          'props': {'text': 'Loaded', 'memberName': 'loadedButton'},
          'children': <Map<String, dynamic>>[],
        },
      ],
    });

    expect(state.pageClassName, 'LoadedPage');
    expect(state.pageTitle, 'Loaded Page');
    expect(state.canvasWidth, 720);
    expect(state.canvasHeight, 480);
    expect(state.nodes, hasLength(1));
    expect(state.nodes.single.payload.string('text'), 'Loaded');
    expect(state.exportedCodes, isEmpty);
  });
}
