import 'dart:async';

import 'package:flutter/widgets.dart';

/// Moves focus from a layer's [scope] to the first control inside it in Tab
/// order, when the scope itself holds focus because nothing inside asked
/// for it (no `autofocus`). A layer that opens with focus on its container
/// leaves keyboard users with no visible focus until they press Tab, and
/// screen readers on the trigger behind it (WAI-ARIA dialog pattern). With
/// no control inside, focus stays on the scope, where Escape still lands.
///
/// Call it once the scope's own focus request has been applied (focus
/// changes apply in a microtask).
void focusFirstControl(FocusScopeNode scope) {
  if (!scope.hasPrimaryFocus) return;
  final policy =
      FocusTraversalGroup.maybeOfNode(scope) ?? ReadingOrderTraversalPolicy();
  final first = policy.findFirstFocus(scope, ignoreCurrentFocus: true);
  if (first != null && first != scope) first.requestFocus();
}

/// Runs [focusFirstControl] on the enclosing focus scope (a modal route's)
/// once, after the first frame, when the route's own focus and any
/// `autofocus` inside have been applied.
class FocusFirstOnOpen extends StatefulWidget {
  /// Wraps a layer's content.
  const FocusFirstOnOpen({super.key, required this.child});

  /// The layer's content.
  final Widget child;

  @override
  State<FocusFirstOnOpen> createState() => _FocusFirstOnOpenState();
}

class _FocusFirstOnOpenState extends State<FocusFirstOnOpen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The route's focus request and any autofocus from this first build
      // apply in a microtask already queued; this one runs after them.
      scheduleMicrotask(() {
        if (!mounted) return;
        focusFirstControl(FocusScope.of(context, createDependency: false));
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
