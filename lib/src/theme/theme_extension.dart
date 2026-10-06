import 'package:flutter/foundation.dart';

import 'theme_data.dart';

/// An app's own tokens, carried on a [DsThemeData] next to Desen's.
///
/// Subclass it to bundle what the app needs beyond the built-in token
/// groups (a brand gradient, chart colors, a heat ramp), attach instances
/// with `DsThemeData(extensions: […])` and read them back with
/// [DsThemeData.extension] or `DsTheme.extensionOf<T>(context)`. Desen's
/// own components never read extensions.
///
/// [T] is the subclass itself; it is also the key the extension is stored
/// and looked up under ([type]), so a theme holds one extension per type.
///
/// **Animated theme changes.** `DsAnimatedTheme` and `DsThemeData.lerp`
/// interpolate an extension with [lerp], so its values move with the rest
/// of the theme.
///
/// **Following the theme.** Override [resolve] to derive values from the
/// theme the extension lands in: its mode, contrast, density or tokens.
/// The theme calls it when the extension is attached and again whenever the
/// theme regenerates (a switch to dark mode, a contrast or density change),
/// always on the extension it holds, which is the result of the previous
/// [resolve]. So keep what you resolve from on the extension, for example
/// both mode values next to the one in use:
///
/// ```dart
/// @immutable
/// class Brand extends DsThemeExtension<Brand> {
///   const Brand({required this.lightGlow, required this.darkGlow, Color? glow})
///     : glow = glow ?? lightGlow;
///
///   final Color lightGlow, darkGlow;
///
///   /// The glow for the current mode.
///   final Color glow;
///
///   @override
///   Brand resolve(DsThemeData theme) =>
///       copyWith(glow: theme.isDark ? darkGlow : lightGlow);
///
///   @override
///   Brand copyWith({Color? glow}) =>
///       Brand(lightGlow: lightGlow, darkGlow: darkGlow, glow: glow ?? this.glow);
///
///   @override
///   Brand lerp(Brand? other, double t) => other == null
///       ? this
///       : Brand(
///           lightGlow: other.lightGlow,
///           darkGlow: other.darkGlow,
///           glow: Color.lerp(glow, other.glow, t),
///         );
///
///   @override
///   bool operator ==(Object other) =>
///       other is Brand &&
///       other.lightGlow == lightGlow &&
///       other.darkGlow == darkGlow &&
///       other.glow == glow;
///
///   @override
///   int get hashCode => Object.hash(lightGlow, darkGlow, glow);
/// }
///
/// // DsThemeData(extensions: [Brand(lightGlow: a, darkGlow: b)])
/// // DsTheme.extensionOf<Brand>(context)!.glow
/// ```
///
/// Themes compare their extensions, so implement `==` and `hashCode`:
/// without them every rebuilt theme counts as a change.
@immutable
abstract class DsThemeExtension<T extends DsThemeExtension<T>> {
  /// Const constructor for subclasses.
  const DsThemeExtension();

  /// The key the extension is stored and looked up under: [T].
  Object get type => T;

  /// Returns a copy with the given values replaced. Subclasses add the
  /// fields they hold as optional named parameters.
  T copyWith();

  /// Interpolates between this extension and [other], for animated theme
  /// changes: at 0 this, at 1 [other]. [other] is null when the theme being
  /// animated to has no extension of this type; returning this keeps the
  /// values until the switch.
  T lerp(covariant T? other, double t);

  /// This extension as it applies to [theme]. By default unchanged.
  ///
  /// Called when the extension is attached to a theme and again on the
  /// result whenever that theme regenerates its tokens, so derive the
  /// result from [theme] and values the extension keeps (see the class
  /// docs). [theme] has every setting and token, and the extensions as
  /// they were before this call.
  T resolve(DsThemeData theme) => this as T;
}
