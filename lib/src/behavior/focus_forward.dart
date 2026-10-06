import 'package:flutter/widgets.dart';

/// The focus node of a widget made of several focus stops (a bar of
/// buttons, a table's rows): not a stop itself, it has focus while any
/// stop inside does, and focusing it moves focus on to the stop the widget
/// picks in [onFocused]. [autofocus] does the same when first built.
///
/// Library-internal: it gives such widgets the `focusNode` and `autofocus`
/// every interactive widget takes.
class FocusForward extends StatefulWidget {
  /// Forwards focus on [focusNode] (one is created when null) to a stop
  /// inside [child].
  const FocusForward({
    super.key,
    required this.focusNode,
    required this.autofocus,
    this.onFocused,
    required this.child,
  });

  /// The node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Moves focus to the stop that stands for the widget, e.g. its selected
  /// item. Called when the node itself becomes the primary focus. Null
  /// focuses the first stop inside.
  final VoidCallback? onFocused;

  /// The stops.
  final Widget child;

  @override
  State<FocusForward> createState() => _FocusForwardState();
}

class _FocusForwardState extends State<FocusForward> {
  FocusNode? _own;
  FocusNode get _node =>
      widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'FocusForward'));

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(FocusForward oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _own)?.removeListener(_onFocus);
      if (widget.focusNode != null) {
        _own?.dispose();
        _own = null;
      }
      _node.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _own?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_node.hasPrimaryFocus) return;
    final onFocused = widget.onFocused;
    if (onFocused != null) {
      onFocused();
    } else {
      _node.traversalDescendants.firstOrNull?.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _node,
    autofocus: widget.autofocus,
    // Not a stop of its own: Tab moves between the stops inside.
    skipTraversal: true,
    includeSemantics: false,
    child: widget.child,
  );
}
