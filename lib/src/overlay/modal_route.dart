import 'package:flutter/widgets.dart';

import '../foundation/component_theme.dart';
import '../l10n/localizations.dart';
import '../theme/motion.dart';
import '../theme/sizes.dart';
import '../theme/theme.dart';
import '../theme/theme_data.dart';

/// The Desen context an opener has and a layer shown elsewhere in the tree
/// would miss: the [DsTheme], [Directionality], [DsLocalizationScope] and
/// component themes ([DsComponentTheme]) that sit between the opener and
/// the layer's host (a [Navigator] or an [Overlay]).
///
/// Anything above the host the layer inherits as usual. What sits between
/// the opener and the host is linked, not copied: the layer follows it
/// live, so a theme switch reaches an open dialog, panel or toast also
/// when [DsScope] sits below the navigator (inside a page, as in
/// `home: DsScope(child: …)`), and a layer opened during the theme's
/// cross-fade ends on the final colors. It catches up one frame after the
/// opener's context changes. When that context leaves the tree (the page
/// under the layer is gone), the layer keeps what it last saw.
@immutable
class DsCapturedThemes {
  const DsCapturedThemes._({
    this._theme,
    this._direction,
    this._localizations,
    this._componentThemes = const [],
  });

  /// Captures what [from] has between itself and [to], an ancestor of
  /// [from] (usually the navigator's or overlay's context). When [to] is
  /// not an ancestor, everything up to the root is captured.
  factory DsCapturedThemes.capture({
    required BuildContext from,
    required BuildContext? to,
  }) {
    _Link<DsTheme>? theme;
    _Link<Directionality>? direction;
    _Link<DsLocalizationScope>? localizations;
    final components = <_Link<DsComponentTheme<dynamic>>>[];
    from.visitAncestorElements((element) {
      if (identical(element, to)) return false;
      switch (element.widget) {
        case final DsTheme w:
          theme ??= _Link(element, w);
        case final Directionality w:
          direction ??= _Link(element, w);
        case final DsLocalizationScope w:
          localizations ??= _Link(element, w);
        case final DsComponentTheme<dynamic> w:
          components.add(_Link(element, w));
      }
      return true;
    });
    return DsCapturedThemes._(
      theme: theme,
      direction: direction,
      localizations: localizations,
      // Outermost first, so each one merges over the next as it did.
      componentThemes: components.reversed.toList(growable: false),
    );
  }

  /// Nothing captured: the layer inherits everything from its host.
  static const DsCapturedThemes none = DsCapturedThemes._();

  final _Link<DsTheme>? _theme;
  final _Link<Directionality>? _direction;
  final _Link<DsLocalizationScope>? _localizations;
  final List<_Link<DsComponentTheme<dynamic>>> _componentThemes;

  List<_Link<Widget>> get _links => [
    ?_theme,
    ?_direction,
    ?_localizations,
    ..._componentThemes,
  ];

  /// The opener's theme as it is now, when it came from below the host;
  /// null when the layer inherits the host's theme.
  DsThemeData? get theme => _theme?.current.data;

  /// The opener's direction as it is now, when it came from below the
  /// host.
  TextDirection? get textDirection => _direction?.current.textDirection;

  /// The opener's localization scope as it is now, when it came from below
  /// the host.
  DsLocalizationScope? get localizations => _localizations?.current;

  /// Wraps [child] in what was captured, following it live.
  Widget wrap(Widget child) =>
      _links.isEmpty ? child : _CapturedScope(captured: this, child: child);

  Widget _wrapNow(Widget child) {
    var result = child;
    for (final link in _componentThemes.reversed) {
      final data = link.current.data as Object?;
      if (data is DsComponentThemeData<DsComponentThemeData<dynamic>>) {
        result = data.wrap(result);
      }
    }
    if (textDirection case final d?) {
      result = Directionality(textDirection: d, child: result);
    }
    if (theme case final t?) result = DsTheme(data: t, child: result);
    if (localizations case final scope?) {
      result = DsLocalizationScope(
        overrides: scope.overrides,
        localizations: scope.localizations,
        child: result,
      );
    }
    return result;
  }
}

/// One captured ancestor: read live from its element while that is in the
/// tree, else as it was last seen.
class _Link<W extends Widget> {
  _Link(this._element, this._last);

  final Element _element;
  W _last;

  W get current {
    if (_element.mounted) {
      if (_element.widget case final W w) _last = w;
    }
    return _last;
  }
}

/// Builds the captured context and rebuilds when the opener's changes. The
/// layer sits elsewhere in the tree, so it cannot depend on those
/// ancestors; it checks them after each frame instead (a few identity
/// checks, only while the layer is up and frames run anyway).
class _CapturedScope extends StatefulWidget {
  const _CapturedScope({required this.captured, required this.child});

  final DsCapturedThemes captured;
  final Widget child;

  @override
  State<_CapturedScope> createState() => _CapturedScopeState();
}

class _CapturedScopeState extends State<_CapturedScope> {
  List<Widget> _seen = const [];

  @override
  void initState() {
    super.initState();
    _watch();
  }

  void _watch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = [for (final l in widget.captured._links) l.current];
      if (now.length != _seen.length ||
          [for (var i = 0; i < now.length; i++) i]
              .any((i) => !identical(now[i], _seen[i]))) {
        setState(() {});
      }
      _watch();
    });
  }

  @override
  Widget build(BuildContext context) {
    _seen = [for (final l in widget.captured._links) l.current];
    return widget.captured._wrapNow(widget.child);
  }
}

/// Where a modal sits.
enum DsModalPlacement {
  /// Centered: dialogs. Grows in slightly.
  center,

  /// Along the end edge (right in LTR): side panels. Slides in.
  end,

  /// Along the bottom: bottom sheets. Slides up.
  bottom,
}

/// What a modal does to the page behind it.
enum DsScrim {
  /// Dims the page with the theme's scrim color. The default.
  dim,

  /// Leaves the page at full contrast, for a live preview: a sheet of
  /// settings whose effect shows on the page above it as they change. The
  /// page still does not take pointer input while the modal is open, and
  /// a tap on it still closes a dismissible modal.
  clear,
}

/// A modal layer over a scrim: dialogs, side panels and bottom sheets.
///
/// As a route it traps focus while open and gives focus back to the
/// opener when it closes; Escape, a tap on the scrim and system back close
/// it when [barrierDismissible].
///
/// **Context.** The modal inherits the theme above its navigator live, so
/// a theme switch while it is open (dark mode, contrast, reduce
/// motion) restyles it and its scrim. What the opener had between itself
/// and the navigator ([captured]: a subtree [DsTheme], component themes,
/// direction, localization scope) is carried over and followed live, so a
/// modal opened inside a themed section looks like that section, also
/// after it changes (a [DsScope] inside the page). [theme] pins one theme
/// instead.
///
/// [scrim] can leave the page undimmed ([DsScrim.clear]); the barrier
/// keeps blocking and dismissing as above.
///
/// Motion: the scrim fades with the tone spring. A centered modal
/// grows in with the movement spring; panels slide in without bouncing
/// past the edge. Closing is a quick fade. With reduced motion, only
/// fades.
class DsModalRoute<T> extends PopupRoute<T> {
  /// Creates a modal route. Prefer `showDsDialog` and `showDsPanel`.
  DsModalRoute({
    required this.builder,
    this.captured = DsCapturedThemes.none,
    this.theme,
    this.direction,
    this.localizations,
    this.placement = DsModalPlacement.center,
    this.scrim = DsScrim.dim,
    this._dismissible = true,
    this.semanticBarrierLabel,
    super.settings,
  });

  /// Builds the modal's content.
  final WidgetBuilder builder;

  /// The opener's context from below the navigator (see [showDsModal]).
  final DsCapturedThemes captured;

  /// Pins the modal to this theme. Null follows the inherited theme.
  final DsThemeData? theme;

  /// Pins the text direction. Null follows the inherited direction.
  final TextDirection? direction;

  /// Pins a localization scope. Null follows the inherited one.
  final DsLocalizationScope? localizations;

  /// Where the modal sits.
  final DsModalPlacement placement;

  /// Whether the page behind is dimmed.
  final DsScrim scrim;

  /// Read by the scrim for screen readers ("Close").
  final String? semanticBarrierLabel;

  final bool _dismissible;

  /// Wraps [child] in the captured and pinned context.
  Widget _context(Widget child) {
    Widget result = child;
    if (direction case final d?) {
      result = Directionality(textDirection: d, child: result);
    }
    if (theme case final t?) result = DsTheme(data: t, child: result);
    result = captured.wrap(result);
    if (localizations case final scope?) {
      result = DsLocalizationScope(
        overrides: scope.overrides,
        localizations: scope.localizations,
        child: result,
      );
    }
    return result;
  }

  /// The theme the modal shows in, for [context] below the navigator.
  DsThemeData _themeFor(BuildContext? context) =>
      theme ??
      captured.theme ??
      (context == null ? null : DsTheme.maybeOf(context)) ??
      navigatorTheme ??
      DsThemeData();

  /// The theme above the navigator, if any.
  DsThemeData? get navigatorTheme =>
      navigator?.context.getInheritedWidgetOfExactType<DsTheme>()?.data;

  DsMotion get _motion => _themeFor(null).motion;

  @override
  bool get barrierDismissible => _dismissible;

  /// System back (the Android back button and gesture, the browser's back,
  /// `Navigator.maybePop`) closes the modal only when it is dismissible,
  /// like Escape and the scrim. `Navigator.pop` from the modal's own
  /// actions always closes it.
  @override
  RoutePopDisposition get popDisposition =>
      _dismissible ? super.popDisposition : RoutePopDisposition.doNotPop;

  @override
  Color get barrierColor => _scrimColor(_themeFor(null).colors.scrim);

  /// The scrim color for [scrim], from the theme's [themed] scrim.
  Color _scrimColor(Color themed) => switch (scrim) {
    DsScrim.dim => themed,
    DsScrim.clear => themed.withValues(alpha: 0),
  };

  @override
  String? get barrierLabel => semanticBarrierLabel;

  @override
  Curve get barrierCurve => _motion.toneCurve;

  @override
  Duration get transitionDuration =>
      _motion.reduced ? _motion.toneDuration : _motion.moveDuration;

  @override
  Duration get reverseTransitionDuration => _motion.toneDuration;

  /// The scrim reads its color from the live theme, so it follows a theme
  /// switch while the modal is open.
  @override
  Widget buildModalBarrier() => _context(
    Builder(
      builder: (context) {
        final scrim = _scrimColor(DsTheme.colorsOf(context).scrim);
        return AnimatedModalBarrier(
          color: animation!.drive(
            ColorTween(
              begin: scrim.withValues(alpha: 0),
              end: scrim,
            ).chain(CurveTween(curve: barrierCurve)),
          ),
          dismissible: barrierDismissible,
          semanticsLabel: barrierLabel,
          barrierSemanticsDismissible: semanticsDismissible,
        );
      },
    ),
  );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _context(
    Builder(
      builder: (context) {
        final t = DsTheme.of(context);
        return DefaultTextStyle(
          style: t.typography.body.copyWith(color: t.colors.text),
          child: IconTheme(
            data: IconThemeData(
              color: t.colors.text,
              size: t.sizes.iconSize(DsSize.md),
            ),
            child: Builder(builder: builder),
          ),
        );
      },
    ),
  );

  // The curved animations live as long as the route, not one build: they
  // listen to the route's animation and must be disposed (eng L4).
  Animation<double>? _parent;
  DsMotion? _curvesMotion;
  CurvedAnimation? _fade, _move;

  void _curves(Animation<double> parent, DsMotion motion) {
    if (identical(parent, _parent) && motion == _curvesMotion) return;
    _disposeCurves();
    _parent = parent;
    _curvesMotion = motion;
    _fade = CurvedAnimation(
      parent: parent,
      curve: motion.toneCurve,
      reverseCurve: motion.toneCurve.flipped,
    );
    _move = CurvedAnimation(
      parent: parent,
      curve: motion.moveCurve,
      reverseCurve: motion.toneCurve.flipped,
    );
  }

  void _disposeCurves() {
    _fade?.dispose();
    _move?.dispose();
    _fade = _move = null;
  }

  @override
  void dispose() {
    _disposeCurves();
    super.dispose();
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final motion = _themeFor(context).motion;
    _curves(animation, motion);
    final fade = _fade!;
    if (motion.reduced) return FadeTransition(opacity: fade, child: child);
    final move = _move!;
    final rtl =
        (direction ??
            captured.textDirection ??
            Directionality.maybeOf(context)) ==
        TextDirection.rtl;
    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: move,
        child: child,
        builder: (context, child) {
          final v = move.value;
          // Panels never travel past their edge; dialogs may overshoot a hair.
          final p = v.clamp(0.0, 1.0);
          return switch (placement) {
            DsModalPlacement.center => Transform.scale(
              scale: motion.overlayScale + (1 - motion.overlayScale) * v,
              child: child,
            ),
            DsModalPlacement.end => FractionalTranslation(
              translation: Offset((1 - p) * (rtl ? -1 : 1), 0),
              child: child,
            ),
            DsModalPlacement.bottom => FractionalTranslation(
              translation: Offset(0, 1 - p),
              child: child,
            ),
          };
        },
      ),
    );
  }
}

/// Opens a modal from [context]. The modal follows the theme above the
/// navigator live and carries what [context] has below it (see
/// [DsCapturedThemes]). [scrim] leaves the page undimmed with
/// [DsScrim.clear].
Future<T?> showDsModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  DsModalPlacement placement = DsModalPlacement.center,
  bool dismissible = true,
  DsScrim scrim = DsScrim.dim,
  bool useRootNavigator = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(
    DsModalRoute<T>(
      builder: builder,
      captured: DsCapturedThemes.capture(from: context, to: navigator.context),
      placement: placement,
      scrim: scrim,
      dismissible: dismissible,
      semanticBarrierLabel: DsLocalizations.of(context).close,
    ),
  );
}
