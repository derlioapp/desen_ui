/// Internal: the field-and-button frame shared by the date and time
/// pickers. Not exported from the package.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../text_field/field_fit.dart';

/// Lays a picker's button at the end of its text field, inside the well,
/// as the text field lays its own clear and show-password buttons:
/// the button is drawn at its own small size, its tap area overflows it,
/// and the field does not grow. The button stays a separate semantics node
/// inside a `DsField`. When the field is too narrow, the button
/// gives way after the error icon and the trailing slot, as a number
/// field's step buttons do; Alt+Down and typing still work.
class PickerFieldFrame extends StatelessWidget {
  /// Creates the frame.
  const PickerFieldFrame({
    super.key,
    required this.field,
    required this.button,
    required this.buttonVisual,
  });

  /// The text field.
  final Widget field;

  /// The button, drawn at [buttonVisual].
  final Widget button;

  /// The button's drawn width and height.
  final double buttonVisual;

  /// [child], a button that opens a popup, read as expanded while the
  /// popup is open (WAI-ARIA `aria-expanded`). The flag is merged into the
  /// button's own node, so it stays one node.
  static Widget expandedButton({
    required bool expanded,
    required Widget child,
  }) => MergeSemantics(
    child: Semantics(expanded: expanded, child: child),
  );

  @override
  Widget build(BuildContext context) =>
      FieldEndAction(button: button, visual: buttonVisual, child: field);
}

/// Whether [event] is Alt+Down (or Option+Down), the platform key for
/// opening a field's popup.
bool isOpenPopupKey(KeyEvent event) =>
    event is KeyDownEvent &&
    event.logicalKey == LogicalKeyboardKey.arrowDown &&
    HardwareKeyboard.instance.isAltPressed;
