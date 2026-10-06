import 'dart:math' as math;
import 'dart:ui' show Brightness, Color, Offset;

import 'package:flutter/foundation.dart';

import '../foundation/color_utils.dart';
import '../foundation/oklch.dart';
import '../painting/shadow.dart';
import 'colors.dart';
import 'shadows.dart';

/// Contrast level, an end-user setting.
///
/// The two levels share their pages, text and focus: canvas, surfaces,
/// sidebar, controls and floating layers never change, text stays at least
/// 4.5:1 and the focus ring 3:1 at both. They differ only on control
/// boundaries.
enum DsContrast {
  /// The iOS look: text and focus as at [standard], but control boundaries
  /// as faint as iOS draws them. The text field, checkbox and radio have a
  /// light edge (about 1.5:1), the switch's off track and the slider's
  /// track are light fills (about 1.3–1.4:1), chip and button edges are
  /// lighter. Controls are told by fill, shape and shadow rather than by
  /// outline.
  ///
  /// This knowingly falls below WCAG 1.4.11 (3:1 for the boundary of a
  /// control) for those edges, as iOS does; choose [standard] where that
  /// criterion must hold.
  soft,

  /// Default contrast: text at AA without glare, and the boundary of every
  /// form control (field, checkbox, radio, switch track) at 3:1 against
  /// its surface (WCAG 1.4.11). Decorative lines stay light.
  ///
  /// The strongest level: `DsScope` lifts [soft] to it when the platform
  /// asks for more contrast (iOS and macOS "Increase contrast", Android
  /// high-contrast text, Windows contrast themes).
  standard,
}

/// How the seed relates to the fixed status hues (the clash rule).
enum DsSeedRole {
  /// At least 35° away from danger and success: selection, focus and links
  /// come straight from the seed.
  free,

  /// Chroma below 0.03: selection is a mid gray with full-ink text.
  neutral,

  /// Within 35° of danger (27°) or success (~155°). The nearby status color
  /// shifts away from the brand; selection turns 20° the other way, so it
  /// stays in the brand's family without reading as that status. Links and
  /// focus use the brand's dark ink.
  nearStatus,

  /// The clash rule is off; the developer supplies status colors.
  manual,
}

/// The brand color a theme is generated from.
///
/// Only the hue, chroma and lightness of the seed are used. Every other role
/// is a fixed (lightness, chroma multiplier, alpha) rule on top of the
/// seed's hue, so any brand color yields the same hierarchy.
@immutable
class DsSeed {
  /// A seed given directly in OKLCH.
  const DsSeed.oklch(this.l, this.c, this.h);

  /// A seed taken from an sRGB brand color.
  factory DsSeed.color(Color color) {
    final v = DsOklch.fromColor(color);
    return DsSeed.oklch(v.l, v.c, v.h);
  }

  /// Lightness, 0–1.
  final double l;

  /// Chroma, 0–~0.37.
  final double c;

  /// Hue angle in degrees.
  final double h;

  /// The seed in OKLCH.
  DsOklch get value => DsOklch(l, c, h);

  /// Blue. The default: the most vivid blue that still carries a white
  /// label at AA (#0170E8); no clash.
  static const blue = DsSeed.oklch(0.565, 0.20, 257);

  /// Navy. A deep, muted brand blue; no clash.
  static const navy = DsSeed.oklch(0.43, 0.11, 262);

  /// Graphite. Neutral: gray selection, full-ink text.
  static const graphite = DsSeed.oklch(0.40, 0.016, 255);

  /// Oxblood. Near danger: brand ink for selection, danger shifts to tomato.
  static const oxblood = DsSeed.oklch(0.45, 0.16, 12);

  /// Forest. Near success: brand ink for selection, success shifts to leaf.
  static const forest = DsSeed.oklch(0.48, 0.12, 160);

  /// Vivid indigo. A saturated optional accent.
  static const indigo = DsSeed.oklch(0.52, 0.20, 272);

  @override
  bool operator ==(Object other) =>
      other is DsSeed && other.l == l && other.c == c && other.h == h;

  @override
  int get hashCode => Object.hash(l, c, h);

  @override
  String toString() => 'DsSeed($value)';
}

/// The colors and shadows generated from one seed, for one brightness and
/// contrast level.
@immutable
class DsPalette {
  const DsPalette._(this.role, this.colors, this.shadows);

  /// Generates a palette from [seed].
  ///
  /// With [autoClashRule] off, no hue shifting or selection adaptation
  /// happens. [dangerOverride], [successOverride] and [warningOverride]
  /// replace those status colors; their hover, tint and text shades are
  /// derived from the given color, with no shifting. A warning keeps the
  /// dark label of the generated one while it reads better than white on
  /// the given fill, and its text is the given color at the nearest
  /// lightness that reads 4.5:1 on the surface and on its own tint.
  ///
  /// [adjustColors] edits the generated colors before shadows are built
  /// from them, so an adjusted edge or focus color also reaches the
  /// matching shadow stack.
  factory DsPalette.fromSeed(
    DsSeed seed, {
    Brightness brightness = Brightness.light,
    DsContrast contrast = DsContrast.standard,
    bool autoClashRule = true,
    Color? dangerOverride,
    Color? successOverride,
    Color? warningOverride,
    DsColors Function(DsColors colors)? adjustColors,
  }) => _Engine(
    seed.value,
    dark: brightness == Brightness.dark,
    level: contrast,
    auto: autoClashRule,
  ).build(dangerOverride, successOverride, warningOverride, adjustColors);

  /// Which branch of the clash rule the seed fell into.
  final DsSeedRole role;

  /// Every color role.
  final DsColors colors;

  /// Every shadow stack.
  final DsShadows shadows;

  @override
  bool operator ==(Object other) =>
      other is DsPalette &&
      other.role == role &&
      other.colors == colors &&
      other.shadows == shadows;

  @override
  int get hashCode => Object.hash(role, colors, shadows);
}

/// The palette engine, tuned to the contrast budget;
/// test/fixtures/palette_snapshot.json is the regression baseline.
class _Engine {
  _Engine(
    DsOklch seed, {
    required this.dark,
    required this.level,
    required this.auto,
  }) : hu = seed.h,
       c = seed.c {
    neutral = c < .03;
    l = _lightAccentLightness(seed.l);
    _fit = l < seed.l;
    bright = !neutral && _isBright(seed.l);
    fl = bright ? _brightLightness(seed.l) : l;
    if (dark) dl = _darkAccentLightness(l);
    clash = auto && !neutral && (_near(hu, _dangerHue) || _near(hu, 150));
    final nearD = clash && _near(hu, _dangerHue);
    final nearS = clash && _near(hu, _successHue);
    final redSide = hu < 27 || hu > 207;
    dHf = nearD ? (redSide ? 31 : 23) : _dangerHue;
    dH = nearD ? (redSide ? 40 : 14) : _dangerHue;
    sH = nearS ? (hu > 155 ? 140 : 170) : _successHue;
    iH = auto && !neutral && _near(hu, _infoHue)
        ? (hu > _infoHue ? 212 : 268)
        : _infoHue;
    // Selection turns away from the status it could be mistaken for, on
    // the side away from that status's shifted hue (the status moved away
    // from the brand already, so the two end up ~35–50° apart).
    final status = nearD ? dH : (nearS ? sH : null);
    selHue = status == null
        ? hu
        : (hu + _selectionTurn * _side(hu, status)) % 360;
  }

  /// How far a near-status seed's selection turns from the brand hue.
  static const double _selectionTurn = 20;

  /// +1 when hue [a] lies clockwise of [b] (within 180°), else −1.
  static double _side(double a, double b) {
    final d = (a - b) % 360;
    return d > 0 && d <= 180 ? 1 : -1;
  }

  /// Whether colors keep the seed hue by lowering chroma instead of
  /// clipping sRGB channels. On for seeds darkened for their label:
  /// clipping turned a dark yellow orange-brown. Seeds that pass as
  /// they are, every preset included, keep their calibrated colors.
  var _fit = false;

  static const double _dangerHue = 27, _successHue = 155, _infoHue = 240;

  final double hu, c;
  final bool dark, auto;

  /// The contrast level being generated.
  final DsContrast level;

  bool get soft => level == DsContrast.soft;

  /// Lightness of the light-mode accent fill: the seed's own, or darker
  /// when the seed is too light to carry a white label.
  late final double l;

  /// Lightness of the dark-mode accent fill.
  late final double dl;

  /// Whether the seed takes the bright-accent branch: a light brand color
  /// (yellow, orange, sky, mint, lime) that cannot carry a white label but
  /// carries a dark one well. The accent fill then keeps the seed and its
  /// label turns dark; [l] still holds the darkened lightness, which the
  /// unlabeled roles (indicator, focus, accent text) keep using, the marks
  /// cleaned of mud by [_mark].
  late final bool bright;

  /// Lightness of the accent fill: the seed's own for a bright seed (see
  /// [bright]), else [l]. Both modes share it.
  late final double fl;

  /// The least contrast a dark label must reach on the seed for the bright
  /// branch: AAA (7:1). Only truly light seeds qualify (yellow, amber,
  /// orange, lime, mint, cyan), the set that Radix also labels dark; mid
  /// seeds such as a light blue or magenta keep the familiar white label
  /// and are darkened as before.
  static const double _brightLabelMin = 7;

  /// The dark label of a bright fill: a deep ink tinted toward the seed,
  /// like the warning fill's label.
  Color _brightInk() => o(.22, math.min(c * .35, .06));

  bool _isBright(double seedL) {
    final fill = DsOklch(seedL, _r(c), hu).fitted().toColor();
    return DsColorUtils.contrastRatio(white(), fill) < 4.5 &&
        DsColorUtils.contrastRatio(_brightInk(), fill) >= _brightLabelMin;
  }

  /// The seed's own lightness, unless the fill would melt into a white card
  /// (Snapchat yellow is 1.1:1): then darkened, hue kept, until it stands
  /// 1.2:1 off the surface, the floor of a decorative edge.
  double _brightLightness(double seedL) {
    bool stands(double lightness) =>
        DsColorUtils.contrastRatio(o(lightness, c), white()) >= 1.2;
    if (stands(seedL)) return seedL;
    var lightness = _r(seedL);
    while (!stands(lightness)) {
      lightness = _r(lightness - .005);
    }
    return lightness;
  }

  /// Hover ([steps] 1) and press (2) of a bright fill. A dark label wants a
  /// lighter fill, one step per state. A fill too light to
  /// step up twice darkens instead, mirroring the near-black fill that
  /// lightens: its label stays above 7:1.
  double _brightStep(int steps) =>
      _r(fl + (fl + .10 <= .96 ? .05 : -.05) * steps);

  /// Chroma of neutral roles (text, edges, channels, shadows): almost
  /// neutral. Clarity comes from true neutrals and one clean
  /// accent, not from tinting everything.
  double get nt => math.min(cn * .11, .012);

  /// The chroma neutral roles scale from: the seed's, up to the blue
  /// preset's, so a vivid seed does not tint the grays more.
  double get cn => math.min(c, .17);

  /// The hue of every neutral role: one cool slate for all brand colors,
  /// since a faint purple, red or yellow cast reads as a dirty gray.
  /// A neutral seed (graphite, a warm stone) is the brand's own
  /// gray and keeps its hue.
  double get _neutralHueOf => neutral ? hu : _neutralHue;
  static const double _neutralHue = 255;

  /// `oklch(l ch hue / a)` on the neutral hue; see [cn] and [nt].
  Color oN(double lightness, double chroma, [double alpha = 1]) =>
      DsOklch(lightness, _r(chroma), _neutralHueOf, alpha).toColor();

  /// Whether the dark soft selection keeps the brand hue: blues,
  /// violets and teals stay clear at low lightness; reds, oranges,
  /// yellows and greens turn brown or olive and read as status colors.
  bool get _coolSelection => !clash && hu >= 180 && hu <= 330;

  /// Light-mode `channelStrong`: the progress and slider track.
  Color _lightChannelStrong() => oN(.876, nt * .8);

  /// Dark-mode `channelStrong`: the progress and slider track.
  Color _darkChannelStrong() => oN(.33, nt * .5);

  /// Dark-mode accent chroma: the light fill's, as drawn, so dark mode is as
  /// vivid as light mode (iOS keeps its blue's chroma in dark mode too; a
  /// lower cap read dusty). Never above 0.21, so no seed turns neon. A
  /// bright fill (dark label, [bright]) is already light and keeps a 0.148
  /// cap: more chroma there turns neon. The small margin keeps seeds that
  /// merely round exactly as they were.
  double get _darkAccentChroma => math.min(
    bright ? math.min(c, .148) : math.min(c, .208),
    _drawnChroma(_lightFill) + .001,
  );

  /// Dark-mode [DsColors.indicator] chroma: the accent's, a little lower
  /// at the indicator's higher lightness so a vivid seed stays clear of
  /// neon.
  double get _darkIndicatorChroma => math.min(_darkAccentChroma, .19);

  /// The light-mode accent fill, as [_lightColors] draws it.
  Color get _lightFill => bright ? _color(DsOklch(fl, c, hu)) : o(l, c);

  /// Dark-mode chroma of a near-status seed's strong selection: never more
  /// than the light one's, as drawn.
  double get _darkClashSelectionChroma =>
      math.min(math.min(c * .6, .12), _drawnChroma(o(.32, c * .75)) + .001);

  static double _drawnChroma(Color color) => DsOklch.fromColor(color).c;

  /// The warm hues whose deep tones read as mud: orange-brown through
  /// mustard and olive to yellow-green.
  static const double _mudFrom = 50, _mudTo = 125;

  /// Lemon yellow: a muddy tone below it turns toward orange, one above
  /// it toward green.
  static const double _lemon = 105;

  /// How far below its hue's most vivid lightness ([_cuspL]) a warm tone
  /// may sit and still read as its hue rather than as brown or olive.
  static const double _mudDepth = .12;

  /// The least chroma of a turned mark: vivid, like iOS's system colors
  /// (at 0.125 a deep orange still read as sienna).
  static const double _markChroma = .15;

  static final _cusps = <int, double>{};

  /// The lightness at which [hue] reaches its highest chroma in sRGB:
  /// about 0.68 for orange, 0.89 for yellow.
  static double _cuspL(double hue) => _cusps.putIfAbsent(hue.round() % 360, () {
    final h = (hue.round() % 360).toDouble();
    var best = .5, bestC = 0.0;
    for (var i = 30; i < 100; i++) {
      var lo = 0.0, hi = .4;
      for (var j = 0; j < 16; j++) {
        final mid = (lo + hi) / 2;
        if (DsOklch(i / 100, mid, h).inGamut) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      if (lo > bestC) {
        bestC = lo;
        best = i / 100;
      }
    }
    return best;
  });

  /// Whether [v] reads as olive, mustard or brown: a warm hue (50–125°)
  /// well below the lightness where that hue is vivid. A dark yellow is
  /// olive and a dark amber mustard whatever their chroma; a dark blue or
  /// green is still blue or green.
  static bool _muddy(DsOklch v) =>
      v.c >= .015 &&
      v.h >= _mudFrom &&
      v.h <= _mudTo &&
      v.l < _cuspL(v.h) - _mudDepth;

  /// The fitted tone of [hue] and [chroma] with the highest lightness
  /// whose luminance stays at most [luminance].
  static DsOklch _atLuminance(double hue, double chroma, double luminance) {
    var lo = 0.0, hi = 1.0;
    for (var i = 0; i < 24; i++) {
      final mid = (lo + hi) / 2;
      final y = DsColorUtils.luminance(
        DsOklch(mid, chroma, hue).fitted().toColor(),
      );
      if (y > luminance) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return DsOklch(lo, chroma, hue).fitted();
  }

  /// A light-mode mark with no label on it (progress and slider fill, tab
  /// underline, caret, focus outline), at [lightness] on
  /// the seed hue: `o(lightness, c)`, unless that tone is muddy (a yellow
  /// or amber darkened to stand 3:1 or read 4.5:1 turns olive or
  /// mustard). Then the hue turns, away from lemon yellow, to the nearest
  /// one that is clean at the same luminance, so every contrast it met
  /// still holds: a yellow or amber brand marks in a vivid deep orange
  /// (about 49°, iOS's accessible yellow), a lemon one in a deep lime.
  /// Chroma is the seed's, at least [_markChroma], as far as sRGB allows.
  Color _mark(double lightness) {
    final plain = o(lightness, c);
    if (neutral) return plain;
    final drawn = DsOklch.fromColor(plain);
    if (!_muddy(drawn)) return plain;
    final y = DsColorUtils.luminance(plain);
    final chroma = math.max(c, _markChroma);
    final step = drawn.h < _lemon ? -1.0 : 1.0;
    var hue = drawn.h;
    Color tone;
    do {
      hue = (hue + step) % 360;
      tone = _atLuminance(hue, chroma, y).toColor();
      // Judged as drawn: 8-bit rounding moves a hue by a few tenths.
    } while (_muddy(DsOklch.fromColor(tone)));
    return tone;
  }

  /// The dark-mode [DsColors.indicator]: the accent hue at 0.68, lighter
  /// than the button fill like iOS's dark blue. A warm hue that is muddy
  /// there (a yellow or amber at 0.68 is mustard) rises close to the
  /// lightness where it is vivid, as iOS's dark yellow does; so does an
  /// amber that only borders on ochre.
  Color _darkIndicator() {
    final base = DsOklch(.68, _darkIndicatorChroma, hu).fitted();
    if (neutral || hu < _mudFrom || hu > _mudTo) return base.toColor();
    return DsOklch(
      math.max(.68, _cuspL(hu) - _mudDepth / 2),
      _darkIndicatorChroma,
      hu,
    ).fitted().toColor();
  }

  /// The light-mode [DsColors.accentTint]: the label-safe accent at 9%,
  /// unless that accent is muddy (a darkened yellow at 9% is linen-beige):
  /// then the fill itself for a bright seed, or the clean [_mark] tone,
  /// at the opacity that keeps the same lightness on a card.
  Color _lightTint(Color fill, Color mark) {
    final ink = o(l, c, .09);
    if (neutral || !_muddy(DsOklch.fromColor(o(l, c)))) return ink;
    final source = bright ? fill : mark;
    final target = DsColorUtils.luminance(DsColorUtils.flatten(ink, white()));
    var alpha = .09;
    int byte(double channel) => (channel * 255).round();
    Color at(double a) =>
        Color.fromARGB(byte(a), byte(source.r), byte(source.g), byte(source.b));
    while (alpha < .4 &&
        DsColorUtils.luminance(DsColorUtils.flatten(at(alpha), white())) >
            target) {
      alpha = _r(alpha + .01);
    }
    return at(alpha);
  }

  /// The dark-mode [DsColors.accentTint] (date range band, icon box), at
  /// 18% so it reads as a band on a card and a floating layer (1.3:1; at
  /// 10% a range nearly vanished). Cool brands keep their color; a warm
  /// one's light tint mixes with the dark gray into olive, brown or dusty
  /// mauve, so it washes in gray and the accent text and filled ends carry
  /// the brand (as the dark soft selection does, K-161).
  Color _darkTint() => neutral || _coolSelection
      ? o(.72, math.min(c * .9, .12), .18)
      : oN(.72, math.min(cn * .05, .008), .18);

  /// The dark-mode accent text: from 0.80 a step lighter until it reads
  /// 4.5:1 on the date range band in a floating calendar (the band is 18%
  /// so it stands 1.3:1 off that layer; a pink stood at 4.48:1).
  Color _darkAccentInk(double chroma, {required Color overlay}) {
    final band = DsColorUtils.flatten(_darkTint(), overlay);
    var lightness = .80;
    while (lightness < .86 &&
        DsColorUtils.contrastRatio(o(lightness, chroma), band) < 4.55) {
      lightness = _r(lightness + .005);
    }
    return o(lightness, chroma);
  }

  late final bool neutral, clash;
  late final double dHf, dH, sH, iH, selHue;

  static bool _near(double a, double b) => DsOklch.hueDistance(a, b) < 35;

  /// Measures instead of trusting the seed: a light brand color such
  /// as yellow or sky blue cannot hold a white label at AA. The lightness
  /// is lowered, keeping the hue (chroma drops only where sRGB runs out, see
  /// [_fit]), until white text reaches 4.5:1 and the color stands 3:1 off
  /// the progress track. Seeds that already pass keep their exact
  /// lightness, so the presets do not move.
  ///
  /// A bright seed (see [bright]) keeps its own fill with a dark label; this
  /// darkened color then draws only what has no label on it and must stand
  /// 3:1 on its own: progress and slider fill, focus outline, accent text.
  /// The switch track stays bright and its knob gets a dark edge instead
  /// ([DsShadows.knobOn]).
  /// Dark mode: a little lighter than the light-mode fill, never
  /// more saturated, with a white label at 4.5:1 like iOS (whose own blue
  /// reaches only 3.2:1). Starts at the light fill + 0.1 (0.55–0.64) and
  /// darkens until the label and the switch knob (3:1) pass. Progress and
  /// slider fills use the lighter [DsColors.indicator] instead.
  double _darkAccentLightness(double lightL) {
    final knob = oN(.97, nt * .5);
    var lightness = _r((lightL + .1).clamp(.55, .64));
    while (lightness > .3) {
      final fill = o(lightness, _darkAccentChroma);
      if (DsColorUtils.contrastRatio(white(), fill) >= 4.6 &&
          DsColorUtils.contrastRatio(knob, fill) >= 3.05) {
        break;
      }
      lightness = _r(lightness - .005);
    }
    return lightness;
  }

  double _lightAccentLightness(double seedL) {
    final track = _lightChannelStrong();
    bool passes(double lightness, double label, double ui) {
      final candidate = DsOklch(lightness, _r(c), hu);
      final fill = (lightness < seedL ? candidate.fitted() : candidate)
          .toColor();
      return DsColorUtils.contrastRatio(white(), fill) >= label &&
          DsColorUtils.contrastRatio(fill, track) >= ui;
    }

    if (passes(seedL, 4.5, 3)) return seedL;
    // A small margin keeps the derived hover and tint shades clear of the
    // threshold after rounding.
    var lightness = _r(seedL);
    while (lightness > .2 && !passes(lightness, 4.6, 3.05)) {
      lightness = _r(lightness - .005);
    }
    return lightness;
  }

  /// JS `+x.toFixed(3)`.
  static double _r(double x) => (x * 1000).round() / 1000;

  /// The value for the contrast level: [standard], or [soft] at soft
  /// contrast. Soft only departs from standard on control boundaries.
  double v(double standard, {required double soft}) =>
      this.soft ? soft : standard;

  /// `oklch(l ch hu / a)` on the seed hue; chroma rounded like the JS.
  Color o(double lightness, double chroma, [double alpha = 1]) =>
      _color(DsOklch(lightness, _r(chroma), hu, alpha));

  /// Same, on the selection hue.
  Color oS(double lightness, double chroma, [double alpha = 1]) =>
      _color(DsOklch(lightness, _r(chroma), selHue, alpha));

  Color _color(DsOklch v) => (_fit ? v.fitted() : v).toColor();

  /// A status color at a fixed hue.
  static Color st(
    double lightness,
    double chroma,
    double hue, [
    double alpha = 1,
  ]) => DsOklch(lightness, chroma, hue, alpha).toColor();

  static const _clear = Color(0x00000000);

  static Color white([double a = 1]) =>
      Color.fromARGB((a * 255).round(), 255, 255, 255);
  static Color black([double a = 1]) =>
      Color.fromARGB((a * 255).round(), 0, 0, 0);

  static Color _alpha(Color color, double factor) =>
      color.withValues(alpha: (color.a * factor).clamp(0.0, 1.0));

  DsPalette build(
    Color? dangerOverride,
    Color? successOverride,
    Color? warningOverride,
    DsColors Function(DsColors)? adjust,
  ) {
    var colors = dark ? _darkColors() : _lightColors();
    colors = colors.copyWith(accentEdge: _accentEdge(colors));
    // An override's tints are opaque like the generated ones: the color at
    // a low opacity, mixed onto the surface.
    final surface = colors.surface;
    Color wash(Color color, double alpha) =>
        DsColorUtils.flatten(color.withValues(alpha: alpha), surface);
    if (dangerOverride != null) {
      final d = dangerOverride;
      final toward = dark ? white() : black();
      colors = colors.copyWith(
        danger: DsStatusColors(
          fill: d,
          fillHover: DsOklch.mix(d, toward, .12),
          fillPress: DsOklch.mix(d, toward, .24),
          onFill: colors.danger.onFill,
          tint: wash(d, dark ? .16 : .09),
          tintHover: wash(d, dark ? .24 : .15),
          tintPress: wash(d, dark ? .32 : .21),
          text: DsOklch.mix(d, toward, dark ? .40 : .15),
          signal: _clear,
        ),
      );
    }
    if (successOverride != null) {
      final g = successOverride;
      final toward = dark ? white() : black();
      colors = colors.copyWith(
        success: DsStatusColors(
          fill: g,
          fillHover: DsOklch.mix(g, toward, .12),
          fillPress: DsOklch.mix(g, toward, .24),
          onFill: colors.success.onFill,
          tint: wash(g, dark ? .16 : .13),
          tintHover: wash(g, dark ? .24 : .2),
          tintPress: wash(g, dark ? .32 : .27),
          text: DsOklch.mix(g, toward, dark ? .45 : .28),
          signal: _clear,
        ),
      );
    }
    if (warningOverride != null) {
      final w = warningOverride;
      // The generated warning is a light fill with a dark label, and its
      // hover and press lighten, away from the label (K-29, K-68). A fill
      // on which white reads better takes a white label and steps like
      // danger.
      final label = colors.warning.onFill;
      final darkLabel =
          DsColorUtils.contrastRatio(label, w) >=
          DsColorUtils.contrastRatio(white(), w);
      final toward = darkLabel || dark ? white() : black();
      final tint = wash(w, dark ? .16 : .13);
      colors = colors.copyWith(
        warning: DsStatusColors(
          fill: w,
          fillHover: DsOklch.mix(w, toward, .12),
          fillPress: DsOklch.mix(w, toward, .24),
          onFill: darkLabel ? label : white(),
          tint: tint,
          tintHover: wash(w, dark ? .24 : .2),
          tintPress: wash(w, dark ? .32 : .27),
          // A warning hue is light: the given color itself rarely reads as
          // text, so it moves to the nearest lightness that does.
          text: _readable(w, [surface, tint]),
          signal: _clear,
        ),
      );
    }
    colors = _withSignals(
      colors,
      danger: dangerOverride == null ? null : DsOklch.fromColor(dangerOverride),
      success: successOverride == null
          ? null
          : DsOklch.fromColor(successOverride),
      warning: warningOverride == null
          ? null
          : DsOklch.fromColor(warningOverride),
    );
    final role = !auto
        ? DsSeedRole.manual
        : neutral
        ? DsSeedRole.neutral
        : clash
        ? DsSeedRole.nearStatus
        : DsSeedRole.free;
    if (adjust != null) colors = adjust(colors);
    return DsPalette._(
      role,
      colors,
      dark ? _darkShadows(colors) : _lightShadows(colors),
    );
  }

  /// Fills in each status's [DsStatusColors.signal]: a vivid mark color
  /// with no label on it, like iOS's system colors (light red #FF3B30-class,
  /// dark green #30D158-class). It starts at an iOS-like lightness and
  /// chroma on the status hue and moves away from the layers (darker in
  /// light mode, lighter in dark mode) only until it stands 3:1 off the
  /// canvas, the surface, the sidebar and floating layers, and in light
  /// mode off the status tint (a light alert's icon). [danger], [success]
  /// and [warning] are a developer's override colors, used as the start.
  DsColors _withSignals(
    DsColors k, {
    DsOklch? danger,
    DsOklch? success,
    DsOklch? warning,
  }) {
    final grounds = [k.canvas, k.surface, k.sidebar, k.overlay];
    Color signal(DsOklch start, DsStatusColors s) {
      final on = [...grounds, if (!dark) s.tint];
      Color at(double lightness) =>
          start.copyWith(l: lightness).fitted().toColor();
      bool stands(Color c) =>
          on.every((g) => DsColorUtils.contrastRatio(c, g) >= 3.05);
      var lightness = start.l;
      while (!stands(at(lightness)) && lightness > .05 && lightness < .98) {
        lightness = _r(lightness + (dark ? .005 : -.005));
      }
      return at(lightness);
    }

    DsStatusColors put(DsStatusColors s, DsOklch start) =>
        s.copyWith(signal: signal(start, s));
    return k.copyWith(
      neutral: put(k.neutral, DsOklch(dark ? .70 : .60, nt, _neutralHueOf)),
      danger: put(k.danger, danger ?? DsOklch(dark ? .66 : .63, .21, dHf)),
      success: put(k.success, success ?? DsOklch(dark ? .76 : .65, .18, sH)),
      warning: put(k.warning, warning ?? DsOklch(dark ? .80 : .74, .16, 68)),
      info: put(k.info, DsOklch(dark ? .74 : .62, .14, iH)),
    );
  }

  /// [color]'s hue and chroma at the lightness nearest its own that reads
  /// 4.5:1 on every one of [grounds]: darker in light mode, lighter in
  /// dark mode.
  Color _readable(Color color, List<Color> grounds) {
    final start = DsOklch.fromColor(color);
    Color at(double lightness) =>
        start.copyWith(l: lightness).fitted().toColor();
    bool reads(Color c) =>
        grounds.every((g) => DsColorUtils.contrastRatio(c, g) >= 4.55);
    var lightness = start.l;
    while (!reads(at(lightness)) && lightness > .05 && lightness < .98) {
      lightness = _r(lightness + (dark ? .005 : -.005));
    }
    return at(lightness);
  }

  DsColors _lightColors() {
    // The darkened accent; marks without a label on it use its clean tone
    // ([_mark]), which is the same color unless the darkened hue is muddy.
    final ink = o(l, c);
    final mark = _mark(l);
    // A bright fill is the seed itself, chroma unrounded.
    final acc = bright ? _color(DsOklch(fl, c, hu)) : ink;
    final onAcc = bright ? _brightInk() : white();
    // Status tints: opaque, light and clean, so they read the same on the
    // page and the card (translucent ones took on the cool page's gray:
    // warning turned khaki). Hover and press step darker and a little more
    // saturated.
    Color softTint(double hue, double chroma, [int step = 0]) => DsOklch(
      const [.95, .925, .90][step],
      chroma * const [1, 1.5, 2][step],
      hue,
    ).fitted().toColor();
    final dangerC = clash ? .025 : .035, successC = clash ? .03 : .045;
    // Stands off the page as well as the card (M3; was 1.03:1 on canvas).
    // Translucent like the channel (K-160): light on a card, still 1.2:1 on
    // it and 1.15:1 on the page (K-161).
    final neutralTint = oN(.30, nt, .10);
    final accentInk = o(math.min(l, .45), c);
    return DsColors(
      canvas: oN(.96, clash ? cn * .012 : cn * .025),
      surface: white(),
      sidebar: oN(.984, clash ? cn * .012 : cn * .025),
      control: white(),
      controlHover: oN(.975, cn * .03),
      // Pressed goes one step beyond hover (K-68).
      controlPress: oN(.95, cn * .03),
      overlay: white(),
      // White at every level: a gray, iOS-like filled well read as
      // disabled on the gray page.
      field: white(),
      text: oN(.22, nt),
      textMuted: oN(.485, nt * .8),
      // 4.5:1 on a selected row too (select hints, V10).
      textSubtle: oN(.535, nt * .7),
      accent: acc,
      // Darkens under the white label (K-29) and presses one step further
      // (K-68); a near-black fill cannot, so it lightens instead (the label
      // stays far above AA).
      accentHover: bright
          ? o(_brightStep(1), c)
          : o(_r(l < .2 ? math.max(l + .07, .27) : l - .05), c),
      accentPress: bright
          ? o(_brightStep(2), c)
          : o(_r(l < .2 ? math.max(l + .12, .32) : l - .10), c),
      onAccent: onAcc,
      // Set in [build] from the finished fills ([_accentEdge]).
      accentEdge: _clear,
      indicator: mark,
      accentTint: _lightTint(acc, mark),
      accentText: accentInk,
      link: clash ? o(.36, c * .8) : accentInk,
      // A vivid seed's tint is capped and fitted to sRGB rather than
      // clipped, which made it darker than the text budget allows.
      selection: neutral
          ? o(.895, c)
          : clash
          ? oS(.913, c * .24)
          : c * .4 > .08
          ? DsOklch(.916, .08, hu).fitted().toColor()
          : o(.911, c * .4),
      // A stronger tint, like the status tints' hover.
      selectionHover: neutral
          ? o(.85, c)
          : clash
          ? oS(.875, c * .3)
          : o(.87, math.min(c * .5, .1)),
      onSelection: neutral
          ? o(.22, c * .3)
          : clash
          ? oS(.32, c * .55)
          : o(math.min(l, .38), c),
      selectionStrong: clash ? o(.32, c * .75) : acc,
      // Darkens under the white label (K-29); a near-black fill cannot, so
      // it lightens instead (the label stays far above AA).
      selectionStrongHover: clash
          ? o(.27, c * .75)
          : bright
          ? o(_brightStep(1), c)
          : o(_r(l < .3 ? math.max(l + .07, .3) : l - .05), c),
      onSelectionStrong: clash ? white() : onAcc,
      focus: neutral
          ? o(.30, c * .3)
          : clash
          ? o(.34, c * .75)
          : mark,
      // Soft: as faint as iOS draws them.
      border: oN(.30, nt, v(.11, soft: .10)),
      borderControl: oN(.25, nt, v(.15, soft: .11)),
      // Standard: 3:1 against field and surface (WCAG 1.4.11; the concept
      // had 1.44:1). Soft: a light edge, about 1.5:1.
      borderField: oN(.25, nt, v(.52, soft: .24)),
      borderChip: oN(.30, nt, v(.10, soft: .08)),
      // Translucent like iOS's fill: light on a white card (#EEEFEF), still
      // 1.15:1 on the gray page (an opaque 0.92 read heavy).
      channel: oN(.30, nt, .08),
      // Soft: lighter, like iOS's slider track. Opaque: a slider tick
      // punches it through the fill.
      channelStrong: soft ? oN(.905, nt * .8) : _lightChannelStrong(),
      // Soft: a light fill like iOS's off switch (about 1.35:1); the
      // knob's shadow carries it.
      rail: oN(v(.62, soft: .895), nt),
      channelThumb: white(),
      knob: white(),
      shimmer: white(.7),
      hover: oN(.30, nt, .045),
      press: oN(.30, nt, .08),
      // Disabled reads as inactive but stays legible (3–4.5:1) and stands
      // off the page (concept: 1.02:1 and 2.35:1).
      disabled: oN(.30, nt, .065),
      onDisabled: oN(.60, cn * .05),
      // Dims the page like Apple, Radix and Primer; a light veil washed it
      // out instead (M1).
      scrim: oN(.22, nt, .32),
      tooltip: oN(.24, nt),
      onTooltip: white(),
      onTooltipMuted: white(.65),
      neutral: DsStatusColors(
        fill: oN(.50, nt),
        fillHover: oN(.45, nt),
        fillPress: oN(.40, nt),
        onFill: white(),
        tint: neutralTint,
        tintHover: oN(.30, nt, .14),
        tintPress: oN(.30, nt, .18),
        text: oN(.42, nt),
        signal: _clear,
      ),
      danger: DsStatusColors(
        fill: st(.57, .21, dHf),
        fillHover: st(.52, .21, dHf),
        fillPress: st(.47, .21, dHf),
        onFill: white(),
        tint: softTint(dH, dangerC),
        tintHover: softTint(dH, dangerC, 1),
        tintPress: softTint(dH, dangerC, 2),
        text: st(.50, .17, dH),
        signal: _clear,
      ),
      success: DsStatusColors(
        fill: st(.54, .14, sH),
        fillHover: st(.49, .14, sH),
        fillPress: st(.44, .14, sH),
        onFill: white(),
        tint: softTint(sH, successC),
        tintHover: softTint(sH, successC, 1),
        tintPress: softTint(sH, successC, 2),
        text: st(.43, .11, sH),
        signal: _clear,
      ),
      warning: DsStatusColors(
        fill: st(.70, .15, 75),
        // Dark label: hover and press lighten (K-29, K-68).
        fillHover: st(.75, .15, 75),
        fillPress: st(.80, .14, 75),
        onFill: st(.25, .06, 70),
        tint: softTint(85, .055),
        tintHover: softTint(85, .055, 1),
        tintPress: softTint(85, .055, 2),
        text: st(.46, .10, 70),
        signal: _clear,
      ),
      info: DsStatusColors(
        fill: st(.55, .13, iH),
        fillHover: st(.50, .13, iH),
        fillPress: st(.45, .13, iH),
        onFill: white(),
        tint: softTint(iH, .035),
        tintHover: softTint(iH, .035, 1),
        tintPress: softTint(iH, .035, 2),
        text: st(.44, .12, iH),
        signal: _clear,
      ),
    );
  }

  /// Dark mode, tuned to the contrast budget.
  ///
  /// Choices that follow iOS 27's dark-mode habits:
  /// - Accent fills keep the light fill's chroma (capped at 0.21; a bright
  ///   fill at 0.148) and get only a little lighter; text accents are
  ///   capped at 0.105.
  /// - Elevation is told by lightness: page, surface and control/overlay
  ///   steps each clear 1.2:1.
  /// - Text is softened white (≤ 13:1), not pure white.
  /// - Hover moves away from the label color: white-label fills
  ///   darken, dark-label fills lighten.
  /// - Form control boundaries meet 3:1; decorative lines stay soft.
  DsColors _darkColors() {
    // Dark surfaces stay almost neutral, even for a neon seed.
    final n = math.min(cn * .05, .008);
    final accC = _darkAccentChroma;
    final textAccC = math.min(c * .7, .105);
    final acc = o(bright ? fl : dl, accC);
    final onAcc = bright ? _brightInk() : white();
    final accentInk = clash
        ? o(.82, math.min(c * .45, .10))
        : _darkAccentInk(textAccC, overlay: oN(.335, n));
    // Deep, opaque status tints (a light color at low opacity mixed with
    // the dark gray into olive and brown, K-161). As saturated as sRGB
    // allows this dark and a little lighter than before, so they read as
    // the status hue rather than brown or maroon; the vivid status text on
    // them carries the color. Hover and press step lighter, staying under
    // the text at 4.5:1. Alerts do not use them (a neutral block instead).
    Color deepTint(double hue, double chroma, [int step = 0]) =>
        DsOklch(.34 + step * .02, chroma, hue).fitted().toColor();
    final softWhite = oN(.93, n * .3);
    // As much brand chroma as keeps secondary text 4.5:1 on a menu
    // highlight (select details, shortcuts): chroma darkens a blue or
    // violet a little.
    final selL = .395;
    final muted = oN(.80, n * .5);
    var coolSelC = math.min(c * .55, .09);
    if (_coolSelection) {
      final overlay = oN(.335, n);
      while (coolSelC > .03 &&
          DsColorUtils.contrastRatio(
                muted,
                DsColorUtils.flatten(o(selL, coolSelC), overlay),
              ) <
              4.55) {
        coolSelC -= .005;
      }
    }
    return DsColors(
      canvas: oN(.18, n),
      surface: oN(.26, n),
      sidebar: oN(.22, n),
      control: oN(.32, n),
      controlHover: oN(.35, n),
      // Pressed goes one step beyond hover (K-68).
      controlPress: oN(.38, n),
      overlay: oN(.335, n),
      field: oN(.30, n),
      text: oN(.93, n * .3),
      // Three tiers apart, as in light mode: textSubtle ~6.3:1 on the
      // surface and still 4.5:1 on a floating layer and in a field. On a
      // highlighted row in a floating layer (select details, shortcuts)
      // components use textMuted, which holds 4.5:1 there.
      textMuted: muted,
      textSubtle: oN(.72, n * .5),
      accent: acc,
      // White label: hover darkens (K-29); a dark label lightens.
      accentHover: o(bright ? _brightStep(1) : _r(dl - .04), accC),
      accentPress: o(bright ? _brightStep(2) : _r(dl - .08), accC),
      onAccent: onAcc,
      accentEdge: _clear,
      // No label on it: lighter than the button fill, like iOS's dark blue,
      // and as vivid (fitted to sRGB so the hue holds).
      indicator: _darkIndicator(),
      accentTint: _darkTint(),
      accentText: accentInk,
      link: accentInk,
      // Lighter than every layer it sits on, the floating one included
      // (V2: at 0.33 a menu highlight vanished on the 0.335 overlay).
      // Cool brands keep their color, with more chroma than before; warm
      // ones (red, orange, yellow, green) turn brown or olive this dark,
      // so they select in gray with the brand in the text (K-161).
      selection: neutral
          ? o(selL + .005, c)
          : _coolSelection
          ? o(selL, coolSelC)
          : oN(selL, n),
      selectionHover: neutral
          ? o(selL + .045, c)
          : _coolSelection
          ? o(selL + .04, coolSelC)
          : oN(selL + .04, n),
      onSelection: neutral
          ? oN(.93, n * .3)
          : _coolSelection
          ? o(.90, math.min(c * .3, .06))
          : o(.88, textAccC),
      selectionStrong: clash ? o(_r(dl - .02), _darkClashSelectionChroma) : acc,
      selectionStrongHover: clash
          ? o(_r(dl - .06), _darkClashSelectionChroma)
          : o(bright ? _brightStep(1) : _r(dl - .04), accC),
      onSelectionStrong: clash ? white() : onAcc,
      focus: neutral ? o(.86, c * .1) : accentInk,
      // Soft: as faint as iOS draws them; the field is a lighter well
      // already.
      border: white(v(.12, soft: .10)),
      borderControl: white(v(.15, soft: .11)),
      borderField: white(v(.36, soft: .13)),
      borderChip: white(v(.11, soft: .09)),
      // A lighter, translucent channel reads on both page and surface.
      channel: white(.07),
      channelStrong: _darkChannelStrong(),
      // Soft: a dark fill like iOS's off switch (about 1.4:1).
      rail: oN(v(.56, soft: .36), n),
      // Translucent like the channel: an opaque thumb stood well off the
      // channel on the page but vanished on a floating layer (1.09:1), where
      // the channel is already light. A white layer lifts it the same on
      // every layer. A fill, so both contrast levels share it.
      channelThumb: white(.16),
      // A small element: brighter than text so it reads 3:1 on both
      // switch tracks (rail and accent).
      knob: oN(.97, n),
      shimmer: white(.13),
      hover: white(.065),
      press: white(.11),
      disabled: oN(.27, n),
      onDisabled: oN(.56, n),
      scrim: black(.4),
      // An elevated dark tooltip instead of a bright inverted block.
      tooltip: oN(.40, n),
      onTooltip: softWhite,
      onTooltipMuted: oN(.93, n * .3, .72),
      neutral: DsStatusColors(
        fill: oN(.74, n * .5),
        fillHover: oN(.80, n * .5),
        fillPress: oN(.86, n * .5),
        onFill: oN(.20, n),
        tint: white(.09),
        tintHover: white(.14),
        tintPress: white(.19),
        text: oN(.86, n * .5),
        signal: _clear,
      ),
      danger: DsStatusColors(
        fill: st(.58, .20, dHf),
        fillHover: st(.54, .20, dHf),
        fillPress: st(.50, .20, dHf),
        onFill: white(),
        tint: deepTint(dH, .11),
        tintHover: deepTint(dH, .11, 1),
        tintPress: deepTint(dH, .11, 2),
        // Vivid, like iOS's dark system colors, not pastel.
        text: st(.80, .15, dH),
        signal: _clear,
      ),
      success: DsStatusColors(
        // White label like the accent (K-44); hover darkens (K-29).
        fill: st(.55, .13, sH),
        fillHover: st(.51, .13, sH),
        fillPress: st(.47, .13, sH),
        onFill: white(),
        tint: deepTint(sH, .09),
        tintHover: deepTint(sH, .09, 1),
        tintPress: deepTint(sH, .09, 2),
        // Vivid, like iOS's dark system colors, not pastel.
        text: st(.82, .15, sH),
        signal: _clear,
      ),
      warning: DsStatusColors(
        fill: st(.78, .15, 75),
        fillHover: st(.83, .15, 75),
        fillPress: st(.88, .12, 78),
        onFill: st(.25, .06, 70),
        tint: deepTint(70, .09),
        tintHover: deepTint(70, .09, 1),
        tintPress: deepTint(70, .09, 2),
        // Vivid, like iOS's dark system colors, not pastel.
        text: st(.86, .14, 78),
        signal: _clear,
      ),
      info: DsStatusColors(
        fill: st(.56, .12, iH),
        fillHover: st(.52, .12, iH),
        fillPress: st(.48, .12, iH),
        onFill: white(),
        tint: deepTint(iH, .07),
        tintHover: deepTint(iH, .07, 1),
        tintPress: deepTint(iH, .07, 2),
        // Vivid, like iOS's dark system colors, not pastel.
        text: st(.83, .11, iH),
        signal: _clear,
      ),
    );
  }

  DsShadows _lightShadows(DsColors k) {
    const down1 = Offset(0, 1);
    final lift = [DsShadow(color: oN(.25, nt, .07), offset: down1, blur: 2)];
    final knobEdge = DsShadow.ring(oN(.25, nt, .1), width: .5);
    return DsShadows(
      surface: [DsShadow.ring(oN(.25, nt, .077), hairline: true)],
      surfaceRaised: [
        DsShadow.ring(oN(.25, nt, .10), hairline: true),
        DsShadow(color: oN(.25, nt, .06), offset: down1, blur: 2),
        DsShadow(
          color: oN(.25, nt, .14),
          offset: const Offset(0, 6),
          blur: 16,
          spread: -6,
        ),
      ],
      control: [DsShadow.ring(k.borderControl), ...lift],
      controlLift: lift,
      fieldError: [DsShadow.innerRing(k.danger.fill)],
      accent: _filledEdge(k),
      danger: const [],
      overlay: [
        DsShadow(color: white(), offset: down1, inset: true),
        DsShadow.ring(oN(.25, nt, .12), hairline: true),
        DsShadow(color: oN(.25, nt, .06), offset: const Offset(0, 2), blur: 4),
        DsShadow(
          color: oN(.25, nt, .22),
          offset: const Offset(0, 12),
          blur: 28,
          spread: -8,
        ),
      ],
      sidebarEdge: [
        DsShadow(
          color: oN(.30, nt, .1),
          offset: const Offset(-1, 0),
          inset: true,
          hairline: true,
        ),
      ],
      // Channels draw no line.
      channel: const [],
      channelThumb: [
        DsShadow.ring(oN(.25, nt, .126), hairline: true),
        DsShadow(color: oN(.25, nt, .22), offset: down1, blur: 3),
      ],
      // The knob's faint edge.
      knob: [
        knobEdge,
        DsShadow(color: oN(.25, nt, .2), offset: down1, blur: 3),
      ],
      knobOn: [
        if (bright) DsShadow.ring(_knobEdge(k)) else knobEdge,
        DsShadow(color: oN(.25, nt, .2), offset: down1, blur: 3),
      ],
      // Concept: 0 6px 16px -6px rgba(0,0,0,.35).
      tooltip: [
        DsShadow(
          color: black(.35),
          offset: const Offset(0, 6),
          blur: 16,
          spread: -6,
        ),
      ],
      focusOffset: _focusOffset(k),
    );
  }

  DsShadows _darkShadows(DsColors k) {
    const down1 = Offset(0, 1);
    final highlight = DsShadow(color: white(.045), offset: down1, inset: true);
    final lift = [
      highlight,
      DsShadow(color: black(.3), offset: down1, blur: 2),
    ];
    return DsShadows(
      surface: [DsShadow.ring(white(.07), hairline: true), highlight],
      surfaceRaised: [
        DsShadow.ring(white(.11), hairline: true),
        highlight,
        DsShadow(
          color: black(.35),
          offset: const Offset(0, 6),
          blur: 16,
          spread: -6,
        ),
      ],
      control: [DsShadow.ring(k.borderControl), ...lift],
      controlLift: lift,
      // danger.fill is ~2.96:1 on dark surfaces; danger.text clears the
      // 3:1 WCAG 1.4.11 bar for control boundaries (KALITE S-01).
      fieldError: [DsShadow.innerRing(k.danger.text)],
      accent: _filledEdge(k),
      danger: const [],
      overlay: [
        DsShadow.ring(white(.14), hairline: true),
        DsShadow(color: white(.09), offset: down1, inset: true),
        DsShadow(color: black(.3), offset: const Offset(0, 2), blur: 4),
        DsShadow(
          color: black(.6),
          offset: const Offset(0, 14),
          blur: 32,
          spread: -8,
        ),
      ],
      sidebarEdge: [
        DsShadow(
          color: white(.08),
          offset: const Offset(-1, 0),
          inset: true,
          hairline: true,
        ),
      ],
      channel: const [],
      channelThumb: [
        DsShadow.ring(white(.11), hairline: true),
        highlight,
        DsShadow(color: black(.45), offset: down1, blur: 3),
      ],
      knob: [DsShadow(color: black(.4), offset: down1, blur: 2)],
      knobOn: [
        if (bright) DsShadow.ring(_knobEdge(k)),
        DsShadow(color: black(.4), offset: down1, blur: 2),
      ],
      tooltip: [
        DsShadow(
          color: black(.5),
          offset: const Offset(0, 6),
          blur: 16,
          spread: -6,
        ),
      ],
      focusOffset: _focusOffset(k),
    );
  }

  /// A filled button is flat, like Geist and shadcn: no glow, no lift.
  /// Only a bright accent, which melts into a light card,
  /// keeps a hairline inside the fill: its dark label at 20%. A hairline
  /// and not the 3:1 [DsColors.accentEdge] itself, because the button's
  /// label, not its outline, says what it is (WCAG 1.4.11 asks 3:1 of a
  /// checkbox's edge, which carries its state, not of a labeled
  /// button's); for the same reason a white-labeled fill, which may wear
  /// an edge on its checked controls in dark mode, keeps its buttons flat.
  List<DsShadow> _filledEdge(DsColors k) => [
    if (bright && k.accentEdge.a > 0)
      DsShadow.innerRing(_alpha(k.onAccent, .2)),
  ];

  /// The knob's edge over a bright on track: the dark label at the lowest
  /// opacity that stands 3:1 off the track, resting and hovered.
  static Color _knobEdge(DsColors k) {
    bool stands(Color edge) => [
      k.accent,
      k.accentHover,
    ].every((track) => DsColorUtils.contrastRatio(edge, track) >= 3.1);
    var alpha = .4;
    while (alpha < 1 && !stands(_alpha(k.onAccent, alpha))) {
      alpha = _r(alpha + .05);
    }
    return _alpha(k.onAccent, math.min(alpha, 1));
  }

  /// The edge of an accent fill that does not stand 3:1 off every layer a
  /// checked control sits on (WCAG 1.4.11): the label color at the lowest
  /// opacity whose blend over the fill, resting, hovered and pressed,
  /// stands 3:1 off each of them; transparent when the resting fill does
  /// so alone.
  ///
  /// - A bright accent stands only 1.07–1.9:1 off white, so a checked box
  ///   or an on switch lost its outline: its dark label draws the edge,
  ///   from 30%.
  /// - A white-labeled fill stands ≥ 4.5:1 off the card in light mode by
  ///   construction: no edge. In dark mode its white label holds it dark
  ///   (4.5:1 under white); a deep red falls under 3:1 off the surface,
  ///   and a faint light rim (the white label, from 10%) keeps its checked
  ///   shape apart.
  ///
  /// The grounds are the page layers a form sits on (page, card, sidebar).
  /// On the lighter layers of dark mode, a floating layer or a field well,
  /// every white-labeled fill stands only ~2.2–2.9:1, but a rim on every
  /// checked control there would draw lines everywhere; its check mark
  /// (≥ 4.5:1 on the fill) carries the state. The same rule for every seed, in both modes and at
  /// both contrast levels; a filled selection drawn in the accent wears it
  /// too.
  Color _accentEdge(DsColors k) {
    final grounds = [k.canvas, k.surface, k.sidebar];
    final fills = [
      k.accent,
      k.accentHover,
      k.accentPress,
      // A near-status seed's strong selection is its own dark fill.
      if (k.onSelectionStrong == k.onAccent) ...[
        k.selectionStrong,
        k.selectionStrongHover,
      ],
    ];
    bool stands(Color edge, [Iterable<Color>? only]) => (only ?? fills).every(
      (fill) => grounds.every(
        (ground) =>
            DsColorUtils.contrastRatio(Color.alphaBlend(edge, fill), ground) >=
            3.05,
      ),
    );
    // The resting fills decide whether a rim is drawn: hover and press are
    // momentary, and a dark white-labeled fill darkens on them (a rim on
    // every dark checked control drew lines everywhere). Once a rim is
    // drawn it is strong enough for every state.
    if (stands(_clear, [
      k.accent,
      if (k.onSelectionStrong == k.onAccent) k.selectionStrong,
    ])) {
      return _clear;
    }
    var alpha = bright ? .3 : .1;
    while (alpha < 1 && !stands(_alpha(k.onAccent, alpha))) {
      alpha = _r(alpha + .05);
    }
    return _alpha(k.onAccent, math.min(alpha, 1));
  }

  // A solid 2px ring 2px away from the control, on a transparent gap
  // (KALITE S-13). The concept's translucent halo alone reached only
  // 1.4–2.2:1 against the page; WCAG wants 3:1 for focus indicators.
  static List<DsShadow> _focusOffset(DsColors k) => [
    DsShadow.outline(k.focus, width: 2, gap: 2),
  ];
}
