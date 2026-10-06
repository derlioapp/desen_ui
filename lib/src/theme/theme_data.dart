import 'dart:ui' show Brightness, Color;

import 'package:flutter/foundation.dart';

import '../foundation/platform.dart';
import '../painting/shadow.dart';

import 'colors.dart';
import 'haptics.dart';
import 'motion.dart';
import 'palette.dart';
import 'radii.dart';
import 'shadows.dart';
import 'sizes.dart';
import 'theme_extension.dart';
import 'typography.dart';

/// How selected items are drawn, set once for the whole theme.
enum DsSelectionStyle {
  /// A soft tinted background with accent ink: the `selection` colors.
  /// The default.
  soft,

  /// A filled accent background with contrasting ink: the
  /// `selectionStrong` colors.
  strong,
}

/// Edits generated colors. Receives the brightness they were generated for,
/// so one adjuster can serve light and dark.
typedef DsColorsAdjuster = DsColors Function(
  DsColors colors,
  Brightness brightness,
);

/// Edits generated shadows; receives the (already adjusted) colors.
typedef DsShadowsAdjuster = DsShadows Function(
  DsShadows shadows,
  DsColors colors,
  Brightness brightness,
);

/// Edits the corner rules for a corner style.
typedef DsRadiiAdjuster = DsRadii Function(DsRadii radii, DsCornerStyle style);

/// Edits the size scale for a density.
typedef DsSizesAdjuster = DsSizes Function(DsSizes sizes, DsDensity density);

/// Everything a Desen component reads to draw itself.
///
/// Colors, shadows, radii and sizes are **generated** from a [seed] and the
/// end-user settings ([brightness], [contrast], [cornerStyle], [density]).
/// They regenerate whenever a setting changes, for example when the user
/// switches to dark mode.
///
/// To customize generated tokens, use the `adjust…` hooks rather than
/// replacing them: a hook runs again after every regeneration, so your
/// changes survive mode, contrast, corner and density switches.
///
/// ```dart
/// DsThemeData(
///   seed: DsSeed.color(brand),
///   adjustColors: (k, brightness) => k.copyWith(
///     link: brightness == Brightness.dark ? lightLink : darkLink,
///   ),
///   adjustRadii: (r, style) => r.copyWith(card: r.card + 4),
/// )
/// ```
///
/// Equality compares settings and the resulting tokens, not the hook
/// functions, so a hook recreated on every build does not count as a
/// theme change.
///
/// An app's own tokens ride along as [extensions] ([DsThemeExtension]):
/// read them with [extension]. They follow regeneration and animated theme
/// changes like the built-in token groups.
///
/// The [platform] (by default the running one) sets the tap area: on
/// iOS and Android every small control gets an invisible 44px target while
/// keeping its compact look; elsewhere the target is 24px. It also decides
/// whether controls answer a touch with haptic feedback (see [haptics]).
/// Pin it with `platform:` when a layout must not depend on where it runs,
/// e.g. in golden tests.
///
/// Without a [density] the theme follows the platform, as Apple's do: phones
/// and tablets (iOS, Android, their browsers included) get
/// [DsDensity.touch], desktop and desktop browsers [DsDensity.compact]. It
/// keeps following it: `copyWith(platform:)` derives the density again
/// ([densityFollowsPlatform]), while a density that was given stays. The
/// [density] also picks the type ramp ([typography]): body text 14 at
/// [DsDensity.compact], 16 at [DsDensity.touch]. The default font follows
/// the app the code runs in, not [platform], since a font is only there
/// where it is installed: San Francisco in iOS and macOS apps, the bundled
/// face elsewhere (see `DsTypography.new`).
@immutable
class DsThemeData with Diagnosticable {
  /// Generates a theme from a seed and settings.
  factory DsThemeData({
    Brightness brightness = Brightness.light,
    DsSeed seed = DsSeed.blue,
    DsContrast contrast = DsContrast.standard,
    DsCornerStyle cornerStyle = DsCornerStyle.standard,
    DsDensity? density,
    TargetPlatform? platform,
    DsSelectionStyle selectionStyle = DsSelectionStyle.soft,
    bool autoClashRule = true,
    Color? dangerOverride,
    Color? successOverride,
    Color? warningOverride,
    DsColorsAdjuster? adjustColors,
    DsShadowsAdjuster? adjustShadows,
    DsRadiiAdjuster? adjustRadii,
    DsSizesAdjuster? adjustSizes,
    DsTypography? typography,
    DsMotion motion = const DsMotion(),
    DsHaptics? haptics,
    Iterable<DsThemeExtension<dynamic>> extensions = const [],
  }) {
    final palette = DsPalette.fromSeed(
      seed,
      brightness: brightness,
      contrast: contrast,
      autoClashRule: autoClashRule,
      dangerOverride: dangerOverride,
      successOverride: successOverride,
      warningOverride: warningOverride,
      adjustColors: adjustColors == null
          ? null
          : (k) => adjustColors(k, brightness),
    );
    final radii = DsRadii.forStyle(cornerStyle);
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    final resolvedDensity = density ?? DsDensity.forPlatform(resolvedPlatform);
    final sizes = DsSizes.forDensity(
      resolvedDensity,
      platform: resolvedPlatform,
    );
    return DsThemeData.raw(
      brightness: brightness,
      seed: seed,
      contrast: contrast,
      cornerStyle: cornerStyle,
      density: resolvedDensity,
      densityFollowsPlatform: density == null,
      platform: resolvedPlatform,
      selectionStyle: selectionStyle,
      autoClashRule: autoClashRule,
      dangerOverride: dangerOverride,
      successOverride: successOverride,
      warningOverride: warningOverride,
      adjustColors: adjustColors,
      adjustShadows: adjustShadows,
      adjustRadii: adjustRadii,
      adjustSizes: adjustSizes,
      seedRole: palette.role,
      colors: palette.colors,
      shadows:
          adjustShadows?.call(palette.shadows, palette.colors, brightness) ??
          palette.shadows,
      radii: adjustRadii?.call(radii, cornerStyle) ?? radii,
      sizes: adjustSizes?.call(sizes, resolvedDensity) ?? sizes,
      typography:
          typography?.forDensity(resolvedDensity) ??
          DsTypography(density: resolvedDensity),
      motion: motion,
      haptics: haptics,
      extensions: _byType(extensions),
    )._resolveExtensions();
  }

  /// A light theme.
  factory DsThemeData.light({DsSeed seed = DsSeed.blue}) =>
      DsThemeData(seed: seed);

  /// A dark theme.
  factory DsThemeData.dark({DsSeed seed = DsSeed.blue}) =>
      DsThemeData(seed: seed, brightness: Brightness.dark);

  /// Creates a theme with every token set given explicitly, for full manual
  /// control. [copyWith] keeps a raw theme's hand-set tokens (see there).
  ///
  /// [extensions] are keyed by [DsThemeExtension.type] and kept as given:
  /// [DsThemeExtension.resolve] is not called.
  ///
  /// Meant for tests and tools. It is not covered by the compatibility
  /// promise: later versions may add settings and token sets. To customize
  /// a theme, use the default constructor with its `adjust…` hooks
  /// (`adjustColors`, `adjustShadows`, `adjustRadii`, `adjustSizes`) and
  /// [copyWith].
  const DsThemeData.raw({
    required this.brightness,
    required this.seed,
    required this.contrast,
    required this.cornerStyle,
    required this.density,
    required this.platform,
    required this.selectionStyle,
    required this.autoClashRule,
    required this.dangerOverride,
    required this.successOverride,
    required this.seedRole,
    required this.colors,
    required this.shadows,
    required this.radii,
    required this.sizes,
    required this.typography,
    required this.motion,
    this.haptics,
    this.warningOverride,
    this.extensions = const {},
    this.densityFollowsPlatform = false,
    this.adjustColors,
    this.adjustShadows,
    this.adjustRadii,
    this.adjustSizes,
  });

  // Settings

  /// Light or dark.
  final Brightness brightness;

  /// The brand color.
  final DsSeed seed;

  /// Contrast level (end user).
  final DsContrast contrast;

  /// Corner style (end user).
  final DsCornerStyle cornerStyle;

  /// Density (end user). When the theme was created without one, the
  /// platform's ([DsDensity.forPlatform]); see [densityFollowsPlatform].
  final DsDensity density;

  /// Whether [density] was derived from [platform] rather than given: the
  /// theme was created without a density. Such a theme derives it again
  /// when [copyWith] changes the platform, so
  /// `DsThemeData(platform: TargetPlatform.macOS).copyWith(platform:
  /// TargetPlatform.iOS)` equals `DsThemeData(platform: TargetPlatform.iOS)`.
  /// A density given to the constructor or to [copyWith] stays on every
  /// platform.
  final bool densityFollowsPlatform;

  /// The platform whose conventions the sizes follow: iOS and Android get
  /// 44px tap areas at [DsDensity.compact] (see [DsSizes.forDensity]).
  /// Defaults to [defaultTargetPlatform], which is also right for mobile
  /// web.
  final TargetPlatform platform;

  /// How selected items are drawn.
  final DsSelectionStyle selectionStyle;

  /// Whether the seed/status clash rule is applied.
  final bool autoClashRule;

  /// Developer-supplied danger color.
  final Color? dangerOverride;

  /// Developer-supplied success color.
  final Color? successOverride;

  /// How much the controls answer a touch through the device's haptic
  /// engine, or null to follow the platform: see [effectiveHaptics].
  ///
  /// Set it to fix the setting for the whole app: [DsHaptics.none] for a
  /// deliberately quiet product, [DsHaptics.full] for one that answers every
  /// press. A single pressable opts out with `DsPressable(haptic: null)`.
  final DsHaptics? haptics;

  /// Developer-supplied warning color. Its hover, press, tint, text and
  /// label colors are derived from it like those of [dangerOverride] and
  /// [successOverride]; see `DsPalette.fromSeed`.
  final Color? warningOverride;

  // Customization hooks, reapplied on every regeneration

  /// Edits generated colors.
  final DsColorsAdjuster? adjustColors;

  /// Edits generated shadows.
  final DsShadowsAdjuster? adjustShadows;

  /// Edits the corner rules.
  final DsRadiiAdjuster? adjustRadii;

  /// Edits the size scale.
  final DsSizesAdjuster? adjustSizes;

  // Tokens

  /// Which branch of the clash rule [seed] fell into.
  final DsSeedRole seedRole;

  /// Color roles.
  final DsColors colors;

  /// Shadow stacks.
  final DsShadows shadows;

  /// Corner rules: control radius by height, card and layer radii, nested
  /// radii.
  final DsRadii radii;

  /// Control heights.
  final DsSizes sizes;

  /// Type scale, set for [density]: the theme passes the typography it is
  /// given through `DsTypography.forDensity`, so the touch density gets
  /// the larger touch ramp in the same fonts, and roles replaced with
  /// `DsTypography.copyWith` keep their values.
  final DsTypography typography;

  /// Motion rules.
  final DsMotion motion;

  /// The haptics setting in effect: [haptics], or when it is null the
  /// platform's own behavior, [DsHaptics.subtle] in iOS and Android apps
  /// and [DsHaptics.none] on the web and desktop.
  ///
  /// Haptics only ever play when [platform] is iOS or Android: desktop has
  /// no haptic engine. On the web a non-null [haptics] is honored where the
  /// browser can vibrate (Android browsers); the default stays silent.
  DsHaptics get effectiveHaptics =>
      haptics ??
      (!kIsWeb && isTouchPlatform(platform)
          ? DsHaptics.subtle
          : DsHaptics.none);

  /// The app's own tokens, keyed by [DsThemeExtension.type]. Read one with
  /// [extension].
  final Map<Object, DsThemeExtension<dynamic>> extensions;

  /// The extension of type [T], or null when the theme has none.
  ///
  /// ```dart
  /// final brand = DsTheme.of(context).extension<Brand>()!;
  /// ```
  T? extension<T extends DsThemeExtension<T>>() => extensions[T] as T?;

  static Map<Object, DsThemeExtension<dynamic>> _byType(
    Iterable<DsThemeExtension<dynamic>> extensions,
  ) => {for (final e in extensions) e.type: e};

  /// This theme with each extension resolved against it.
  DsThemeData _resolveExtensions() {
    if (extensions.isEmpty) return this;
    return _keepTokens(
      extensions: {
        for (final MapEntry(:key, :value) in extensions.entries)
          key: value.resolve(this) as DsThemeExtension<dynamic>,
      },
    );
  }

  /// A copy that keeps every setting, hook and token, with the given
  /// non-generating values replaced.
  DsThemeData _keepTokens({
    bool? densityFollowsPlatform,
    DsSelectionStyle? selectionStyle,
    DsTypography? typography,
    DsMotion? motion,
    ValueGetter<DsHaptics?>? haptics,
    Map<Object, DsThemeExtension<dynamic>>? extensions,
  }) => DsThemeData.raw(
    brightness: brightness,
    seed: seed,
    contrast: contrast,
    cornerStyle: cornerStyle,
    density: density,
    densityFollowsPlatform:
        densityFollowsPlatform ?? this.densityFollowsPlatform,
    platform: platform,
    selectionStyle: selectionStyle ?? this.selectionStyle,
    autoClashRule: autoClashRule,
    dangerOverride: dangerOverride,
    successOverride: successOverride,
    warningOverride: warningOverride,
    adjustColors: adjustColors,
    adjustShadows: adjustShadows,
    adjustRadii: adjustRadii,
    adjustSizes: adjustSizes,
    seedRole: seedRole,
    colors: colors,
    shadows: shadows,
    radii: radii,
    sizes: sizes,
    typography: typography ?? this.typography,
    motion: motion ?? this.motion,
    haptics: haptics != null ? haptics() : this.haptics,
    extensions: extensions ?? this.extensions,
  );

  /// Whether this is a dark theme.
  bool get isDark => brightness == Brightness.dark;

  /// Whether selected items are filled: under [DsSelectionStyle.strong].
  bool get fillsSelection => selectionStyle == DsSelectionStyle.strong;

  /// Background of a selected item: the soft `selection` tint, or the
  /// filled `selectionStrong` when [fillsSelection].
  Color get selectedFill =>
      fillsSelection ? colors.selectionStrong : colors.selection;

  /// Text of a selected item, on [selectedFill].
  Color get onSelectedFill =>
      fillsSelection ? colors.onSelectionStrong : colors.onSelection;

  /// Background of a selected item while hovered: one visible step from
  /// [selectedFill], so a selected item still answers the pointer.
  Color get selectedHoverFill =>
      fillsSelection ? colors.selectionStrongHover : colors.selectionHover;

  /// Edge of a selected item, or null for none. Only a filled selection in
  /// a bright accent needs one: it melts into a light card, so it wears
  /// [DsColors.accentEdge] (at every contrast level). A soft tint draws no
  /// edge.
  Color? get selectedEdge =>
      fillsSelection &&
          colors.accentEdge.a > 0 &&
          colors.onSelectionStrong == colors.onAccent
      ? colors.accentEdge
      : null;

  /// The focus outline filled controls draw: [DsShadows.focusOffset], a
  /// 2px ring on a 2px gap around the control. Bordered controls
  /// draw [DsShadows.focusTight] in place of their border, fields recolor
  /// their edge, full-bleed rows draw an inner ring. It only shows for
  /// keyboard focus (CSS `:focus-visible`, see `DsFocusVisibility`; text
  /// fields on any focus).
  List<DsShadow> get focusShadows => shadows.focusOffset;

  /// Returns a copy with the given settings replaced.
  ///
  /// [selectionStyle], [typography], [motion], [haptics] and [extensions]
  /// are not generation inputs: changing only them (or passing settings at
  /// their current values) keeps colors, shadows, radii and sizes exactly
  /// as they are, on any theme. A new [typography] is set for the theme's
  /// [density] (`DsTypography.forDensity`). New [extensions] replace all of the current
  /// ones and are resolved against the theme (`DsThemeExtension.resolve`).
  ///
  /// The other settings ([brightness], [seed], [contrast], [cornerStyle],
  /// [density], [platform], [autoClashRule], [dangerOverride],
  /// [successOverride], [warningOverride] and the `adjust…` hooks) only
  /// feed generation: changing one regenerates colors, shadows, radii and
  /// sizes, reapplies the hooks and resolves the extensions again.
  ///
  /// A new [platform] also brings that platform's density when the theme
  /// follows the platform ([densityFollowsPlatform]); a [density] passed
  /// here is kept on every platform from then on.
  ///
  /// A hand-built theme ([DsThemeData.raw] with tokens other than its
  /// settings generate) cannot express such a change without losing its
  /// tokens, so changing one of those settings on it asserts in debug
  /// builds; release builds regenerate as for any theme. Build a new raw
  /// theme with the tokens you want instead (for dark mode, give `DsScope`
  /// a `darkTheme`).
  ///
  /// Hooks and nullable settings are passed as getters so they can be
  /// cleared: `copyWith(adjustColors: () => null)`,
  /// `copyWith(haptics: () => null)` to follow the platform again.
  DsThemeData copyWith({
    Brightness? brightness,
    DsSeed? seed,
    DsContrast? contrast,
    DsCornerStyle? cornerStyle,
    DsDensity? density,
    TargetPlatform? platform,
    DsSelectionStyle? selectionStyle,
    bool? autoClashRule,
    ValueGetter<Color?>? dangerOverride,
    ValueGetter<Color?>? successOverride,
    ValueGetter<Color?>? warningOverride,
    ValueGetter<DsColorsAdjuster?>? adjustColors,
    ValueGetter<DsShadowsAdjuster?>? adjustShadows,
    ValueGetter<DsRadiiAdjuster?>? adjustRadii,
    ValueGetter<DsSizesAdjuster?>? adjustSizes,
    DsTypography? typography,
    DsMotion? motion,
    ValueGetter<DsHaptics?>? haptics,
    Iterable<DsThemeExtension<dynamic>>? extensions,
  }) {
    final nextHaptics = haptics != null ? haptics() : this.haptics;
    final nextDanger = dangerOverride != null
        ? dangerOverride()
        : this.dangerOverride;
    final nextSuccess = successOverride != null
        ? successOverride()
        : this.successOverride;
    final nextWarning = warningOverride != null
        ? warningOverride()
        : this.warningOverride;
    final nextColors = adjustColors != null
        ? adjustColors()
        : this.adjustColors;
    final nextShadows = adjustShadows != null
        ? adjustShadows()
        : this.adjustShadows;
    final nextRadii = adjustRadii != null ? adjustRadii() : this.adjustRadii;
    final nextSizes = adjustSizes != null ? adjustSizes() : this.adjustSizes;
    final followsPlatform = density == null && densityFollowsPlatform;
    // The generation inputs that change, by name.
    final changed = [
      if (brightness != null && brightness != this.brightness) 'brightness',
      if (seed != null && seed != this.seed) 'seed',
      if (contrast != null && contrast != this.contrast) 'contrast',
      if (cornerStyle != null && cornerStyle != this.cornerStyle) 'cornerStyle',
      if (density != null && density != this.density) 'density',
      if (platform != null && platform != this.platform) 'platform',
      if (autoClashRule != null && autoClashRule != this.autoClashRule)
        'autoClashRule',
      if (nextDanger != this.dangerOverride) 'dangerOverride',
      if (nextSuccess != this.successOverride) 'successOverride',
      if (nextWarning != this.warningOverride) 'warningOverride',
      if (nextColors != this.adjustColors) 'adjustColors',
      if (nextShadows != this.adjustShadows) 'adjustShadows',
      if (nextRadii != this.adjustRadii) 'adjustRadii',
      if (nextSizes != this.adjustSizes) 'adjustSizes',
    ];
    if (changed.isEmpty) {
      // Nothing that feeds generation changes: keep every token.
      final kept = _keepTokens(
        densityFollowsPlatform: followsPlatform,
        selectionStyle: selectionStyle,
        typography: typography?.forDensity(this.density),
        motion: motion,
        haptics: () => nextHaptics,
        extensions: extensions == null ? null : _byType(extensions),
      );
      return extensions == null ? kept : kept._resolveExtensions();
    }
    assert(
      _isGenerated,
      'DsThemeData.copyWith changed ${changed.join(', ')} on a hand-built '
      'theme (DsThemeData.raw). These settings only feed token generation, '
      'so honoring them would replace the hand-set colors, shadows, radii '
      'and sizes. Build a new DsThemeData.raw with the tokens you want, or '
      'start from the default constructor with adjust… hooks.',
    );
    return DsThemeData(
      brightness: brightness ?? this.brightness,
      seed: seed ?? this.seed,
      contrast: contrast ?? this.contrast,
      cornerStyle: cornerStyle ?? this.cornerStyle,
      // Null derives the density from the (new) platform again.
      density: followsPlatform ? null : density ?? this.density,
      platform: platform ?? this.platform,
      selectionStyle: selectionStyle ?? this.selectionStyle,
      autoClashRule: autoClashRule ?? this.autoClashRule,
      dangerOverride: nextDanger,
      successOverride: nextSuccess,
      warningOverride: nextWarning,
      adjustColors: nextColors,
      adjustShadows: nextShadows,
      adjustRadii: nextRadii,
      adjustSizes: nextSizes,
      typography: typography ?? this.typography,
      motion: motion ?? this.motion,
      haptics: nextHaptics,
      extensions: extensions ?? this.extensions.values,
    );
  }

  /// Whether the tokens are exactly what the settings generate, so
  /// regenerating loses nothing. Extensions are not tokens and do not
  /// count. Not cheap: it generates a theme.
  bool get _isGenerated =>
      DsThemeData(
        brightness: brightness,
        seed: seed,
        contrast: contrast,
        cornerStyle: cornerStyle,
        density: densityFollowsPlatform ? null : density,
        platform: platform,
        selectionStyle: selectionStyle,
        autoClashRule: autoClashRule,
        dangerOverride: dangerOverride,
        successOverride: successOverride,
        warningOverride: warningOverride,
        adjustColors: adjustColors,
        adjustShadows: adjustShadows,
        adjustRadii: adjustRadii,
        adjustSizes: adjustSizes,
        typography: typography,
        motion: motion,
        haptics: haptics,
      ) ==
      _keepTokens(extensions: const {});

  /// Linearly interpolates between two themes, for animated theme changes.
  /// Settings and hooks switch at the midpoint. An extension type both
  /// themes have interpolates with [DsThemeExtension.lerp]; one that only
  /// one theme has is there up to (or from) the midpoint.
  static DsThemeData lerp(DsThemeData a, DsThemeData b, double t) {
    if (identical(a, b)) return a;
    final p = t < 0.5 ? a : b;
    return DsThemeData.raw(
      brightness: p.brightness,
      seed: p.seed,
      contrast: p.contrast,
      cornerStyle: p.cornerStyle,
      density: p.density,
      densityFollowsPlatform: p.densityFollowsPlatform,
      platform: p.platform,
      selectionStyle: p.selectionStyle,
      autoClashRule: p.autoClashRule,
      dangerOverride: p.dangerOverride,
      successOverride: p.successOverride,
      warningOverride: p.warningOverride,
      adjustColors: p.adjustColors,
      adjustShadows: p.adjustShadows,
      adjustRadii: p.adjustRadii,
      adjustSizes: p.adjustSizes,
      seedRole: p.seedRole,
      colors: DsColors.lerp(a.colors, b.colors, t),
      shadows: DsShadows.lerp(a.shadows, b.shadows, t),
      radii: DsRadii.lerp(a.radii, b.radii, t),
      sizes: DsSizes.lerp(a.sizes, b.sizes, t),
      typography: DsTypography.lerp(a.typography, b.typography, t),
      motion: p.motion,
      haptics: p.haptics,
      extensions: _lerpExtensions(a.extensions, b.extensions, t),
    );
  }

  static Map<Object, DsThemeExtension<dynamic>> _lerpExtensions(
    Map<Object, DsThemeExtension<dynamic>> a,
    Map<Object, DsThemeExtension<dynamic>> b,
    double t,
  ) {
    if (a.isEmpty && b.isEmpty) return const {};
    // A map literal with explicit type arguments would instantiate the
    // F-bounded type argument to its bound under the compiler (not the
    // analyzer); the return type gives this one its context instead.
    return {
      for (final key in {...a.keys, ...b.keys})
        if (_lerpExtension(a[key], b[key], t)
            case final DsThemeExtension<dynamic> e)
          key: e,
    };
  }

  static DsThemeExtension<dynamic>? _lerpExtension(
    DsThemeExtension<dynamic>? from,
    DsThemeExtension<dynamic>? to,
    double t,
  ) {
    if (from != null && to != null) {
      return from.lerp(to, t) as DsThemeExtension<dynamic>;
    }
    return t < 0.5 ? from : to;
  }

  @override
  bool operator ==(Object other) =>
      other is DsThemeData &&
      other.brightness == brightness &&
      other.seed == seed &&
      other.contrast == contrast &&
      other.cornerStyle == cornerStyle &&
      other.density == density &&
      other.densityFollowsPlatform == densityFollowsPlatform &&
      other.platform == platform &&
      other.selectionStyle == selectionStyle &&
      other.autoClashRule == autoClashRule &&
      other.dangerOverride == dangerOverride &&
      other.successOverride == successOverride &&
      other.warningOverride == warningOverride &&
      other.seedRole == seedRole &&
      other.colors == colors &&
      other.shadows == shadows &&
      other.radii == radii &&
      other.sizes == sizes &&
      other.typography == typography &&
      other.motion == motion &&
      other.haptics == haptics &&
      mapEquals(other.extensions, extensions);

  @override
  int get hashCode => Object.hash(
    brightness,
    seed,
    contrast,
    cornerStyle,
    (density, densityFollowsPlatform),
    platform,
    selectionStyle,
    autoClashRule,
    dangerOverride,
    successOverride,
    warningOverride,
    seedRole,
    colors,
    shadows,
    radii,
    sizes,
    typography,
    motion,
    haptics,
    Object.hashAllUnordered([
      for (final MapEntry(:key, :value) in extensions.entries)
        Object.hash(key, value),
    ]),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty('brightness', brightness))
      ..add(DiagnosticsProperty('seed', seed))
      ..add(EnumProperty('contrast', contrast))
      ..add(EnumProperty('cornerStyle', cornerStyle))
      ..add(EnumProperty('density', density))
      ..add(
        FlagProperty(
          'densityFollowsPlatform',
          value: densityFollowsPlatform,
          ifTrue: 'density follows platform',
        ),
      )
      ..add(EnumProperty('platform', platform))
      ..add(EnumProperty('selectionStyle', selectionStyle))
      ..add(EnumProperty('haptics', haptics, defaultValue: null))
      ..add(EnumProperty('seedRole', seedRole))
      ..add(IterableProperty('extensions', extensions.values, ifEmpty: null))
      ..add(
        FlagProperty(
          'adjustColors',
          value: adjustColors != null,
          ifTrue: 'adjusted colors',
        ),
      );
  }
}
