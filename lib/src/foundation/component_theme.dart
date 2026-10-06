import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Component defaults that can be scoped to a subtree with
/// [DsComponentTheme], the one customization model every component
/// shares.
@immutable
abstract class DsComponentThemeData<T extends DsComponentThemeData<T>>
    with Diagnosticable {
  /// Const constructor for subclasses.
  const DsComponentThemeData();

  /// Lays [other] over this: values set in [other] win, unset ones fall
  /// through.
  T merge(T? other);

  /// Wraps [child] so these defaults apply to it.
  Widget wrap(Widget child) =>
      DsComponentTheme<T>(data: this as T, child: child);
}

/// Applies component defaults ([data]) to a subtree.
///
/// Nested themes of the same type merge: an inner theme overrides only what
/// it sets. Put one above the app for global defaults, or around a section
/// to change only that section.
class DsComponentTheme<T extends DsComponentThemeData<T>>
    extends StatelessWidget {
  /// Applies [data] to [child], merged over any outer theme of type [T].
  const DsComponentTheme({super.key, required this.data, required this.child});

  /// The defaults.
  final T data;

  /// The subtree.
  final Widget child;

  /// The merged defaults of type [T] for [context], or null.
  static T? maybeOf<T extends DsComponentThemeData<T>>(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_InheritedComponentTheme<T>>()
          ?.data;

  @override
  Widget build(BuildContext context) => _InheritedComponentTheme<T>(
    data: maybeOf<T>(context)?.merge(data) ?? data,
    child: child,
  );
}

class _InheritedComponentTheme<T extends DsComponentThemeData<T>>
    extends InheritedWidget {
  const _InheritedComponentTheme({required this.data, required super.child});

  final T data;

  @override
  bool updateShouldNotify(_InheritedComponentTheme<T> old) => data != old.data;
}

/// Applies several component themes at once.
///
/// ```dart
/// DsComponentThemes(
///   themes: const [
///     DsButtonThemeData(size: .sm),
///     DsChipThemeData(style: DsChipStyle(height: 28)),
///   ],
///   child: app,
/// )
/// ```
class DsComponentThemes extends StatelessWidget {
  /// Applies every theme in [themes] to [child].
  const DsComponentThemes({
    super.key,
    required this.themes,
    required this.child,
  });

  /// The component defaults, each of a different type.
  final List<DsComponentThemeData<dynamic>> themes;

  /// The subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var result = child;
    for (final t in themes.reversed) {
      result = t.wrap(result);
    }
    return result;
  }
}
