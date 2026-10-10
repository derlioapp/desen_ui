import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/component_theme.dart';
import '../../theme/sizes.dart';
import 'button_style.dart';

/// The visual variants of a `DsButton`.
enum DsButtonVariant {
  /// Filled with the accent. One per view, for the main action.
  primary,

  /// Raised neutral control with an edge. The everyday button.
  secondary,

  /// Accent ink on a light wash of the accent, with no edge: lighter than
  /// [primary], warmer than [secondary]. For an action that should stand
  /// out without being the main one, or for several equal actions in a
  /// row.
  tinted,

  /// No fill until hovered. Text buttons use the link color; icon buttons
  /// use muted ink.
  ghost,

  /// Soft danger tint, for destructive actions in lists and toolbars.
  dangerSoft,

  /// Filled danger, reserved for confirming a destructive action in a
  /// dialog.
  danger,

  /// Filled with the ink: near-black under a white label in light mode,
  /// soft white under a dark label in dark mode, like the dark default
  /// button of iOS and Vercel. The same emphasis as [primary] without the
  /// brand color, for a design that keeps the accent for links, marks and
  /// selection.
  neutral,

  /// For an accent-filled ground (a hero band, an accent card), where
  /// [primary] would vanish into its own color: filled with the accent's
  /// label color (white, or the dark ink of a bright accent) under an
  /// accent label. Its focus ring is drawn in the same label color, so it
  /// shows on the accent.
  inverse,
}

/// Button defaults for a subtree; see [DsButtonTheme].
class DsButtonThemeData extends DsComponentThemeData<DsButtonThemeData> {
  /// Creates button defaults.
  const DsButtonThemeData({
    this.variant,
    this.size,
    this.style,
    this.variants = const {},
    this.loadingIndicator,
  });

  /// Variant for text buttons that do not set one.
  final DsButtonVariant? variant;

  /// Size for buttons that do not set one.
  final DsSize? size;

  /// Style laid over Desen's defaults for every variant.
  final DsButtonStyle? style;

  /// Styles laid over [style] for one variant each.
  ///
  /// The variants are a fixed set. A variant of the app's own (a main call
  /// to action) is a [DsButtonStyle] kept in one place and passed as
  /// `DsButton.style`.
  final Map<DsButtonVariant, DsButtonStyle> variants;

  /// Replaces the default `DsSpinner` shown while a button is loading. It
  /// inherits the button's icon color and size through [IconTheme].
  final Widget? loadingIndicator;

  /// Lays [other] over this: its values win, styles merge.
  @override
  DsButtonThemeData merge(DsButtonThemeData? other) {
    if (other == null) return this;
    return DsButtonThemeData(
      variant: other.variant ?? variant,
      size: other.size ?? size,
      style: style?.merge(other.style) ?? other.style,
      variants: {
        for (final v in {...variants.keys, ...other.variants.keys})
          v: variants[v]?.merge(other.variants[v]) ?? other.variants[v]!,
      },
      loadingIndicator: other.loadingIndicator ?? loadingIndicator,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DsButtonThemeData &&
      other.variant == variant &&
      other.size == size &&
      other.style == style &&
      mapEquals(other.variants, variants) &&
      other.loadingIndicator == loadingIndicator;

  @override
  int get hashCode => Object.hash(
    variant,
    size,
    style,
    loadingIndicator,
    Object.hashAllUnordered(
      variants.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty('variant', variant, defaultValue: null))
      ..add(EnumProperty('size', size, defaultValue: null))
      ..add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}

/// Sets button defaults for a subtree.
///
/// Nested button themes merge: an inner theme only overrides what it sets.
/// Put one above your app for global defaults, or around a section to
/// change only that section.
class DsButtonTheme extends DsComponentTheme<DsButtonThemeData> {
  /// Applies [data] to buttons in [child], merged over any outer theme.
  const DsButtonTheme({super.key, required super.data, required super.child});

  /// The merged button theme for [context]; empty when there is none.
  static DsButtonThemeData of(BuildContext context) =>
      DsComponentTheme.maybeOf<DsButtonThemeData>(context) ??
      const DsButtonThemeData();
}
