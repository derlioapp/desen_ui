import 'dart:ui' show Brightness, lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/color_utils.dart';
import '../../foundation/oklch.dart';
import '../../painting/shadow.dart';

/// The visual style of a `DsButton`. Every field is optional.
///
/// ## How styles combine
///
/// A button's final style is built from layers, weakest first:
///
/// 1. Desen's defaults for the variant and size
/// 2. `DsButtonTheme.style` (all variants)
/// 3. `DsButtonTheme.variants[variant]`
/// 4. The button's own `style:`
///
/// Each layer is first resolved for the button's current states (see
/// [resolve]), then laid over the layers below it. So a `background` you set
/// on a button wins over Desen's hover color too: give a [hovered] style when
/// you want hover feedback in your own color, or use [DsButtonStyle.solid],
/// which derives it for you.
///
/// ## State styles
///
/// [hovered], [focused], [pressed] and [disabled] are partial styles laid
/// over the base when that state is active, like CSS `:hover` blocks. When
/// several apply, they stack in a fixed order regardless of how they were
/// written: focused, then hovered, then pressed, then disabled.
///
/// ## Removing a value
///
/// `null` means "not specified, keep the layer below". To remove something,
/// pass an empty value: `shadows: const []`, `borderColor:
/// Color(0x00000000)`.
@immutable
class DsButtonStyle with Diagnosticable {
  /// Creates a style.
  const DsButtonStyle({
    this.background,
    this.foreground,
    this.borderColor,
    this.borderWidth,
    this.shadows,
    this.focusShadows,
    this.borderRadius,
    this.height,
    this.padding,
    this.gap,
    this.iconSize,
    this.textStyle,
    this.cursor,
    this.pressScale,
    this.hovered,
    this.focused,
    this.pressed,
    this.disabled,
  });

  /// A filled style from one color, with hover and pressed shades derived in
  /// OKLCH: 0.05 and 0.08 lightness steps, darker in light themes and
  /// lighter in dark ones, the way Desen's own accent behaves.
  ///
  /// ```dart
  /// DsButton(
  ///   style: DsButtonStyle.solid(
  ///     background: brand,
  ///     foreground: white,
  ///     brightness: DsTheme.of(context).brightness,
  ///   ),
  ///   …
  /// )
  /// ```
  factory DsButtonStyle.solid({
    required Color background,
    required Color foreground,
    Brightness brightness = Brightness.light,
  }) {
    final base = DsOklch.fromColor(background);
    double step(double d) => brightness == Brightness.dark ? d : -d;
    Color shade(double d) =>
        base.copyWith(l: (base.l + step(d)).clamp(0.0, 1.0)).toColor();
    return DsButtonStyle(
      background: background,
      foreground: foreground,
      shadows: const [],
      borderColor: const Color(0x00000000),
      hovered: DsButtonStyle(background: shade(.05)),
      pressed: DsButtonStyle(background: shade(.08)),
    );
  }

  /// Fill color.
  final Color? background;

  /// Label and icon color.
  final Color? foreground;

  /// A crisp ring around the button. Drawn outside the box, so it never
  /// shifts layout.
  final Color? borderColor;

  /// Width of the [borderColor] ring.
  final double? borderWidth;

  /// Drop shadows and highlights, drawn under the border ring.
  final List<DsShadow>? shadows;

  /// Added while focused from the keyboard: the focus ring, drawn above
  /// the fill and the border. Filled variants take the gapped
  /// `DsShadows.focusOffset`; the secondary button the tight
  /// `DsShadows.focusTight`, which covers its border.
  final List<DsShadow>? focusShadows;

  /// Corner radii. When no layer sets them, the button is rounded by the
  /// corner rule at its [height] (`DsRadii.controlCorners`), so a style
  /// that changes only the height keeps the corners in proportion.
  final BorderRadiusGeometry? borderRadius;

  /// Minimum height. The button grows with large text.
  final double? height;

  /// Inner padding. An icon-only button (`DsButton.icon`) takes it only from
  /// its own `style`, never from a theme, so it stays square.
  final EdgeInsetsGeometry? padding;

  /// Space between icon and label.
  final double? gap;

  /// Size of icons in the leading and trailing slots.
  final double? iconSize;

  /// Label text style, merged onto the layer below.
  final TextStyle? textStyle;

  /// Mouse cursor.
  final MouseCursor? cursor;

  /// Scale while pressed; 1 disables the press animation. A `DsPressEffect`
  /// scope above the button can turn it off for a whole subtree.
  final double? pressScale;

  /// Laid over the base while a mouse hovers.
  final DsButtonStyle? hovered;

  /// Laid over the base while focused from the keyboard.
  final DsButtonStyle? focused;

  /// Laid over the base while pressed.
  final DsButtonStyle? pressed;

  /// Laid over the base while disabled.
  final DsButtonStyle? disabled;

  /// Lays [other] over this style: fields set in [other] win; state styles
  /// merge recursively; text styles merge.
  DsButtonStyle merge(DsButtonStyle? other) {
    if (other == null) return this;
    return DsButtonStyle(
      background: other.background ?? background,
      foreground: other.foreground ?? foreground,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      shadows: other.shadows ?? shadows,
      focusShadows: other.focusShadows ?? focusShadows,
      borderRadius: other.borderRadius ?? borderRadius,
      height: other.height ?? height,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      iconSize: other.iconSize ?? iconSize,
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      cursor: other.cursor ?? cursor,
      pressScale: other.pressScale ?? pressScale,
      hovered: _mergeNullable(hovered, other.hovered),
      focused: _mergeNullable(focused, other.focused),
      pressed: _mergeNullable(pressed, other.pressed),
      disabled: _mergeNullable(disabled, other.disabled),
    );
  }

  static DsButtonStyle? _mergeNullable(DsButtonStyle? a, DsButtonStyle? b) =>
      a == null ? b : a.merge(b);

  /// This style flattened for [states]: the base with every matching state
  /// style laid over it, in the fixed order focused, hovered, pressed,
  /// disabled. The result has no state styles.
  DsButtonStyle resolve(Set<WidgetState> states) {
    var s = _base;
    if (states.contains(WidgetState.focused)) s = s.merge(focused?._base);
    if (states.contains(WidgetState.hovered)) s = s.merge(hovered?._base);
    if (states.contains(WidgetState.pressed)) s = s.merge(pressed?._base);
    if (states.contains(WidgetState.disabled)) s = s.merge(disabled?._base);
    return s;
  }

  /// Resolves each layer for [states] and lays them over each other, weakest
  /// first.
  static DsButtonStyle resolveLayers(
    Iterable<DsButtonStyle?> layers,
    Set<WidgetState> states,
  ) {
    var result = const DsButtonStyle();
    for (final layer in layers) {
      if (layer != null) result = result.merge(layer.resolve(states));
    }
    return result;
  }

  DsButtonStyle get _base =>
      hovered == null && focused == null && pressed == null && disabled == null
      ? this
      : DsButtonStyle(
          background: background,
          foreground: foreground,
          borderColor: borderColor,
          borderWidth: borderWidth,
          shadows: shadows,
          focusShadows: focusShadows,
          borderRadius: borderRadius,
          height: height,
          padding: padding,
          gap: gap,
          iconSize: iconSize,
          textStyle: textStyle,
          cursor: cursor,
          pressScale: pressScale,
        );

  /// Interpolates two flat styles, e.g. for an animated custom theme.
  /// Colors blend in premultiplied alpha ([DsColorUtils.lerp]), so a
  /// transparent end fades without a gray flash; shadows and sizes blend;
  /// discrete values switch at the midpoint. State styles are dropped.
  static DsButtonStyle lerp(DsButtonStyle a, DsButtonStyle b, double t) {
    if (identical(a, b)) return a;
    final p = t < 0.5 ? a : b;
    return DsButtonStyle(
      background: DsColorUtils.lerp(a.background, b.background, t),
      foreground: DsColorUtils.lerp(a.foreground, b.foreground, t),
      borderColor: DsColorUtils.lerp(a.borderColor, b.borderColor, t),
      borderWidth: lerpDouble(a.borderWidth, b.borderWidth, t),
      shadows: a.shadows == null || b.shadows == null
          ? p.shadows
          : DsShadow.lerpList(a.shadows!, b.shadows!, t),
      focusShadows: p.focusShadows,
      borderRadius: BorderRadiusGeometry.lerp(
        a.borderRadius,
        b.borderRadius,
        t,
      ),
      height: lerpDouble(a.height, b.height, t),
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t),
      gap: lerpDouble(a.gap, b.gap, t),
      iconSize: lerpDouble(a.iconSize, b.iconSize, t),
      textStyle: TextStyle.lerp(a.textStyle, b.textStyle, t),
      cursor: p.cursor,
      pressScale: lerpDouble(a.pressScale, b.pressScale, t),
    );
  }

  List<Object?> get _fields => [
    background, foreground, borderColor, borderWidth, shadows, focusShadows, //
    borderRadius, height, padding, gap, iconSize, textStyle, cursor,
    pressScale, hovered, focused, pressed, disabled,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DsButtonStyle) return false;
    final a = _fields, b = other._fields;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x is List && y is List ? !listEquals(x, y) : x != y) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll(_fields.map((f) => f is List ? Object.hashAll(f) : f));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('background', background, defaultValue: null))
      ..add(ColorProperty('foreground', foreground, defaultValue: null))
      ..add(ColorProperty('borderColor', borderColor, defaultValue: null))
      ..add(DoubleProperty('height', height, defaultValue: null))
      ..add(DiagnosticsProperty('padding', padding, defaultValue: null))
      ..add(DiagnosticsProperty('hovered', hovered, defaultValue: null))
      ..add(DiagnosticsProperty('pressed', pressed, defaultValue: null))
      ..add(DiagnosticsProperty('disabled', disabled, defaultValue: null));
  }
}
