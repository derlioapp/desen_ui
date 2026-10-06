import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'motion.dart';
import 'palette.dart';
import 'platform_contrast.dart';
import 'radii.dart';
import 'shadows.dart';
import 'sizes.dart';
import 'theme_data.dart';
import 'theme_extension.dart';
import 'typography.dart';

/// Which brightness [DsScope] uses.
enum DsThemeMode {
  /// Follow the platform setting.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// The token groups a widget can depend on separately.
enum DsThemeAspect {
  /// [DsThemeData.colors].
  colors,

  /// [DsThemeData.shadows].
  shadows,

  /// [DsThemeData.radii].
  radii,

  /// [DsThemeData.sizes].
  sizes,

  /// [DsThemeData.typography].
  typography,

  /// [DsThemeData.motion].
  motion,

  /// [DsThemeData.extensions].
  extensions,
}

/// Makes a [DsThemeData] available to descendants.
///
/// Most apps use [DsScope] (or `DsApp`), which also follows the platform's
/// brightness, contrast and reduce-motion settings. Use [DsTheme] directly to
/// override the theme for a subtree.
///
/// Reading a single token group (e.g. [colorsOf]) only rebuilds the reader
/// when that group changes.
///
/// It is an inherited theme (`InheritedTheme`): a route or overlay that
/// captures the opener's themes, Flutter's own dialogs included, shows its
/// layer in the opener's [DsTheme] even when that sits below the
/// navigator.
class DsTheme extends InheritedModel<DsThemeAspect> implements InheritedTheme {
  /// Provides [data] to [child].
  const DsTheme({super.key, required this.data, required super.child});

  /// The theme.
  final DsThemeData data;

  static final Map<(Brightness, TargetPlatform), DsThemeData> _fallback = {};

  /// The nearest theme, or a default one when there is no [DsTheme] above.
  ///
  /// Components keep working without any setup: the fallback follows the
  /// platform brightness and [defaultTargetPlatform].
  static DsThemeData of(BuildContext context) => _of(context, null);

  /// The nearest theme, or null when there is none.
  static DsThemeData? maybeOf(BuildContext context) =>
      InheritedModel.inheritFrom<DsTheme>(context)?.data;

  /// Colors only. Rebuilds the caller only when colors change.
  static DsColors colorsOf(BuildContext context) =>
      _of(context, DsThemeAspect.colors).colors;

  /// Shadows only.
  static DsShadows shadowsOf(BuildContext context) =>
      _of(context, DsThemeAspect.shadows).shadows;

  /// Radii only.
  static DsRadii radiiOf(BuildContext context) =>
      _of(context, DsThemeAspect.radii).radii;

  /// Sizes only.
  static DsSizes sizesOf(BuildContext context) =>
      _of(context, DsThemeAspect.sizes).sizes;

  /// Typography only.
  static DsTypography typographyOf(BuildContext context) =>
      _of(context, DsThemeAspect.typography).typography;

  /// Motion only.
  static DsMotion motionOf(BuildContext context) =>
      _of(context, DsThemeAspect.motion).motion;

  /// The app's extension of type [T] (see [DsThemeExtension]), or null
  /// when the theme has none. Rebuilds the caller only when the theme's
  /// extensions change.
  static T? extensionOf<T extends DsThemeExtension<T>>(BuildContext context) =>
      _of(context, DsThemeAspect.extensions).extension<T>();

  static DsThemeData _of(BuildContext context, DsThemeAspect? aspect) {
    final theme = InheritedModel.inheritFrom<DsTheme>(context, aspect: aspect);
    if (theme != null) return theme.data;
    final brightness =
        MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light;
    return _fallback[(brightness, defaultTargetPlatform)] ??= DsThemeData(
      brightness: brightness,
    );
  }

  @override
  Widget wrap(BuildContext context, Widget child) =>
      DsTheme(data: data, child: child);

  @override
  bool updateShouldNotify(DsTheme oldWidget) => data != oldWidget.data;

  @override
  bool updateShouldNotifyDependent(
    DsTheme oldWidget,
    Set<DsThemeAspect> aspects,
  ) {
    final a = data, b = oldWidget.data;
    return aspects.any(
      (aspect) => switch (aspect) {
        DsThemeAspect.colors => a.colors != b.colors,
        DsThemeAspect.shadows => a.shadows != b.shadows,
        DsThemeAspect.radii => a.radii != b.radii,
        DsThemeAspect.sizes => a.sizes != b.sizes,
        DsThemeAspect.typography => a.typography != b.typography,
        DsThemeAspect.motion => a.motion != b.motion,
        DsThemeAspect.extensions => !mapEquals(a.extensions, b.extensions),
      },
    );
  }
}

/// A [DsTheme] that animates to a new [data] instead of jumping.
///
/// It lerps every token each frame, so every widget that depends on the
/// theme (and every [Text] under [DsScope]'s default text style) rebuilds
/// once per frame of the transition. [DsScope] does not use it: it
/// cross-fades a snapshot instead, which rebuilds once (see
/// [DsScope.animateChanges]).
class DsAnimatedTheme extends ImplicitlyAnimatedWidget {
  /// Animates theme changes over [duration].
  const DsAnimatedTheme({
    super.key,
    required this.data,
    required this.child,
    super.duration = const Duration(milliseconds: 150),
    super.curve = Curves.easeOut,
    super.onEnd,
  });

  /// The target theme.
  final DsThemeData data;

  /// The subtree.
  final Widget child;

  @override
  AnimatedWidgetBaseState<DsAnimatedTheme> createState() =>
      _DsAnimatedThemeState();
}

class _DsAnimatedThemeState extends AnimatedWidgetBaseState<DsAnimatedTheme> {
  _DsThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (value) => _DsThemeDataTween(begin: value as DsThemeData),
    ) as _DsThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) =>
      DsTheme(data: _data!.evaluate(animation), child: widget.child);
}

class _DsThemeDataTween extends Tween<DsThemeData> {
  _DsThemeDataTween({super.begin});

  @override
  DsThemeData lerp(double t) => DsThemeData.lerp(begin!, end!, t);
}

/// Sets up Desen for a subtree: theme, default text and icon styles, and
/// text selection colors.
///
/// Unlike app wrappers in other libraries, [DsScope] does not need to sit at
/// the root and does not require `DsApp`. It works inside a `WidgetsApp`, a
/// `MaterialApp` or a plain widget tree.
///
/// It follows the platform: dark mode (per [themeMode]), a request for more
/// contrast (when [followPlatformContrast]) and reduce motion. Reduce motion
/// only changes [DsThemeData.motion]. More contrast lifts a soft theme to
/// [DsContrast.standard], the strongest level, regenerating a generated
/// theme's colors; a [DsThemeData.raw] theme with hand-set tokens keeps them
/// and only takes the setting.
class DsScope extends StatefulWidget {
  /// Creates a scope.
  const DsScope({
    super.key,
    this.theme,
    this.darkTheme,
    this.themeMode = DsThemeMode.system,
    this.followPlatformContrast = true,
    this.animateChanges = true,
    required this.child,
  });

  /// The light theme. Defaults to `DsThemeData()`.
  final DsThemeData? theme;

  /// The dark theme. Defaults to [theme] with dark brightness, so one theme
  /// definition covers both modes. A hand-built [theme]
  /// ([DsThemeData.raw]) cannot be turned dark without losing its tokens
  /// (see [DsThemeData.copyWith]): give it a dark theme of its own.
  final DsThemeData? darkTheme;

  /// Which brightness to use.
  final DsThemeMode themeMode;

  /// Lift a [DsContrast.soft] theme to [DsContrast.standard] when the
  /// platform asks for more contrast: `MediaQueryData.highContrast` (iOS
  /// "Increase contrast", Android high-contrast text, Windows contrast
  /// themes) and, on the web, the browser's `prefers-contrast: more`
  /// (macOS and iOS "Increase contrast"). A standard theme is kept as it
  /// is: standard is the strongest level.
  final bool followPlatformContrast;

  /// Cross-fade when the theme's colors change (e.g. switching to dark).
  ///
  /// The subtree switches to the new theme at once, in a single rebuild,
  /// and a snapshot of its last frame fades out over it over
  /// [DsMotion.toneDuration] (like the web's View Transitions). The blend is
  /// of finished pixels, so nothing dips through a lighter or darker shade.
  /// While it fades the snapshot holds still: something that
  /// moves in that time (a switch's thumb) shows a brief trace of where it
  /// was. A change of sizes, radii or typography (density, text scale)
  /// does not fade: the layout jumps, like it would on the web. Nor does a
  /// change while the subtree's tickers are muted.
  ///
  /// Only this subtree is captured: layers shown above it (a dialog of a
  /// navigator above this scope) take the new colors at once.
  ///
  /// False switches at once.
  final bool animateChanges;

  /// The subtree.
  final Widget child;

  @override
  State<DsScope> createState() => _DsScopeState();
}

class _DsScopeState extends State<DsScope> {
  // Regenerating a palette is cheap but not free; cache derived themes so
  // rebuilds with unchanged inputs reuse the same instance. Theme equality
  // ignores the adjust hooks (K-31), so the key also holds the hooks: a
  // changed hook can change the derived dark or standard-contrast theme even
  // when the theme it hangs on compares equal.
  final Map<Object, DsThemeData> _cache = {};

  @override
  void initState() {
    super.initState();
    prefersMoreContrast.addListener(_onBrowserContrast);
  }

  @override
  void dispose() {
    prefersMoreContrast.removeListener(_onBrowserContrast);
    super.dispose();
  }

  void _onBrowserContrast() {
    if (widget.followPlatformContrast) setState(() {});
  }

  DsThemeData _resolve(Brightness brightness, bool highContrast, bool reduced) {
    final source = brightness == Brightness.dark
        ? widget.darkTheme
        : widget.theme;
    final base = widget.theme;
    final key = (
      source,
      _hooks(source),
      _hooks(base),
      brightness,
      highContrast,
      reduced,
    );
    final cached = _cache[key];
    if (cached != null) return cached;
    if (_cache.length > 8) _cache.clear();

    var data = brightness == Brightness.dark
        ? widget.darkTheme ?? _darkFrom(widget.theme ?? DsThemeData())
        : widget.theme ?? DsThemeData();
    if (highContrast && data.contrast == DsContrast.soft) {
      // A generated soft theme regenerates its colors at standard
      // contrast. A raw theme with hand-set tokens keeps them: only the
      // setting changes.
      data = _isGenerated(data)
          ? data.copyWith(contrast: DsContrast.standard)
          : _withSettings(data, contrast: DsContrast.standard);
    }
    if (reduced != data.motion.reduced) {
      // Motion never feeds the generated tokens, so no regeneration.
      data = _withSettings(
        data,
        motion: data.motion.copyWith(reduced: reduced),
      );
    }
    return _cache[key] = data;
  }

  /// The dark theme derived from [light]. A hand-built theme cannot be
  /// regenerated without losing its tokens, so without a `darkTheme` it is
  /// used as is (with a debug warning) rather than failing the app when the
  /// platform switches to dark.
  static DsThemeData _darkFrom(DsThemeData light) {
    if (_isGenerated(light)) {
      return light.copyWith(brightness: Brightness.dark);
    }
    assert(() {
      if (!_warnedRawDark) {
        _warnedRawDark = true;
        debugPrint(
          'DsScope: dark mode with a hand-built theme (DsThemeData.raw) and '
          'no darkTheme. Its tokens are kept as they are; give DsScope a '
          'darkTheme to style dark mode.',
        );
      }
      return true;
    }());
    return light;
  }

  static bool _warnedRawDark = false;

  static (Object?, Object?, Object?, Object?) _hooks(DsThemeData? d) =>
      (d?.adjustColors, d?.adjustShadows, d?.adjustRadii, d?.adjustSizes);

  /// Whether [d]'s tokens are exactly what its settings generate, so
  /// regenerating loses nothing.
  static bool _isGenerated(DsThemeData d) =>
      DsThemeData(
        brightness: d.brightness,
        seed: d.seed,
        contrast: d.contrast,
        cornerStyle: d.cornerStyle,
        density: d.densityFollowsPlatform ? null : d.density,
        platform: d.platform,
        selectionStyle: d.selectionStyle,
        autoClashRule: d.autoClashRule,
        dangerOverride: d.dangerOverride,
        successOverride: d.successOverride,
        warningOverride: d.warningOverride,
        adjustColors: d.adjustColors,
        adjustShadows: d.adjustShadows,
        adjustRadii: d.adjustRadii,
        adjustSizes: d.adjustSizes,
        typography: d.typography,
        motion: d.motion,
        haptics: d.haptics,
      ) ==
      // Extensions are not tokens: they do not make a theme hand-built.
      d.copyWith(extensions: const []);

  /// [d] with settings replaced and every token kept as is. Its
  /// extensions are resolved again for the new settings.
  static DsThemeData _withSettings(
    DsThemeData d, {
    DsContrast? contrast,
    DsMotion? motion,
  }) => DsThemeData.raw(
    brightness: d.brightness,
    seed: d.seed,
    contrast: contrast ?? d.contrast,
    cornerStyle: d.cornerStyle,
    density: d.density,
    densityFollowsPlatform: d.densityFollowsPlatform,
    platform: d.platform,
    selectionStyle: d.selectionStyle,
    autoClashRule: d.autoClashRule,
    dangerOverride: d.dangerOverride,
    successOverride: d.successOverride,
    warningOverride: d.warningOverride,
    adjustColors: d.adjustColors,
    adjustShadows: d.adjustShadows,
    adjustRadii: d.adjustRadii,
    adjustSizes: d.adjustSizes,
    seedRole: d.seedRole,
    colors: d.colors,
    shadows: d.shadows,
    radii: d.radii,
    sizes: d.sizes,
    typography: d.typography,
    motion: motion ?? d.motion,
    haptics: d.haptics,
  ).copyWith(extensions: d.extensions.values);

  @override
  void didUpdateWidget(DsScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme ||
        oldWidget.darkTheme != widget.darkTheme) {
      _cache.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformDark =
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
    final dark = switch (widget.themeMode) {
      DsThemeMode.system => platformDark,
      DsThemeMode.light => false,
      DsThemeMode.dark => true,
    };
    final data = _resolve(
      dark ? Brightness.dark : Brightness.light,
      widget.followPlatformContrast &&
          ((MediaQuery.maybeHighContrastOf(context) ?? false) ||
              prefersMoreContrast.value),
      MediaQuery.maybeDisableAnimationsOf(context) ?? false,
    );
    // One structure with and without the fade, so switching
    // [DsScope.animateChanges] keeps the subtree's state.
    return DsTheme(
      data: data,
      child: _ThemeCrossFade(
        data: data,
        enabled: widget.animateChanges,
        child: _DsDefaults(child: widget.child),
      ),
    );
  }
}

/// Fades a snapshot of the subtree's last frame out over the subtree when
/// the theme's colors change, so the subtree itself rebuilds once rather
/// than once per frame of a token lerp.
class _ThemeCrossFade extends StatefulWidget {
  const _ThemeCrossFade({
    required this.data,
    required this.enabled,
    required this.child,
  });

  final DsThemeData data;
  final bool enabled;
  final Widget child;

  @override
  State<_ThemeCrossFade> createState() => _ThemeCrossFadeState();
}

class _ThemeCrossFadeState extends State<_ThemeCrossFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _box?.snapshot = null;
    });

  _RenderThemeCrossFade? get _box {
    final box = context.findRenderObject();
    return box is _RenderThemeCrossFade ? box : null;
  }

  /// Whether a change from [a] to [b] fades: the colors (or shadows)
  /// change and nothing that moves the layout does.
  static bool _tonesOnly(DsThemeData a, DsThemeData b) =>
      (a.colors != b.colors || a.shadows != b.shadows) &&
      a.sizes == b.sizes &&
      a.radii == b.radii &&
      a.typography == b.typography;

  @override
  void didUpdateWidget(_ThemeCrossFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    final box = _box;
    if (box == null) return;
    final motion = widget.data.motion;
    final fades =
        widget.enabled &&
        motion.toneDuration > Duration.zero &&
        TickerMode.valuesOf(context).enabled &&
        _tonesOnly(oldWidget.data, widget.data);
    if (!fades) {
      if (!widget.enabled || oldWidget.data != widget.data) {
        _fade.stop();
        box.snapshot = null;
      }
      return;
    }
    // The frame on screen now, mid-fade one included.
    final snapshot = box.capture(View.maybeOf(context)?.devicePixelRatio ?? 1);
    box
      ..snapshot = snapshot
      ..curve = motion.toneCurve;
    if (snapshot == null) {
      _fade.stop();
      return;
    }
    _fade
      ..duration = motion.toneDuration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ThemeCrossFadeBox(
    fade: _fade,
    // The live subtree keeps its own layer, so a frame of the fade only
    // composites; nothing below repaints for it.
    child: RepaintBoundary(child: widget.child),
  );
}

class _ThemeCrossFadeBox extends SingleChildRenderObjectWidget {
  const _ThemeCrossFadeBox({required this.fade, super.child});

  final Animation<double> fade;

  @override
  _RenderThemeCrossFade createRenderObject(BuildContext context) =>
      _RenderThemeCrossFade(fade);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderThemeCrossFade renderObject,
  ) => renderObject.fade = fade;
}

/// Paints its child, then the snapshot over it at the fade's opacity.
class _RenderThemeCrossFade extends RenderProxyBox {
  _RenderThemeCrossFade(this._fade);

  Animation<double> _fade;
  set fade(Animation<double> value) {
    if (identical(value, _fade)) return;
    if (attached) _fade.removeListener(markNeedsPaint);
    _fade = value;
    if (attached) _fade.addListener(markNeedsPaint);
  }

  Curve curve = Curves.linear;

  /// The frame before the change, and the size it was taken at.
  ui.Image? _snapshot;
  Size? _snapshotSize;
  set snapshot(ui.Image? value) {
    if (identical(value, _snapshot)) return;
    _snapshot?.dispose();
    _snapshot = value;
    _snapshotSize = value == null ? null : size;
    markNeedsPaint();
  }

  @override
  bool get isRepaintBoundary => true;

  /// This box's last frame as an image, or null before the first one.
  ui.Image? capture(double pixelRatio) {
    final layer = this.layer;
    if (layer is! OffsetLayer || !hasSize || size.isEmpty) return null;
    try {
      return layer.toImageSync(Offset.zero & size, pixelRatio: pixelRatio);
    } on Object {
      // A backend that cannot snapshot: switch at once.
      return null;
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _fade.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _fade.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _snapshot?.dispose();
    _snapshot = null;
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final image = _snapshot;
    // A resized box would stretch the old frame: the new one shows alone.
    if (image == null || _snapshotSize != size) return;
    final opacity = 1 - curve.transform(_fade.value.clamp(0, 1));
    if (opacity <= 0) return;
    context.canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      offset & size,
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, opacity)
        ..filterQuality = FilterQuality.medium,
    );
  }
}

/// Default text, icon and selection styles derived from the theme.
class _DsDefaults extends StatelessWidget {
  const _DsDefaults({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = DsTheme.colorsOf(context);
    final typography = DsTheme.typographyOf(context);
    return DefaultTextStyle(
      style: typography.body.copyWith(color: colors.text),
      child: IconTheme(
        data: IconThemeData(color: colors.text, size: 16),
        child: DefaultSelectionStyle(
          // 3:1 on the field even under a bright accent (yellow caret).
          cursorColor: colors.indicator,
          // The soft selection fill: text stays AA on it and it stands off
          // the field (K-75), here for SelectableRegion and SelectableText.
          selectionColor: colors.selection,
          child: child,
        ),
      ),
    );
  }
}
