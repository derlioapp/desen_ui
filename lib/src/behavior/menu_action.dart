import 'package:flutter/widgets.dart';

/// Lends a context menu to the first `DsPressable` below it: that
/// pressable's own node then offers screen readers a way to open the menu
/// (a long press, and a "Show menu" action), as a table row does. The
/// pressable hides the scope from those inside it, so a button in a card
/// does not offer the card's menu.
class DsMenuActionScope extends InheritedWidget {
  /// Lends [onShowMenu] to the first pressable in [child]; null lends none.
  const DsMenuActionScope({
    super.key,
    required this.onShowMenu,
    required super.child,
  });

  /// Opens the menu.
  final VoidCallback? onShowMenu;

  /// The menu lent to the pressable at [context], if any.
  static VoidCallback? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DsMenuActionScope>()
      ?.onShowMenu;

  @override
  bool updateShouldNotify(DsMenuActionScope oldWidget) =>
      onShowMenu != oldWidget.onShowMenu;
}
