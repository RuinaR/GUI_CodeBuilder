import 'widget_definition_base.dart';
import 'definitions/button_definition.dart';
import 'definitions/check_box_definition.dart';
import 'definitions/column_definition.dart';
import 'definitions/combo_box_definition.dart';
import 'definitions/container_definition.dart';
import 'definitions/double_spin_box_definition.dart';
import 'definitions/group_box_definition.dart';
import 'definitions/horizontal_slider_definition.dart';
import 'definitions/image_widget_definition.dart';
import 'definitions/label_definition.dart';
import 'definitions/line_edit_definition.dart';
import 'definitions/list_box_definition.dart';
import 'definitions/progress_bar_definition.dart';
import 'definitions/radio_button_definition.dart';
import 'definitions/row_definition.dart';
import 'definitions/scroll_area_definition.dart';
import 'definitions/spin_box_definition.dart';
import 'definitions/tab_widget_definition.dart';
import 'definitions/table_definition.dart';
import 'definitions/text_box_definition.dart';
import 'definitions/vertical_slider_definition.dart';

final widgetDefinitions = <WidgetDefinition>[
  const ButtonDefinition(),
  const RadioButtonDefinition(),
  const CheckBoxDefinition(),
  const SpinBoxDefinition(),
  const DoubleSpinBoxDefinition(),
  const LabelDefinition(),
  const ComboBoxDefinition(),
  const TextBoxDefinition(),
  const LineEditDefinition(),
  const ListBoxDefinition(),
  const ProgressBarDefinition(),
  const HorizontalSliderDefinition(),
  const VerticalSliderDefinition(),
  const TableDefinition(),
  const ImageWidgetDefinition(),
  const GroupBoxDefinition(),
  const TabWidgetDefinition(),
  const ScrollAreaDefinition(),
  const ContainerDefinition(),
  const RowDefinition(),
  const ColumnDefinition(),
];

WidgetDefinition definitionFor(String typeId) {
  return widgetDefinitions.firstWhere(
    (definition) => definition.typeId == typeId,
    orElse: () => widgetDefinitions.firstWhere(
      (definition) => definition.typeId == 'container',
    ),
  );
}
