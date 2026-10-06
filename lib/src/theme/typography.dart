import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'sizes.dart';

/// Builds a text style the way CSS would lay it out.
///
/// - [tracking] is in em, like CSS `letter-spacing`, and is converted to
///   pixels for [size].
/// - [height] is a unitless multiplier, like CSS `line-height`. Leading is
///   split evenly above and below the glyphs (CSS half-leading) instead of
///   Flutter's default proportional split, so text sits where it does in a
///   browser. Null means the font's natural line height (CSS `normal`).
TextStyle dsTextStyle({
  required String family,
  required double size,
  FontWeight weight = FontWeight.w400,
  double tracking = 0,
  double? height,
  String? package,
  List<FontFeature>? features,
}) => TextStyle(
  inherit: true,
  fontFamily: family,
  package: package,
  fontSize: size,
  fontWeight: weight,
  letterSpacing: tracking * size,
  height: height,
  leadingDistribution: TextLeadingDistribution.even,
  fontFeatures: features,
);

/// The type scale.
///
/// Two ramps, one per [DsDensity]:
///
/// - [DsDensity.compact], for pointer screens: 11 · 12 · 13 · 14 · 16 ·
///   22 · 30, body text 14 on a 21px line.
/// - [DsDensity.touch], for phones and touch-first apps: 12 · 13 · 15 ·
///   16 · 18 · 24 · 34, body text 16 on a 22px line. Every role steps up,
///   so the hierarchy reads the same.
///
/// Weights: 400 · 500 · 600, with 700 for page titles. Numbers use the
/// text family with tabular figures ([numeric]); the mono family ([mono])
/// is only for code-like content. Page and component titles ([display],
/// [title]) use the display family, the text family unless one is given.
///
/// A theme (`DsThemeData`) hands its typography the theme's density with
/// [forDensity], so the scale follows the end user's density setting.
///
/// Styles carry no color; components apply color from `DsColors`.
@immutable
class DsTypography {
  /// Creates a type scale with every role given explicitly.
  ///
  /// Building one by hand is meant for tests and tools. It is not covered
  /// by the compatibility promise: later versions may add roles. To
  /// customize type, start from [DsTypography.new] (fonts) and use
  /// [copyWith].
  const DsTypography.raw({
    required this.family,
    required this.package,
    required this.monoFamily,
    required this.monoPackage,
    required this.displayFamily,
    required this.displayPackage,
    required this.density,
    required this.display,
    required this.title,
    required this.heading,
    required this.body,
    required this.bodyStrong,
    required this.small,
    required this.label,
    required this.labelStrong,
    required this.caption,
    required this.fieldLabel,
    required this.overline,
  });

  /// The default scale for [density].
  ///
  /// **Text family.** Without a [family], text is set in the platform's
  /// face where it has a designed one, and in Schibsted Grotesk elsewhere:
  ///
  /// - In iOS and macOS apps (not on the web), the system font, San
  ///   Francisco ([systemFamily]; titles in its display cut,
  ///   [systemDisplayFamily]), with Apple's size-specific tracking.
  /// - Everywhere else (the web, Android, Windows, Linux), Schibsted
  ///   Grotesk, with [package].
  ///
  /// A [family] given here is used on every platform, Apple's included.
  ///
  /// **Fonts.** Schibsted Grotesk and the default [monoFamily], Geist
  /// Mono, ship in the optional `desen_ui_fonts` package, which this
  /// package deliberately does not depend on: add it to your app to get
  /// them. Without it, Flutter cannot find the family and text falls back
  /// to the platform font, silently; the small tracking values (−0.02 to
  /// +0.08 em) suit system fonts too.
  ///
  /// Pass other [family] / [monoFamily] names to use your own fonts, with
  /// [package] / [monoPackage] set to the package that bundles each, or
  /// null for fonts declared in your app. The `desen_ui_fonts` package
  /// (the default of both) only applies to the two faces it bundles: a
  /// family of your own with the default package, e.g.
  /// `DsTypography(family: 'Inter')`, is looked up in your app, as
  /// `'Inter'`, not in `desen_ui_fonts`.
  ///
  /// **Display family.** [displayFamily] (with [displayPackage], null for
  /// app fonts) sets [display] and [title] in another face, e.g. a serif
  /// for headings. Without it they use the text family.
  factory DsTypography({
    String? family,
    String monoFamily = _bundledMonoFamily,
    String? package = fontsPackage,
    String? monoPackage = fontsPackage,
    String? displayFamily,
    String? displayPackage,
    DsDensity density = DsDensity.compact,
  }) {
    final system = family == null && _appleApp;
    final text = system ? systemFamily : family ?? _bundledFamily;
    final textPackage = system ? null : _packageOf(text, package);
    return _build(
      family: text,
      package: textPackage,
      monoFamily: monoFamily,
      monoPackage: _packageOf(monoFamily, monoPackage),
      displayFamily: displayFamily ?? (system ? systemDisplayFamily : text),
      displayPackage: displayFamily != null ? displayPackage : textPackage,
      density: density,
    );
  }

  /// The family name Flutter maps to Apple's system text font (SF Pro
  /// Text) in iOS and macOS apps. On other platforms it falls back to the
  /// platform's default font.
  ///
  /// Flutter applies no tracking of its own to it, so the scale sets
  /// Apple's published tracking for each size.
  static const systemFamily = 'CupertinoSystemText';

  /// The family name Flutter maps to the display cut of Apple's system
  /// font (SF Pro Display) in iOS and macOS apps, meant for 20px and up.
  /// The default display family wherever [systemFamily] is the text
  /// family.
  static const systemDisplayFamily = 'CupertinoSystemDisplay';

  /// The optional package that bundles Desen's faces, Schibsted Grotesk
  /// and Geist Mono.
  static const fontsPackage = 'desen_ui_fonts';

  static const _bundledFamily = 'SchibstedGrotesk';
  static const _bundledMonoFamily = 'GeistMono';

  /// The package to look [family] up in: [package], except that
  /// [fontsPackage] only holds the faces it bundles. Another family with it
  /// is an app font.
  static String? _packageOf(String family, String? package) =>
      package == fontsPackage &&
          family != _bundledFamily &&
          family != _bundledMonoFamily
      ? null
      : package;

  /// Whether this is an iOS or macOS app, where the system font is San
  /// Francisco. Not on the web: a browser on a Mac draws the bundled
  /// face, as the rest of the web does.
  static bool get _appleApp =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// The roles for [density] in the given fonts.
  static DsTypography _build({
    required String family,
    required String? package,
    required String monoFamily,
    required String? monoPackage,
    required String displayFamily,
    required String? displayPackage,
    required DsDensity density,
  }) {
    // A role: size, weight, tracking (em) and line height (a multiplier,
    // or px / size where the line is set in pixels).
    TextStyle s(
      double size, [
      FontWeight weight = FontWeight.w400,
      double tracking = 0,
      double? height,
      bool display = false,
    ]) {
      final face = display ? displayFamily : family;
      return dsTextStyle(
        family: face,
        package: display ? displayPackage : package,
        size: size,
        weight: weight,
        tracking: _isSystem(face) ? _appleTracking(size) : tracking,
        height: height,
      );
    }

    // The uppercase overline keeps its wide spacing in any face: it is
    // part of the style, not an optical correction.
    TextStyle overline(double size) => dsTextStyle(
      family: family,
      package: package,
      size: size,
      weight: FontWeight.w600,
      tracking: 0.08,
    );

    final touch = density == DsDensity.touch;
    return DsTypography.raw(
      family: family,
      package: package,
      monoFamily: monoFamily,
      monoPackage: monoPackage,
      displayFamily: displayFamily,
      displayPackage: displayPackage,
      density: density,
      display: s(touch ? 34 : 30, FontWeight.w700, -0.02, 1.1, true),
      title: s(touch ? 24 : 22, FontWeight.w600, -0.02, 1.2, true),
      heading: s(touch ? 18 : 16, FontWeight.w600, -0.01),
      body: touch
          ? s(16, FontWeight.w400, 0, 22 / 16)
          : s(14, FontWeight.w400, 0, 1.5),
      bodyStrong: s(touch ? 16 : 14, FontWeight.w600),
      small: touch
          ? s(15, FontWeight.w400, 0, 20 / 15)
          : s(13, FontWeight.w400, 0, 1.45),
      label: s(touch ? 15 : 13, FontWeight.w500),
      labelStrong: s(touch ? 15 : 13, FontWeight.w600),
      caption: touch
          ? s(13, FontWeight.w400, 0, 18 / 13)
          : s(12, FontWeight.w400, 0, 1.45),
      fieldLabel: s(touch ? 13 : 12, FontWeight.w600),
      overline: overline(touch ? 12 : 11),
    );
  }

  static bool _isSystem(String? family) =>
      family == systemFamily || family == systemDisplayFamily;

  /// Apple's tracking for San Francisco at [size], in em (Human Interface
  /// Guidelines, "Tracking values"): looser below 12px, tighter from 13 to
  /// 23, looser again in the display cut. Interpolated between sizes and
  /// held beyond the table.
  static double _appleTracking(double size) {
    const first = 9;
    // Thousandths of an em for 9px, 10px, … 36px.
    const table = [
      19, 12, 6, 0, -6, -11, -16, -20, -26, -25, -24, -23, -18, -12, -4, //
      3, 6, 8, 11, 14, 14, 14, 13, 13, 12, 12, 11, 10,
    ];
    final at = (size - first).clamp(0, table.length - 1).toDouble();
    final i = at.floor();
    final next = (i + 1).clamp(0, table.length - 1);
    return lerpDouble(table[i], table[next], at - i)! / 1000;
  }

  /// Text family.
  final String family;

  /// The package bundling [family], or null for app and system fonts.
  final String? package;

  /// Code family, for code-like content only ([mono]); numbers stay in
  /// [family] ([numeric]).
  final String monoFamily;

  /// The package bundling [monoFamily], or null for app fonts.
  final String? monoPackage;

  /// The family of [display] and [title]: [family] unless another was
  /// given.
  final String displayFamily;

  /// The package bundling [displayFamily], or null for app and system
  /// fonts.
  final String? displayPackage;

  /// The density this scale is set for. See [forDensity].
  final DsDensity density;

  /// Page title: 30 / 700 / −0.02em (touch: 34), display family.
  final TextStyle display;

  /// Component title (card, dialog, empty state): 22 / 600 / −0.02em
  /// (touch: 24), display family.
  final TextStyle title;

  /// Section and card header: 16 / 600 / −0.01em (touch: 18).
  final TextStyle heading;

  /// Body text: 14 / 400, line height 1.5 (touch: 16 on a 22px line).
  final TextStyle body;

  /// Emphasized body, medium button labels: 14 / 600 (touch: 16).
  final TextStyle bodyStrong;

  /// Secondary body, descriptions: 13 / 400, line height 1.45 (touch: 15
  /// on a 20px line).
  final TextStyle small;

  /// Control labels, menu rows: 13 / 500 (touch: 15).
  final TextStyle label;

  /// Emphasized labels: 13 / 600 (touch: 15).
  final TextStyle labelStrong;

  /// Help text and meta: 12 / 400, line height 1.45 (touch: 13 on an 18px
  /// line).
  final TextStyle caption;

  /// Field label above an input: 12 / 600 (touch: 13).
  final TextStyle fieldLabel;

  /// Section header in a sidebar: 11 / 600 / +0.08em (touch: 12), shown
  /// uppercase.
  final TextStyle overline;

  /// The label of a control of [size], weight 600: [fieldLabel],
  /// [labelStrong], [bodyStrong], and for [DsSize.lg] [bodyStrong] at
  /// [heading]'s size. That is 12 · 13 · 14 · 16 compact and 13 · 15 · 16
  /// · 18 touch.
  TextStyle controlLabel(DsSize size) => switch (size) {
    DsSize.xs => fieldLabel,
    DsSize.sm => labelStrong,
    DsSize.md => bodyStrong,
    DsSize.lg => _resized(bodyStrong, heading.fontSize ?? 0),
  };

  /// [style] at [size], its tracking kept in em (for the system font,
  /// Apple's tracking at the new size).
  TextStyle _resized(TextStyle style, double size) {
    final from = style.fontSize;
    if (from == null || from == 0) return style.copyWith(fontSize: size);
    final em = _isSystem(_familyOf(style))
        ? _appleTracking(size)
        : (style.letterSpacing ?? 0) / from;
    return style.copyWith(fontSize: size, letterSpacing: em * size);
  }

  /// [style]'s family without a package prefix.
  static String? _familyOf(TextStyle style) =>
      style.fontFamily?.split('/').last;

  /// [style] with tabular figures (OpenType `tnum`), in the text family,
  /// or in the display family when [style] is set in it: for figures that
  /// stack in a column or change in place (table figures, calendar days,
  /// time columns, counters, pagination, progress values). Every digit
  /// takes the same width, so columns align and a changing value does not
  /// shift, while the figures keep the face of the surrounding text.
  ///
  /// In Schibsted Grotesk `tnum` also widens `.`, `,`, `:` and `/` to a
  /// digit's width, so "12.480,00" would read like a typewriter. Desen's
  /// components therefore keep the figures tabular on the digits only and
  /// set the separators between them with the face's own spacing; the
  /// digits still line up. Not for text people type or read inline (a date
  /// or amount in a field, a file size), which stays proportional.
  TextStyle numeric(TextStyle style) {
    final inDisplay =
        displayFamily != family &&
        style.fontFamily == _qualified(displayFamily, displayPackage);
    return style.copyWith(
      fontFamily: inDisplay ? displayFamily : family,
      package: inDisplay ? displayPackage : package,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static String _qualified(String family, String? package) =>
      package == null ? family : 'packages/$package/$family';

  /// [style] in the mono family with tabular figures, for code-like
  /// content only: code, and keycaps such as a search field's "⌘K" hint.
  ///
  /// Not for numbers: use [numeric]. A mono face makes dates, amounts and
  /// counters read like a console, and its slashed zero like "Ø"
  /// (decision 1).
  TextStyle mono(TextStyle style) => style.copyWith(
    fontFamily: monoFamily,
    package: monoPackage,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// This scale for [density], in the same fonts.
  ///
  /// Roles still as generated for [DsTypography.density] take [density]'s
  /// values; roles replaced with [copyWith] keep what was set, at every
  /// density. A theme calls this with its own density, so to give a role
  /// different values per density, build the theme's typography for the
  /// density it is given.
  DsTypography forDensity(DsDensity density) {
    if (density == this.density) return this;
    DsTypography at(DsDensity d) => _build(
      family: family,
      package: package,
      monoFamily: monoFamily,
      monoPackage: monoPackage,
      displayFamily: displayFamily,
      displayPackage: displayPackage,
      density: d,
    );
    final from = at(this.density);
    final to = at(density);
    TextStyle pick(TextStyle mine, TextStyle generated, TextStyle next) =>
        mine == generated ? next : mine;
    return DsTypography.raw(
      family: family,
      package: package,
      monoFamily: monoFamily,
      monoPackage: monoPackage,
      displayFamily: displayFamily,
      displayPackage: displayPackage,
      density: density,
      display: pick(display, from.display, to.display),
      title: pick(title, from.title, to.title),
      heading: pick(heading, from.heading, to.heading),
      body: pick(body, from.body, to.body),
      bodyStrong: pick(bodyStrong, from.bodyStrong, to.bodyStrong),
      small: pick(small, from.small, to.small),
      label: pick(label, from.label, to.label),
      labelStrong: pick(labelStrong, from.labelStrong, to.labelStrong),
      caption: pick(caption, from.caption, to.caption),
      fieldLabel: pick(fieldLabel, from.fieldLabel, to.fieldLabel),
      overline: pick(overline, from.overline, to.overline),
    );
  }

  /// Returns a copy with the given roles replaced.
  DsTypography copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? heading,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? small,
    TextStyle? label,
    TextStyle? labelStrong,
    TextStyle? caption,
    TextStyle? fieldLabel,
    TextStyle? overline,
  }) => DsTypography.raw(
    family: family,
    package: package,
    monoFamily: monoFamily,
    monoPackage: monoPackage,
    displayFamily: displayFamily,
    displayPackage: displayPackage,
    density: density,
    display: display ?? this.display,
    title: title ?? this.title,
    heading: heading ?? this.heading,
    body: body ?? this.body,
    bodyStrong: bodyStrong ?? this.bodyStrong,
    small: small ?? this.small,
    label: label ?? this.label,
    labelStrong: labelStrong ?? this.labelStrong,
    caption: caption ?? this.caption,
    fieldLabel: fieldLabel ?? this.fieldLabel,
    overline: overline ?? this.overline,
  );

  /// Linearly interpolates between two scales. Fonts and density switch at
  /// the midpoint.
  static DsTypography lerp(DsTypography a, DsTypography b, double t) {
    if (identical(a, b)) return a;
    TextStyle l(TextStyle x, TextStyle y) => TextStyle.lerp(x, y, t)!;
    final pick = t < 0.5 ? a : b;
    return DsTypography.raw(
      family: pick.family,
      package: pick.package,
      monoFamily: pick.monoFamily,
      monoPackage: pick.monoPackage,
      displayFamily: pick.displayFamily,
      displayPackage: pick.displayPackage,
      density: pick.density,
      display: l(a.display, b.display),
      title: l(a.title, b.title),
      heading: l(a.heading, b.heading),
      body: l(a.body, b.body),
      bodyStrong: l(a.bodyStrong, b.bodyStrong),
      small: l(a.small, b.small),
      label: l(a.label, b.label),
      labelStrong: l(a.labelStrong, b.labelStrong),
      caption: l(a.caption, b.caption),
      fieldLabel: l(a.fieldLabel, b.fieldLabel),
      overline: l(a.overline, b.overline),
    );
  }

  List<Object?> get _all => [
    family, package, monoFamily, monoPackage, displayFamily, //
    displayPackage, density, display, title, heading, body, bodyStrong, //
    small, label, labelStrong, caption, fieldLabel, overline,
  ];

  @override
  bool operator ==(Object other) =>
      other is DsTypography && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);
}
