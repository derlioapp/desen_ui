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

  /// The type these defaults are looked up by: [T].
  Type get _type => T;

  /// These defaults laid over [outer], defaults of the same type.
  ///
  /// [outer] is typed `Object?`: the compiler reads
  /// `DsComponentThemeData<dynamic>` inside this F-bounded class as
  /// `DsComponentThemeData<DsComponentThemeData<dynamic>>`.
  DsComponentThemeData<T> _over(Object? outer) =>
      outer == null ? this : (outer as T).merge(this as T);
}

/// Applies component defaults ([data]) to a subtree.
///
/// Nested themes of the same type merge: an inner theme overrides only what
/// it sets. Put one above the app for global defaults, or around a section
/// to change only that section.
///
/// Component themes are inherited themes (`InheritedTheme`): a route or
/// overlay that captures the opener's themes, Flutter's own dialogs
/// included, carries them into its layer.
class DsComponentTheme<T extends DsComponentThemeData<T>>
    extends StatelessWidget {
  /// Applies [data] to [child], merged over any outer theme of type [T].
  const DsComponentTheme({super.key, required this.data, required this.child});

  /// The defaults.
  final T data;

  /// The subtree.
  final Widget child;

  /// The merged defaults of type [T] for [context], or null.
  ///
  /// Rebuilds the caller only when the defaults of type [T] change.
  static T? maybeOf<T extends DsComponentThemeData<T>>(BuildContext context) =>
      InheritedModel.inheritFrom<_ComponentThemeScope>(
            context,
            aspect: T,
          )?.themes[T]
          as T?;

  @override
  Widget build(BuildContext context) =>
      _ComponentThemeScope.over(context, [data], child);
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
///
/// Each theme merges over an outer theme of its type, like a
/// [DsComponentTheme]; a later theme of the same type in [themes] merges
/// over an earlier one. Adding, removing or reordering themes keeps the
/// state of [child]: the subtree's structure does not depend on the list.
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
  Widget build(BuildContext context) =>
      _ComponentThemeScope.over(context, themes, child);
}

/// Every component theme in effect, merged and keyed by type. A dependent
/// depends on one type (its aspect) and rebuilds only when that one
/// changes.
class _ComponentThemeScope extends InheritedModel<Type>
    implements InheritedTheme {
  const _ComponentThemeScope({required this.themes, required super.child});

  /// The outer scope's themes with [themes] merged over them, around
  /// [child].
  static Widget over(
    BuildContext context,
    Iterable<DsComponentThemeData<dynamic>> themes,
    Widget child,
  ) {
    final outer = context
        .dependOnInheritedWidgetOfExactType<_ComponentThemeScope>()
        ?.themes;
    final merged = <Type, Object>{...?outer};
    for (final theme in themes) {
      merged[theme._type] = theme._over(merged[theme._type]);
    }
    return _ComponentThemeScope(themes: merged, child: child);
  }

  final Map<Type, Object> themes;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      _ComponentThemeScope(themes: themes, child: child);

  @override
  bool updateShouldNotify(_ComponentThemeScope oldWidget) =>
      !mapEquals(themes, oldWidget.themes);

  @override
  bool updateShouldNotifyDependent(
    _ComponentThemeScope oldWidget,
    Set<Type> dependencies,
  ) => dependencies.any((type) => themes[type] != oldWidget.themes[type]);
}
