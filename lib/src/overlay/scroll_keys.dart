import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Lets the keyboard scroll a layer's body from anywhere in the layer.
///
/// In a dialog, panel or toast focus sits on a button outside the body
/// that scrolls, so the keys that scroll a page would do nothing there.
/// While the body is longer than its room, Page Up and Page Down scroll it
/// by most of a screen, Arrow Up and Arrow Down by a line, and Home and End
/// to its start and end, whichever control in the layer has focus. A key
/// the focused control handles itself stays with it, and a focused text
/// field keeps all of these keys for its cursor. When the body fits, the
/// keys pass on untouched.
///
/// [builder] gets the controller to give the body's scroll view.
class LayerScrollKeys extends StatefulWidget {
  /// Wraps a layer's content.
  const LayerScrollKeys({super.key, required this.builder});

  /// Builds the layer's content; the body's scroll view takes the
  /// controller.
  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  @override
  State<LayerScrollKeys> createState() => _LayerScrollKeysState();
}

class _LayerScrollKeysState extends State<LayerScrollKeys> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_controller.hasClients) return KeyEventResult.ignored;
    final position = _controller.position;
    if (!position.hasContentDimensions ||
        position.maxScrollExtent <= position.minScrollExtent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    // A text field moves its cursor with these keys.
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null ||
        focused.widget is EditableText ||
        focused.findAncestorStateOfType<EditableTextState>() != null) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.end) {
      position.jumpTo(
        key == LogicalKeyboardKey.home
            ? position.minScrollExtent
            : position.maxScrollExtent,
      );
      return KeyEventResult.handled;
    }
    final intent = switch (key) {
      LogicalKeyboardKey.pageUp => const ScrollIntent(
        direction: AxisDirection.up,
        type: ScrollIncrementType.page,
      ),
      LogicalKeyboardKey.pageDown => const ScrollIntent(
        direction: AxisDirection.down,
        type: ScrollIncrementType.page,
      ),
      LogicalKeyboardKey.arrowUp => const ScrollIntent(
        direction: AxisDirection.up,
      ),
      LogicalKeyboardKey.arrowDown => const ScrollIntent(
        direction: AxisDirection.down,
      ),
      _ => null,
    };
    final scrollable = position.context.notificationContext;
    if (intent == null || scrollable == null) return KeyEventResult.ignored;
    ScrollAction().invoke(intent, scrollable);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    includeSemantics: false,
    onKeyEvent: _onKey,
    child: widget.builder(context, _controller),
  );
}
