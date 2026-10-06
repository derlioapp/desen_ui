import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/color_utils.dart';
import '../../foundation/oklch.dart';
import '../../foundation/spring.dart';
import '../../behavior/spring_value.dart';
import '../../behavior/press_effect.dart';
import '../../behavior/pressable.dart';
import '../../overlay/anchored_overlay.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/colors.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../spinner/spinner.dart';
import 'button_style.dart';
import 'button_theme.dart';

const _clear = Color(0x00000000);

/// A button.
///
/// ```dart
/// DsButton(onPressed: save, child: const Text('Save'))
/// DsButton(
///   variant: .secondary,
///   size: .sm,
///   leading: const DsIcon(DsIcons.plus),
///   onPressed: add,
///   child: const Text('New task'),
/// )
/// DsButton.icon(
///   icon: const DsIcon(DsIcons.ellipsis),
///   semanticLabel: 'More',
///   onPressed: openMenu,
/// )
/// ```
///
/// A null [onPressed] (and [onLongPress]) disables the button.
///
/// While [loading], presses are ignored but the button keeps keyboard focus
/// and its enabled look, and screen readers hear "loading" (localized). A
/// spinner replaces the leading icon; without one, it takes the label's
/// place while the label keeps the width, so the button never changes size.
///
/// **Keyboard:** Tab focuses (with a visible ring), Enter or Space activates.
///
/// **Customizing:** see [DsButtonStyle] for how [style], [DsButtonTheme] and
/// the defaults combine.
class DsButton extends StatefulWidget {
  /// Creates a text button with optional icons.
  const DsButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant,
    this.size,
    this.leading,
    this.trailing,
    this.loading = false,
    this.style,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.semanticLabel,
    this.semanticExpanded,
  }) : _iconOnly = false;

  /// Creates a square, icon-only button. [semanticLabel] is required so
  /// screen readers can name it.
  const DsButton.icon({
    super.key,
    required this.onPressed,
    required Widget icon,
    required String this.semanticLabel,
    this.variant,
    this.size,
    this.loading = false,
    this.style,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.semanticExpanded,
  }) : child = icon,
       leading = null,
       trailing = null,
       _iconOnly = true;

  /// Called when the button is activated. Null disables it, unless
  /// [onLongPress] is set.
  final VoidCallback? onPressed;

  /// Called on long press. A button with only [onLongPress] is enabled.
  final VoidCallback? onLongPress;

  /// The label, usually a [Text]; for [DsButton.icon], the icon.
  final Widget child;

  /// Visual variant. Defaults to the theme's, then [DsButtonVariant.primary]
  /// for text buttons and [DsButtonVariant.ghost] for icon buttons.
  final DsButtonVariant? variant;

  /// Size. Defaults to the theme's, then [DsSize.md].
  final DsSize? size;

  /// Widget before the label, usually a `DsIcon`.
  final Widget? leading;

  /// Widget after the label.
  final Widget? trailing;

  /// Shows a spinner and ignores presses, without the disabled look; the
  /// button stays focusable and announces that it is loading.
  final bool loading;

  /// Style laid over the theme and defaults.
  final DsButtonStyle? style;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Observe or force interaction states.
  final WidgetStatesController? statesController;

  /// Label for screen readers. Required for icon buttons; text buttons use
  /// their text.
  final String? semanticLabel;

  /// Announces whether the menu, popover or other layer this button opens
  /// is open (WAI-ARIA `aria-expanded`); null for a button that opens
  /// nothing. Inside a `DsMenuAnchor` or `DsPopover` trigger it follows the
  /// layer by itself ([DsAnchoredOverlay.triggerExpandedOf]); set it for a
  /// layer of your own.
  final bool? semanticExpanded;

  final bool _iconOnly;

  /// Desen's default style for [variant] and [size] under [theme].
  ///
  /// Exposed so custom variants can start from a built-in one.
  static DsButtonStyle defaultStyle(
    DsThemeData theme, {
    required DsButtonVariant variant,
    required DsSize size,
    bool iconOnly = false,
  }) {
    final k = theme.colors;
    final ghost = variant == DsButtonVariant.ghost;
    final height = theme.sizes.height(size);
    // Horizontal padding on the 4px rhythm; ghost buttons sit tighter
    // because they have no visible edge until hovered.
    final pad = switch (size) {
      DsSize.xs => ghost ? DsSpace.s6 : DsSpace.s8,
      DsSize.sm => ghost ? DsSpace.s8 : DsSpace.s12,
      DsSize.md => ghost ? DsSpace.s16 : DsSpace.s20,
      DsSize.lg => ghost ? DsSpace.s20 : DsSpace.s24,
    };
    final base = DsButtonStyle(
      height: height,
      padding: iconOnly
          ? EdgeInsets.zero
          : EdgeInsetsDirectional.symmetric(horizontal: pad),
      gap: size == DsSize.xs ? DsSpace.s6 : DsSpace.s8,
      iconSize: theme.sizes.iconSize(size),
      // No radius: the corners follow whatever height the layers settle
      // on (DsRadii.controlCorners).
      borderColor: _clear,
      borderWidth: 1,
      shadows: const [],
      focusShadows: theme.focusShadows,
      pressScale: ghost
          ? 1
          : size.index >= DsSize.md.index
          ? theme.motion.pressScaleLarge
          : theme.motion.pressScale,
      // The type scale's control label for the size, one weight (600)
      // for every variant and size, so a row of mixed buttons reads as one
      // set.
      textStyle: theme.typography.controlLabel(size),
      disabled: DsButtonStyle(
        background: ghost ? _clear : k.disabled,
        foreground: k.onDisabled,
        borderColor: _clear,
        shadows: const [],
        focusShadows: const [],
      ),
    );
    // Pressed goes one step beyond hovered, never lighter: a touch
    // press, which has no hover, still reads as deeper than rest.
    DsButtonStyle shade(Color hover, Color press) => DsButtonStyle(
      hovered: DsButtonStyle(background: hover),
      pressed: DsButtonStyle(background: press),
    );
    final colors = switch (variant) {
      DsButtonVariant.primary => DsButtonStyle(
        background: k.accent,
        foreground: k.onAccent,
        shadows: theme.shadows.accent,
      ).merge(shade(k.accentHover, k.accentPress)),
      DsButtonVariant.secondary => DsButtonStyle(
        background: k.control,
        // Icon-only secondary buttons use muted ink.
        foreground: iconOnly ? k.textMuted : k.text,
        borderColor: k.borderControl,
        shadows: theme.shadows.controlLift,
        // Bordered: the ring takes the border's place, one 2px line on the
        // edge, instead of circling it.
        focusShadows: theme.shadows.focusTight,
      ).merge(shade(k.controlHover, k.controlPress)),
      DsButtonVariant.tinted => () {
        // The accent as a wash under accent ink, like iOS's tinted button:
        // 15% of it in light mode, 18% in dark mode, where the darker
        // layers need a little more to show the hue. Hover and press add
        // more of it, as a soft danger button does. (The lighter dark-mode
        // indicator would read brighter, but its wash leaves the ink
        // under 4.5:1 on a dialog's lighter layer.)
        final [rest, hover, press] = _washes(
          k.accent,
          theme.isDark ? const [.18, .23, .28] : const [.15, .19, .23],
          ink: k.accentText,
          backdrops: [k.canvas, k.surface, k.sidebar, k.overlay],
        );
        return DsButtonStyle(
          background: rest,
          foreground: k.accentText,
        ).merge(shade(hover, press));
      }(),
      DsButtonVariant.ghost => DsButtonStyle(
        background: _clear,
        foreground: iconOnly ? k.textMuted : k.link,
        hovered: DsButtonStyle(background: k.hover),
        pressed: DsButtonStyle(background: k.press),
      ),
      // In dark mode a deep red tint turns maroon or rust: the button is
      // neutral there and the red is in its label, as on iOS.
      DsButtonVariant.dangerSoft =>
        DsButtonStyle(
          background: theme.isDark ? k.control : k.danger.tint,
          foreground: k.danger.text,
        ).merge(
          theme.isDark
              ? shade(k.controlHover, k.controlPress)
              : shade(k.danger.tintHover, k.danger.tintPress),
        ),
      DsButtonVariant.danger => DsButtonStyle(
        background: k.danger.fill,
        foreground: k.danger.onFill,
        shadows: theme.shadows.danger,
      ).merge(shade(k.danger.fillHover, k.danger.fillPress)),
      // The ink under its inverse: near-black under white in light mode,
      // soft white under the page's ink in dark mode. A near-black fill
      // cannot darken and a near-white one should not glare, so hover and
      // press mix the label's tone into the fill instead (lighter in light
      // mode, dimmer in dark mode); the label stays above 7:1.
      // Flat, like the primary button.
      DsButtonVariant.neutral => () {
        final label = theme.isDark ? k.canvas : k.surface;
        Color mixed(double share) => DsOklch.mix(k.text, label, share);
        return DsButtonStyle(
          background: k.text,
          foreground: label,
        ).merge(shade(mixed(.08), mixed(.14)));
      }(),
      // The primary button turned inside out, for an accent ground: the
      // accent's label color as the fill, the accent as the label. Hover
      // and press mix a little accent into the fill while the label deepens
      // to the accent's own hover and press steps. The ring is in
      // the fill color: the theme's focus color is the accent's ink, which
      // vanishes on the accent. Disabled, it fades to a wash of the label
      // color with the label color on it, which still reads on the accent.
      DsButtonVariant.inverse => () {
        final [rest, hover, press] = _inverseFills(k);
        return DsButtonStyle(
          background: rest,
          foreground: k.accent,
          focusShadows: [
            for (final x in theme.focusShadows)
              x.isOutline ? x.copyWith(color: k.onAccent) : x,
          ],
          hovered: DsButtonStyle(background: hover, foreground: k.accentHover),
          pressed: DsButtonStyle(background: press, foreground: k.accentPress),
          disabled: DsButtonStyle(
            background: k.onAccent.withValues(alpha: .16),
            foreground: k.onAccent,
          ),
        );
      }(),
    };
    return base.merge(colors);
  }

  /// [tint] at each of [alphas] (rest, hover, press), all scaled down
  /// together as far as needed for [ink] to read at 4.5:1 on the strongest
  /// wash over each of [backdrops]. Every preset keeps the full wash; a
  /// pale brand color whose ink is close to it gets a lighter one.
  static List<Color> _washes(
    Color tint,
    List<double> alphas, {
    required Color ink,
    required List<Color> backdrops,
  }) {
    bool fits(double scale) => backdrops.every(
      (b) =>
          DsColorUtils.contrastRatio(
            ink,
            tint.withValues(alpha: alphas.last * scale),
            backdrop: b,
          ) >=
          4.5,
    );
    // More wash, less contrast: the largest scale that fits.
    final scale = _largestFit(fits);
    return [for (final a in alphas) tint.withValues(alpha: a * scale)];
  }

  /// The inverse button's fills at rest, hovered and pressed: the accent's
  /// label color ([DsColors.onAccent]), then mixed toward the accent, 6%
  /// and 12%, both scaled down together as far as needed for the deepening
  /// label ([DsColors.accentHover], [DsColors.accentPress]) to read as well
  /// as at rest: at least 4.5:1, and no less than at rest up to 7:1, so
  /// hover never weakens a label that needs the contrast.
  static List<Color> _inverseFills(DsColors k) {
    const shares = [.06, .12];
    final inks = [k.accentHover, k.accentPress];
    final rest = DsColorUtils.contrastRatio(k.accent, k.onAccent);
    final floor = math.max(4.5, math.min(rest, 7.0));
    Color fill(double share) => DsOklch.mix(k.onAccent, k.accent, share);
    bool fits(double scale) => [
      for (var i = 0; i < shares.length; i++)
        DsColorUtils.contrastRatio(inks[i], fill(shares[i] * scale)),
    ].every((r) => r >= floor);
    final scale = _largestFit(fits);
    return [k.onAccent, for (final s in shares) fill(s * scale)];
  }

  /// The largest scale in 0–1 for which [fits] holds, assuming smaller
  /// scales fit more easily; 0 when none does.
  static double _largestFit(bool Function(double scale) fits) {
    if (fits(1)) return 1;
    var low = 0.0, high = 1.0;
    for (var i = 0; i < 12; i++) {
      final mid = (low + high) / 2;
      if (fits(mid)) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low;
  }

  @override
  State<DsButton> createState() => _DsButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        FlagProperty(
          'enabled',
          value: onPressed != null || onLongPress != null,
          ifFalse: 'disabled',
        ),
      )
      ..add(EnumProperty('variant', variant, defaultValue: null))
      ..add(EnumProperty('size', size, defaultValue: null))
      ..add(FlagProperty('loading', value: loading, ifTrue: 'loading'))
      ..add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}

class _DsButtonState extends State<DsButton> {
  Set<WidgetState>? _lastStates;

  @override
  Widget build(BuildContext context) {
    final theme = dsThemeOf(context);
    final buttonTheme = DsButtonTheme.of(context);
    final variant =
        widget.variant ??
        (widget._iconOnly ? DsButtonVariant.ghost : buttonTheme.variant) ??
        DsButtonVariant.primary;
    final size = widget.size ?? buttonTheme.size ?? DsSize.md;
    final layers = [
      DsButton.defaultStyle(
        theme,
        variant: variant,
        size: size,
        iconOnly: widget._iconOnly,
      ),
      buttonTheme.style,
      buttonTheme.variants[variant],
      widget.style,
    ];
    // The spinner takes an icon's square, so swapping it in for an icon
    // never changes the width.
    final spinner = Builder(
      builder: (context) => SizedBox.square(
        dimension: IconTheme.of(context).size,
        child: Center(child: buttonTheme.loadingIndicator ?? const DsSpinner()),
      ),
    );
    final loading = widget.loading;

    return DsPressable(
      onPressed: widget.onPressed,
      onLongPress: widget.onLongPress,
      // Loading keeps focus and announces itself.
      busy: loading,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      statesController: widget.statesController,
      semanticLabel: widget.semanticLabel,
      expanded:
          widget.semanticExpanded ??
          DsAnchoredOverlay.triggerExpandedOf(context),
      mouseCursor: WidgetStateMouseCursor.resolveWith((states) {
        final s = DsButtonStyle.resolveLayers(layers, states);
        if (s.cursor != null) return s.cursor!;
        if (loading && !states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return DsPressable.defaultCursor.resolve(states);
      }),
      builder: (context, visual, _) {
        final s = DsButtonStyle.resolveLayers(layers, visual);
        // Animate only interaction changes. When the theme changes (for
        // example while it cross-fades to dark), follow it directly instead
        // of chasing a moving target.
        final animate = _lastStates != null && !setEquals(_lastStates, visual);
        _lastStates = visual;
        final motion = theme.motion;
        final duration = animate ? motion.toneDuration : Duration.zero;
        return _ButtonVisual(
          style: s,
          focused: visual.contains(WidgetState.focused),
          pressed: visual.contains(WidgetState.pressed),
          duration: duration,
          curve: motion.toneCurve,
          scaleSpring: motion.moveSpringOrNull,
          iconOnly: widget._iconOnly,
          leading: loading && widget.leading != null ? spinner : widget.leading,
          trailing: widget.trailing,
          child: switch ((loading, widget._iconOnly, widget.leading)) {
            // An icon button shows only the spinner while loading.
            (true, true, _) => spinner,
            // No icon to replace: the spinner covers the label, which keeps
            // its width (and its text for screen readers), so the button
            // does not grow and push its neighbors.
            (true, false, null) => Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0,
                  alwaysIncludeSemantics: true,
                  child: widget.child,
                ),
                spinner,
              ],
            ),
            _ => widget.child,
          },
        );
      },
    );
  }
}

class _ButtonVisual extends StatelessWidget {
  const _ButtonVisual({
    required this.style,
    required this.focused,
    required this.pressed,
    required this.duration,
    required this.curve,
    required this.scaleSpring,
    required this.iconOnly,
    required this.leading,
    required this.trailing,
    required this.child,
  });

  final DsButtonStyle style;
  final bool focused;
  final bool pressed;
  final Duration duration;
  final Curve curve;
  final DsSpring? scaleSpring;
  final bool iconOnly;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = style;
    final height = s.height!;
    final radius = DsTheme.radiiOf(context)
        .controlCorners(s.borderRadius, height);
    final foreground = s.foreground ?? DsTheme.colorsOf(context).text;
    final borderColor = s.borderColor ?? _clear;
    // The ring is always the first entry, transparent when there is no
    // edge, so state changes interpolate shadow for shadow instead of
    // shifting every pair by one. Transparent shadows are not
    // painted.
    final width = s.borderWidth!;
    final shadows = <DsShadow>[
      DsShadow.ring(width > 0 ? borderColor : _clear, width: width),
      ...?s.shadows,
    ];
    // The ring is drawn above the fill and the edge, so a tight ring
    // (DsShadows.focusTight) covers the border it replaces.
    final ring = DsBoxDecoration(
      borderRadius: radius,
      shadows: focused ? s.focusShadows ?? const [] : const [],
    );
    final iconSize = s.iconSize!;
    final gap = s.gap!;

    Widget content = iconOnly
        ? child
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, SizedBox(width: gap)],
              Flexible(child: child),
              if (trailing != null) ...[SizedBox(width: gap), trailing!],
            ],
          );

    content = TweenAnimationBuilder<Color?>(
      tween: DsColorTween(end: foreground),
      duration: duration,
      curve: curve,
      child: content,
      builder: (context, color, child) => IconTheme.merge(
        data: IconThemeData(color: color, size: iconSize),
        child: DefaultTextStyle(
          style: (s.textStyle ?? const TextStyle()).copyWith(color: color),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          child: child!,
        ),
      ),
    );

    Widget box = AnimatedContainer(
      duration: duration,
      curve: curve,
      constraints: BoxConstraints(
        minHeight: height,
        minWidth: iconOnly ? height : 0,
      ),
      padding: s.padding,
      decoration: DsBoxDecoration(
        color: s.background,
        borderRadius: radius,
        shadows: shadows,
      ),
      foregroundDecoration: ring,
      // Shrink-wrap under loose constraints, fill and center under tight
      // ones (e.g. a full-width button).
      child: Align(widthFactor: 1, heightFactor: 1, child: content),
    );

    final scale = DsPressEffect.scaleOf(context, s.pressScale!);
    if (scale != 1) {
      // A quick tap-and-release keeps its velocity: the press flows into
      // the release bounce instead of restarting.
      box = DsSpringValue(
        value: pressed ? scale : 1,
        spring: scaleSpring,
        builder: (context, v, child) => Transform.scale(scale: v, child: child),
        child: box,
      );
    }

    return box;
  }
}
