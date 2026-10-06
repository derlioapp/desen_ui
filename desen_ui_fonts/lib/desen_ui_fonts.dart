/// The typefaces of Desen UI, as a separate package so apps that bring
/// their own fonts carry no extra weight.
///
/// Adding this package is all that is needed: `DsTypography`'s defaults
/// already point at these families.
library;

/// Family and package names, for use outside Desen's own text styles.
abstract final class DsFonts {
  /// The package that bundles the fonts.
  static const package = 'desen_ui_fonts';

  /// Text family: Schibsted Grotesk, weights 400–800.
  static const text = 'SchibstedGrotesk';

  /// Code family: Geist Mono, weights 400–600, for code-like content only.
  /// Numbers are set in [text] with tabular figures.
  static const mono = 'GeistMono';
}
