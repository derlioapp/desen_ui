import 'dart:math' as math;
import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/theme/palette.dart' show DsPalette;
import 'package:flutter/widgets.dart' show WidgetState;

/// The contrast budget, shared by the preset test and the
/// seed fuzz test. Lower bounds are WCAG AA; upper bounds keep both levels
/// calm ("AA, not harsh").
///
/// The two levels:
/// - soft: the same text and focus rules as standard; control boundaries
///   (field and checkbox edge, switch off track) relaxed to iOS-like floors
///   that never let an edge vanish, with a non-color cue kept (an edge
///   line, the knob's shadow). WCAG 1.4.11 knowingly not met there.
/// - standard: the full budget.

/// A contrast requirement: [fg] on [bg], with [bg] flattened on [backdrop].
class Rule {
  Rule(this.label, this.fg, this.bg, {Color? backdrop, this.min, this.max})
    : backdrop = backdrop ?? bg;

  final String label;
  final Color fg, bg, backdrop;
  final double? min, max;

  String? check({required bool withMax}) {
    final r = DsColorUtils.contrastRatio(fg, bg, backdrop: backdrop);
    if (min != null && r < min!) {
      return '$label: ${r.toStringAsFixed(2)} < $min';
    }
    if (withMax && max != null && r > max!) {
      return '$label: ${r.toStringAsFixed(2)} > $max';
    }
    return null;
  }
}

double chroma(Color c) => DsOklch.fromColor(c).c;

/// The edge ring of a shadow stack: the crisp outer ring (no blur, no
/// inset), or null when it has none.
Color? ringOf(List<DsShadow> stack) => [
  for (final x in stack)
    if (!x.inset && x.blur == 0 && x.spread > 0 && x.offset == Offset.zero)
      x.color,
].firstOrNull;

/// The inner edge of a shadow stack: the crisp inset ring, or null.
Color? innerRingOf(List<DsShadow> stack) => [
  for (final x in stack)
    if (x.inset && x.blur == 0 && x.spread > 0 && x.offset == Offset.zero)
      x.color,
].firstOrNull;

/// What separates the switch knob from the on [track]: the knob itself, or
/// the crisp edge of `knobOn` when that stands off the track more.
Color knobEdge(DsColors k, DsShadows s, Color track) {
  final edge = ringOf(s.knobOn);
  if (edge == null) return k.knob;
  double on(Color c) =>
      DsColorUtils.contrastRatio(c, track, backdrop: k.surface);
  return on(edge) > on(k.knob) ? edge : k.knob;
}

/// Whether the palette took the bright-accent branch: a dark label on the
/// accent.
bool isBright(DsColors k) =>
    DsColorUtils.luminance(k.onAccent) < DsColorUtils.luminance(k.accent);

List<Rule> rules(
  DsColors k,
  DsShadows s, {
  required bool dark,
  DsContrast level = DsContrast.standard,
}) {
  final soft = level == DsContrast.soft;
  // A form control's boundary: 3:1 (WCAG 1.4.11), or soft's iOS floor.
  final boundary = soft ? softBoundaryMin : 3.0;
  final backgrounds = {
    'canvas': k.canvas,
    'surface': k.surface,
    'control': k.control,
    'overlay': k.overlay,
  };
  return [
    // Text
    Rule('text on surface', k.text, k.surface, min: 7, max: dark ? 13 : null),
    for (final MapEntry(key: name, value: bg) in backgrounds.entries) ...[
      Rule('textMuted on $name', k.textMuted, bg, min: 4.5),
      Rule('textSubtle on $name', k.textSubtle, bg, min: 4.5),
    ],
    // Links sit on pages, cards and floating layers (a link in a popover,
    // dialog or panel).
    for (final bg in ['canvas', 'surface', 'overlay'])
      Rule('link on $bg', k.link, backgrounds[bg]!, min: 4.5),
    for (final bg in ['canvas', 'surface'])
      Rule('accentText on $bg', k.accentText, backgrounds[bg]!, min: 4.5),
    // Labels on fills, hover included
    Rule(
      'onAccent on accent',
      k.onAccent,
      k.accent,
      backdrop: k.surface,
      min: 4.5,
    ),
    Rule(
      'onAccent on accentHover',
      k.onAccent,
      k.accentHover,
      backdrop: k.surface,
      min: 4.5,
    ),
    Rule(
      'onAccent on accentPress',
      k.onAccent,
      k.accentPress,
      backdrop: k.surface,
      min: 4.5,
    ),
    Rule(
      'onSelection on selection',
      k.onSelection,
      k.selection,
      backdrop: k.surface,
      min: 4.5,
    ),
    Rule(
      'onSelection on selectionHover',
      k.onSelection,
      k.selectionHover,
      backdrop: k.surface,
      min: 4.5,
    ),
    Rule(
      'onSelectionStrong on selectionStrong',
      k.onSelectionStrong,
      k.selectionStrong,
      backdrop: k.surface,
      min: 4.5,
    ),
    Rule(
      'onSelectionStrong on selectionStrongHover',
      k.onSelectionStrong,
      k.selectionStrongHover,
      backdrop: k.surface,
      min: 4.5,
    ),
    // Secondary text on highlighted rows in floating layers: select
    // details on the highlighted option, menu shortcuts. Components use
    // textMuted there; textSubtle is for resting rows.
    Rule(
      'textMuted on selection (overlay)',
      k.textMuted,
      k.selection,
      backdrop: k.overlay,
      min: 4.5,
    ),
    // A destructive menu row's highlight is its danger tint in light mode
    // and the neutral tint in dark mode: the shortcut keeps textMuted there
    // too.
    Rule(
      'textMuted on destructive highlight (overlay, menu shortcut)',
      k.textMuted,
      dark ? k.hover : k.danger.tint,
      backdrop: k.overlay,
      min: 4.5,
    ),
    Rule(
      'onTooltipMuted on tooltip',
      k.onTooltipMuted,
      k.tooltip,
      backdrop: k.surface,
      min: 4.5,
    ),
    Rule(
      'danger.onFill on fill',
      k.danger.onFill,
      k.danger.fill,
      backdrop: k.surface,
      min: 4.5,
    ),
    Rule(
      'danger.onFill on fillHover',
      k.danger.onFill,
      k.danger.fillHover,
      backdrop: k.surface,
      min: 4.5,
    ),
    Rule(
      'danger.onFill on fillPress',
      k.danger.onFill,
      k.danger.fillPress,
      backdrop: k.surface,
      min: 4.5,
    ),
    Rule(
      'text on controlPress',
      k.text,
      k.controlPress,
      backdrop: k.surface,
      min: 7,
    ),
    Rule(
      'onTooltip on tooltip',
      k.onTooltip,
      k.tooltip,
      backdrop: k.surface,
      min: 4.5,
    ),
    // Status
    for (final (name, st) in statuses(k)) ...[
      Rule(
        '$name.text on tint',
        st.text,
        st.tint,
        backdrop: k.surface,
        min: 4.5,
      ),
      Rule('$name.text on surface', st.text, k.surface, min: 4.5),
      Rule('$name.text on overlay', st.text, k.overlay, min: 4.5),
      // In dark mode badges, the soft danger button, the destructive menu
      // highlight and the dialog's icon box are neutral with status ink.
      if (dark)
        for (final (state, fill) in [
          ('control', k.control),
          ('controlHover', k.controlHover),
          ('controlPress', k.controlPress),
          ('hover', k.hover),
        ])
          for (final (layer, backdrop) in [
            ('surface', k.surface),
            ('overlay', k.overlay),
          ])
            Rule(
              '$name.text on $state ($layer)',
              st.text,
              fill,
              backdrop: backdrop,
              min: 4.5,
            ),
      // Destructive menu rows: status text on its tint in a floating layer.
      Rule(
        '$name.text on tint (overlay)',
        st.text,
        st.tint,
        backdrop: k.overlay,
        min: 4.5,
      ),
      Rule(
        '$name.onFill on fill (icons)',
        st.onFill,
        st.fill,
        backdrop: k.surface,
        min: 3,
      ),
      // A pressed soft button keeps its label legible.
      for (final (state, tint) in [
        ('tintHover', st.tintHover),
        ('tintPress', st.tintPress),
      ])
        Rule(
          '$name.text on $state',
          st.text,
          tint,
          backdrop: k.surface,
          min: 4.5,
        ),
      Rule(
        '$name.onFill on fillPress (icons)',
        st.onFill,
        st.fillPress,
        backdrop: k.surface,
        min: 3,
      ),
      // The vivid mark color (dots, alert and toast icons) stands 3:1 off
      // every layer it sits on (WCAG 1.4.11), and in light mode off its
      // own tint (a light alert's icon).
      for (final MapEntry(key: bg, value: ground) in {
        ...backgrounds,
        'sidebar': k.sidebar,
        if (!dark) '$name.tint': st.tint,
      }.entries)
        Rule('$name.signal on $bg', st.signal, ground, min: 3),
    ],
    // Avatar initials on every tone
    for (var tone = 0; tone < DsAvatar.toneCount; tone++)
      if (DsAvatar.toneColors(k, tone) case (final bg, final fg))
        Rule('avatar tone $tone', fg, bg, backdrop: k.surface, min: 4.5),
    // Disabled: legible but clearly inactive.
    Rule(
      'onDisabled on disabled',
      k.onDisabled,
      k.disabled,
      backdrop: k.canvas,
      min: 3,
      max: 4.5,
    ),
    Rule('disabled on canvas', k.disabled, k.canvas, min: 1.1),
    // Form control boundaries and focus
    Rule(
      'borderField on field',
      k.borderField,
      k.field,
      backdrop: k.surface,
      min: boundary,
    ),
    for (final bg in ['canvas', 'surface'])
      Rule(
        'borderField on $bg',
        k.borderField,
        backgrounds[bg]!,
        min: boundary,
      ),
    Rule('rail on surface', k.rail, k.surface, min: soft ? softRailMin : 3),
    Rule(
      'indicator on channelStrong (progress, slider)',
      k.indicator,
      k.channelStrong,
      backdrop: k.surface,
      min: 3,
    ),
    Rule('channelStrong on surface', k.channelStrong, k.surface, min: 1.15),
    // The empty channel must not vanish on the page either.
    Rule('channelStrong on canvas', k.channelStrong, k.canvas, min: 1.15),
    Rule('rail on canvas', k.rail, k.canvas, min: soft ? softRailMin : 3),
    // Switch knob against both track states. On the accent the knob or its
    // edge stands off the track (`knobOn`): a bright accent (dark label)
    // gives the white knob a dark edge, resting and hovered. At soft
    // contrast the light off track carries a white knob by its shadow, as
    // on iOS ([softCues]).
    Rule(
      'knob on rail (switch off)',
      k.knob,
      k.rail,
      backdrop: k.surface,
      min: soft ? softRailMin : 3,
    ),
    for (final (state, track) in [
      ('accent', k.accent),
      ('accentHover', k.accentHover),
    ])
      Rule(
        'knob edge on $state (switch on)',
        knobEdge(k, s, track),
        track,
        backdrop: k.surface,
        min: 3,
      ),
    // A fill stands off the card at least like a decorative edge, so a
    // bright accent never melts into white.
    Rule('accent on surface', k.accent, k.surface, min: 1.2),
    // A checked control (checked box and radio, on switch, filled
    // selection) stands 3:1 off the page layers a form sits on (page,
    // card, sidebar) at rest (WCAG 1.4.11): its accent fill alone, or
    // blended with `accentEdge` where the fill needs an edge (a bright
    // accent on a light card; a deep red on a dark card). Hovered and
    // pressed only where an edge is drawn: they are momentary, and a dark
    // white-labeled fill darkens on them, so holding them would put a rim
    // on every dark checked control. Not on the dark floating layer or a
    // field well, where a rim would draw lines everywhere; the check mark
    // carries the state there. Every seed, both modes, both levels.
    for (final (fillName, fill) in [
      ('accent', k.accent),
      if (k.accentEdge.a > 0) ...[
        ('accentHover', k.accentHover),
        ('accentPress', k.accentPress),
      ],
      // The strong selection when the accent label is on it (not a
      // near-status seed's own fill under another label).
      if (k.onSelectionStrong == k.onAccent) ...[
        ('selectionStrong', k.selectionStrong),
        if (k.accentEdge.a > 0)
          ('selectionStrongHover', k.selectionStrongHover),
      ],
    ])
      for (final MapEntry(key: name, value: bg) in {
        'canvas': k.canvas,
        'surface': k.surface,
        'sidebar': k.sidebar,
      }.entries)
        Rule(
          'checked $fillName (with its edge) on $name',
          Color.alphaBlend(k.accentEdge, fill),
          bg,
          min: 3,
        ),
    // Unlabeled accent marks (tab underline, caret) use the indicator,
    // which stays 3:1 under a bright accent.
    Rule(
      'indicator on surface (tab underline)',
      k.indicator,
      k.surface,
      min: 3,
    ),
    Rule(
      'indicator on field (caret)',
      k.indicator,
      k.field,
      backdrop: k.surface,
      min: 3,
    ),
    // Text selection in fields and selectable text: the soft
    // selection fill behind unchanged text. The text stays AA on it and
    // the highlight stands off the field.
    Rule(
      'text on the text selection',
      k.text,
      k.selection,
      backdrop: k.field,
      min: 4.5,
    ),
    // A focused text field's edge turns to the focus color, also with
    // the subtle indicator.
    Rule(
      'focus edge on field (focused text field)',
      k.focus,
      k.field,
      backdrop: k.surface,
      min: 3,
    ),
    // A text field's clear button: the cross on its small filled circle.
    Rule(
      'clear button cross on its fill (text field)',
      k.textMuted,
      k.channelStrong,
      backdrop: k.field,
      min: 3,
    ),
    // A search field's shortcut hint (⌘K): text on a hover chip.
    Rule(
      'shortcut hint on its chip (search field)',
      k.textMuted,
      k.hover,
      backdrop: k.control,
      min: 4.5,
    ),
    Rule(
      'text selection on field',
      k.selection,
      DsColorUtils.flatten(k.field, k.surface),
      min: 1.2,
    ),
    for (final bg in ['canvas', 'surface'])
      Rule(
        'focus outline on $bg',
        s.focusOffset.single.color,
        backgrounds[bg]!,
        min: 3,
      ),
    // The ring is the default focus look. Rows draw it inside
    // their edge, over their highlight: a menu row on the overlay, a
    // selected sidebar item on the sidebar.
    Rule(
      'inset focus ring on selection (overlay)',
      k.focus,
      k.selection,
      backdrop: k.overlay,
      min: 3,
    ),
    Rule(
      'inset focus ring on danger.tint (overlay, destructive row)',
      k.focus,
      k.danger.tint,
      backdrop: k.overlay,
      min: 3,
    ),
    // A button inside a popover or the sidebar shows the outline there.
    for (final MapEntry(key: name, value: bg) in {
      'overlay': k.overlay,
      'sidebar': k.sidebar,
    }.entries)
      Rule('focus outline on $name', s.focusOffset.single.color, bg, min: 3),
    Rule(
      'inset focus ring on selection (sidebar)',
      k.focus,
      k.selection,
      backdrop: k.sidebar,
      min: 3,
    ),
    Rule(
      'field error outline on field',
      s.fieldError.single.color,
      k.field,
      backdrop: k.surface,
      min: 3,
    ),
    // Decorative edges: present, never loud (soft: a little fainter, like
    // iOS's chip and button edges, still never gone).
    Rule(
      'border on surface',
      k.border,
      k.surface,
      min: soft ? softDecorativeMin : 1.2,
      max: 1.8,
    ),
    Rule(
      'borderChip on surface',
      k.borderChip,
      k.surface,
      min: soft ? softDecorativeMin : 1.2,
      max: 1.8,
    ),
    Rule(
      'borderControl on control',
      k.borderControl,
      k.control,
      backdrop: k.surface,
      min: soft ? softDecorativeMin : 1.2,
      max: 1.8,
    ),
    // Selected items: hover (and keyboard focus in the opt-in subtle mode)
    // steps visibly from the plain selected look.
    Rule(
      'selectionHover vs selection',
      k.selectionHover,
      DsColorUtils.flatten(k.selection, k.surface),
      min: 1.1,
    ),
    Rule(
      'selectionStrongHover vs selectionStrong',
      k.selectionStrongHover,
      DsColorUtils.flatten(k.selectionStrong, k.surface),
      min: 1.1,
    ),
    // A soft badge or count stands off the card and the page.
    Rule('neutral.tint on surface', k.neutral.tint, k.surface, min: 1.2),
    Rule('neutral.tint on canvas', k.neutral.tint, k.canvas, min: 1.15),
    // Dark elevation and channels
    if (dark) ...[
      // The selection is lighter than every layer it sits on.
      for (final MapEntry(key: name, value: bg) in {
        ...backgrounds,
        'sidebar': k.sidebar,
      }.entries)
        Rule(
          'selection vs $name',
          DsColorUtils.flatten(k.selection, bg),
          bg,
          min: 1.2,
        ),
      Rule('surface on canvas', k.surface, k.canvas, min: 1.2),
      // A date range band reads as a band on a card and in a floating
      // calendar, not as a stray hover (it was 1.18:1).
      for (final (name, bg) in [('surface', k.surface), ('overlay', k.overlay)])
        Rule('range band on $name', k.accentTint, bg, min: 1.3),
      Rule('control on surface', k.control, k.surface, min: 1.2),
      Rule('overlay on surface', k.overlay, k.surface, min: 1.2),
      // The raised thumb stands off its channel on every layer, a floating
      // one included (it vanished there at 1.09:1).
      for (final MapEntry(key: name, value: bg) in backgrounds.entries)
        Rule(
          'channelThumb on channel on $name',
          DsColorUtils.flatten(
            k.channelThumb,
            DsColorUtils.flatten(k.channel, bg),
          ),
          DsColorUtils.flatten(k.channel, bg),
          min: 1.4,
        ),
    ],
    // Channels (segment, skeleton) stand off the card and the page in both
    // modes.
    Rule('channel on surface', k.channel, k.surface, min: 1.15),
    Rule('channel on canvas', k.channel, k.canvas, min: 1.15),
  ];
}

List<(String, DsStatusColors)> statuses(DsColors k) => [
  ('neutral', k.neutral),
  ('danger', k.danger),
  ('success', k.success),
  ('warning', k.warning),
  ('info', k.info),
];

/// Upper chroma bounds for dark mode, so accents never turn neon.
List<String> darkChroma(DsColors k) => [
  for (final (name, c, cap) in [
    // A white-label fill keeps the light fill's chroma up to 0.21
    // (darkKeepsVivid); light mode is never exceeded (darkNotMoreChromatic),
    // and a bright fill keeps 0.15.
    ('accent', k.accent, isBright(k) ? 0.15 : 0.21),
    ('accentHover', k.accentHover, isBright(k) ? 0.15 : 0.21),
    ('accentPress', k.accentPress, isBright(k) ? 0.15 : 0.21),
    ('selectionStrong', k.selectionStrong, isBright(k) ? 0.15 : 0.21),
    ('selectionStrongHover', k.selectionStrongHover, isBright(k) ? 0.15 : 0.21),
    ('link', k.link, 0.11),
    ('focus', k.focus, 0.11),
    // A vivid red like iOS's (was 0.15: a brick red); still no neon.
    ('danger.fill', k.danger.fill, 0.21),
    ('danger.fillHover', k.danger.fillHover, 0.21),
    ('success.fill', k.success.fill, 0.15),
    // A clear amber (was 0.15 at 0.12 drawn: sandy).
    ('warning.fill', k.warning.fill, 0.16),
    ('info.fill', k.info.fill, 0.15),
  ])
    if (chroma(c) > cap + 0.0005)
      '$name chroma ${chroma(c).toStringAsFixed(3)} > $cap',
];

/// A white-label dark accent keeps the light fill's chroma (up to 0.208),
/// so dark mode is as vivid as light mode, like iOS's blue. (The target
/// used to be 85% of the light chroma, at least 0.148: the dark blue read
/// dusty.)
List<String> darkKeepsVivid(DsColors light, DsColors dark) {
  final l = chroma(light.accent), d = chroma(dark.accent);
  // Neutral seeds have no chroma to keep.
  if (isBright(dark) || l < .03) return const [];
  final want = math.min(l, .208);
  // What sRGB can show at the dark fill's lightness and hue. The engine
  // clips like CSS, which takes up to ~20% more than fitting on deep,
  // saturated cyan-blues; a cap like the old 0.148 still fails (blue:
  // 0.148 < 0.157).
  final at = DsOklch.fromColor(dark.accent);
  final floor = DsOklch(at.l, want, at.h).fitted().c * .8 - .004;
  return [
    if (d < floor)
      'dark accent chroma ${d.toStringAsFixed(3)} < ${floor.toStringAsFixed(3)}',
  ];
}

/// The dark accent family is never more saturated than in light mode
/// (`açık moddakini de aşmaz`): the accent fill and its hover and press
/// against the light accent fill, the strong selection and its hover
/// against the light strong selection.
List<String> darkNotMoreChromatic(DsColors light, DsColors dark) => [
  for (final (name, d, l) in [
    ('accent', dark.accent, light.accent),
    ('accentHover', dark.accentHover, light.accent),
    ('accentPress', dark.accentPress, light.accent),
    ('selectionStrong', dark.selectionStrong, light.selectionStrong),
    ('selectionStrongHover', dark.selectionStrongHover, light.selectionStrong),
  ])
    if (chroma(d) > chroma(l) + 0.003)
      'dark $name chroma ${chroma(d).toStringAsFixed(3)} > light '
          '${chroma(l).toStringAsFixed(3)}',
];

/// The status signals are vivid like iOS's system colors, never dusty and
/// never neon: chroma between [signalChromaMin] and [signalChromaMax] in
/// both modes (neutral excepted). Cyan-leaning info has the least room in
/// sRGB at a 3:1 lightness (about 0.11 in light mode).
const signalChromaMin = .10, signalChromaMax = .23;

List<String> signalChroma(DsColors k) => [
  for (final (name, st) in statuses(k))
    if (name != 'neutral')
      if (chroma(st.signal) case final c
          when c < signalChromaMin - .0005 || c > signalChromaMax + .0005)
        '$name.signal chroma ${c.toStringAsFixed(3)} outside '
            '$signalChromaMin–$signalChromaMax',
];

final _cusps = <int, double>{};

/// The lightness at which [hue] reaches its highest chroma in sRGB.
double cuspLightness(double hue) => _cusps.putIfAbsent(hue.round() % 360, () {
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

/// Olive, mustard, khaki or brown, a muddy look the palette must never
/// produce: a warm hue, orange to yellow-green (50–125°), more than
/// 0.12 below the lightness where that hue is most vivid. A dark yellow is
/// olive and a dark amber mustard whatever their chroma; a deep blue,
/// green or red keeps its hue. Below 0.015 chroma a color is a gray.
bool isMuddy(Color color) {
  final v = DsOklch.fromColor(color);
  return v.c >= .015 &&
      v.h >= 50 &&
      v.h <= 125 &&
      v.l < cuspLightness(v.h) - .12;
}

/// Marks with no label on them stay clean in every seed: the
/// progress, slider and tab mark (`indicator`, both modes; a neutral
/// seed's is its own gray), the light focus outline where it is the
/// indicator, the date range band and icon box
/// (`accentTint` on a card and a floating layer), and every avatar tone.
/// Avatar tones past the first (the selection pair) also keep off the
/// hues that read as khaki, sage or olive at their lightness (55–135°),
/// and on a dark tone off those that read as brown or maroon (355–55°).
List<String> markFailures(DsColors k, {required bool dark}) => [
  // A neutral seed's indicator is the brand's own gray.
  if (chroma(k.indicator) >= .03) ...[
    if (isMuddy(k.indicator)) 'indicator is muddy (${_hex(k.indicator)})',
    if (!dark && k.focus == k.indicator && isMuddy(k.focus)) 'focus is muddy',
  ],
  for (final (name, bg) in [('surface', k.surface), ('overlay', k.overlay)])
    if (DsColorUtils.flatten(k.accentTint, bg) case final band
        when isMuddy(band))
      'accentTint on $name is muddy (${_hex(band)})',
  for (var tone = 0; tone < DsAvatar.toneCount; tone++)
    if (DsAvatar.toneColors(k, tone).$1 case final bg) ...[
      // Tone 0 is the selection pair; a near-neutral seed's is its own
      // gray, warm or not.
      if ((tone > 0 || chroma(bg) >= .03) &&
          isMuddy(DsColorUtils.flatten(bg, k.surface)))
        'avatar tone $tone is muddy (${_hex(bg)})',
      if (tone > 0 && _muddyAvatarHue(DsOklch.fromColor(bg), dark: dark))
        'avatar tone $tone hue ${DsOklch.fromColor(bg).h.round()} reads as '
            'mud',
    ],
];

bool _muddyAvatarHue(DsOklch v, {required bool dark}) =>
    v.c >= .015 &&
    ((v.h >= 55 && v.h < 135) || (dark && (v.h >= 355 || v.h < 55)));

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// An accent edge only where the fill needs one: when every accent fill
/// (and the strong selection drawn in it) already stands 3:1 off every
/// layer, it draws none. (This replaces "no edge on a white-labeled
/// fill": in dark mode a deep red white-labeled fill sits under 3:1 on
/// the card and wears a faint light edge.)
List<String> accentEdgeOnlyWhereNeeded(DsColors k) {
  if (k.accentEdge.a == 0) return const [];
  // The resting fills decide whether a rim is needed.
  final fills = [
    k.accent,
    if (k.onSelectionStrong == k.onAccent) k.selectionStrong,
  ];
  final grounds = [k.canvas, k.surface, k.sidebar];
  final needed = fills.any(
    (fill) => grounds.any(
      (ground) => DsColorUtils.contrastRatio(fill, ground) < 3.05,
    ),
  );
  return [if (!needed) 'accentEdge on a fill that stands on its own'];
}

/// Pairs that come from component styles, checked over every seed like the
/// palette rules (they used to run on three presets in component tests).
List<String> componentFailures(DsThemeData t) {
  final k = t.colors;
  final slider = DsSlider.defaultStyle(t);
  final offHover = DsSwitch.offHover(t);
  final rangeEdge = DsCalendar.defaultStyle(t).rangeEdgeColor;
  final card = DsCard.defaultStyle(t);
  final zone = DsFileUpload.defaultStyle(t);
  DsButtonStyle button(DsButtonVariant variant) =>
      DsButton.defaultStyle(t, variant: variant, size: DsSize.md);
  List<(String, DsButtonStyle)> shades(DsButtonStyle s) => [
    ('rest', s),
    ('hovered', s.resolve({WidgetState.hovered})),
    ('pressed', s.resolve({WidgetState.pressed})),
  ];
  final tinted = button(DsButtonVariant.tinted);
  final neutral = button(DsButtonVariant.neutral);
  final inverse = button(DsButtonVariant.inverse);
  final inverseRest = DsColorUtils.contrastRatio(
    inverse.foreground!,
    inverse.background!,
  );
  final inverseOff = inverse.resolve({WidgetState.disabled});
  return [
    for (final r in [
      // The tinted button's accent ink on its wash, at rest, hovered and
      // pressed, over every layer a button sits on.
      for (final (state, s) in shades(tinted))
        for (final (name, bg) in [
          ('canvas', k.canvas),
          ('surface', k.surface),
          ('sidebar', k.sidebar),
          ('overlay', k.overlay),
        ])
          Rule(
            'tinted button label $state on $name',
            s.foreground!,
            s.background!,
            backdrop: bg,
            min: 4.5,
          ),
      // The neutral button: the inverse ink on the ink, resting, hovered
      // and pressed. Hover and press move the fill toward the label, which
      // the budget allows only while the label stays at 7:1.
      for (final (state, s) in shades(neutral))
        for (final (name, bg) in [
          ('canvas', k.canvas),
          ('surface', k.surface),
          ('overlay', k.overlay),
        ])
          Rule(
            'neutral button label $state on $name',
            s.foreground!,
            s.background!,
            backdrop: bg,
            min: 7,
          ),
      // The ink fill stands off the layers it sits on like a control edge.
      for (final (name, bg) in [
        ('canvas', k.canvas),
        ('surface', k.surface),
        ('overlay', k.overlay),
      ])
        Rule('neutral button fill on $name', neutral.background!, bg, min: 3),
      // The inverse button on the accent ground it is made for: its accent
      // label at 4.5:1, resting, hovered and pressed, and hover and press
      // never weaker than rest below 7:1.
      for (final (state, s) in shades(inverse))
        Rule(
          'inverse button label $state on accent',
          s.foreground!,
          s.background!,
          backdrop: k.accent,
          min: state == 'rest' ? 4.5 : math.max(4.5, math.min(inverseRest, 7)),
        ),
      // Its fill stands off the accent, and so does its focus ring, which
      // the theme's focus color (the accent's ink) would not.
      Rule(
        'inverse button fill on accent',
        inverse.background!,
        k.accent,
        min: 3,
      ),
      Rule(
        'inverse button focus ring on accent',
        inverse.focusShadows!.firstWhere((x) => x.isOutline).color,
        k.accent,
        min: 3,
      ),
      // Disabled on the accent: legible but clearly inactive (3:1).
      Rule(
        'inverse button disabled label on accent',
        inverseOff.foreground!,
        inverseOff.background!,
        backdrop: k.accent,
        min: 3,
      ),
      // The file drop zone's dashed edge, the same way.
      for (final (state, s) in [
        ('rest', zone),
        ('hovered', zone.resolve({WidgetState.hovered})),
        ('pressed', zone.resolve({WidgetState.pressed})),
      ])
        Rule(
          'drop zone edge $state',
          s.borderColor!,
          s.background!,
          min: t.contrast == DsContrast.soft ? softBoundaryMin : 3,
        ),
      // The dashed card's edge: a form boundary on the page, also over its
      // hover and press fills.
      for (final (state, s) in [
        ('rest', card.resolve(const {}, dashed: true)),
        ('hovered', card.resolve({WidgetState.hovered}, dashed: true)),
        ('pressed', card.resolve({WidgetState.pressed}, dashed: true)),
      ])
        for (final (name, bg) in [('canvas', k.canvas), ('surface', k.surface)])
          Rule(
            'dashed card edge $state on $name',
            s.borderColor!,
            DsColorUtils.flatten(s.background!, bg),
            min: t.contrast == DsContrast.soft ? softBoundaryMin : 3,
          ),
      // A slider tick on the filled part.
      Rule(
        'slider tick on fill',
        slider.tickFilledColor!,
        slider.fillColor!,
        backdrop: k.surface,
        min: 3,
      ),
      // The switch knob over the hovered off track, and the hover a
      // visible step from the rest.
      if (t.contrast != DsContrast.soft)
        Rule(
          'switch knob on off-hover track',
          k.knob,
          offHover,
          backdrop: k.surface,
          min: 3,
        ),
      Rule(
        'switch off-hover vs rail',
        offHover,
        k.rail,
        backdrop: k.surface,
        min: 1.15,
      ),
      // The chosen option's check on the popup and on the highlighted row.
      Rule('option check on overlay', k.accentText, k.overlay, min: 3),
      Rule('option check on highlight', k.accentText, k.selection, min: 3),
      // Date range band: days and today on the band. No line runs
      // along it at any level.
      for (final (name, ink) in [
        ('text', k.text),
        ('accentText', k.accentText),
      ])
        Rule(
          '$name on range band',
          ink,
          DsColorUtils.flatten(k.accentTint, k.overlay),
          min: 4.5,
        ),
      // A soft switch's hover and knob, as the resting off track.
      if (t.contrast == DsContrast.soft)
        Rule(
          'switch knob on off-hover track (soft)',
          k.knob,
          offHover,
          backdrop: k.surface,
          min: softRailMin,
        ),
    ])
      ?r.check(withMax: false),
    if (rangeEdge != null && rangeEdge.a > 0)
      'the range band draws an edge (none at any level)',
    if (t.selectedEdge != null && t.colors.accentEdge.a == 0)
      'a selected item draws an edge its fill does not need',
    ...tagFailures(t),
  ];
}

/// Hover never lowers label contrast, unless the label stays at 7:1
/// (a near-black fill cannot darken, so it lightens).
List<String> hoverRaisesContrast(DsColors k) => [
  for (final (name, label, fill, hover) in [
    ('accent', k.onAccent, k.accent, k.accentHover),
    (
      'selectionStrong',
      k.onSelectionStrong,
      k.selectionStrong,
      k.selectionStrongHover,
    ),
    ('danger', k.danger.onFill, k.danger.fill, k.danger.fillHover),
  ])
    if (DsColorUtils.contrastRatio(label, hover, backdrop: k.surface) + 0.01 <
            DsColorUtils.contrastRatio(label, fill, backdrop: k.surface) &&
        DsColorUtils.contrastRatio(label, hover, backdrop: k.surface) < 7)
      '$name hover lowers label contrast',
];

/// Pressed goes one step beyond hover: further from the resting
/// fill than hover is, so a press never looks lighter than a hover; and on
/// a labeled fill, further from the label too, unless the label
/// stays at 7:1.
List<String> pressBeyondHover(DsColors k) {
  double cr(Color a, Color b) => DsColorUtils.contrastRatio(
    DsColorUtils.flatten(a, k.surface),
    DsColorUtils.flatten(b, k.surface),
  );
  return [
    for (final (name, label, fill, hover, press) in [
      ('accent', k.onAccent, k.accent, k.accentHover, k.accentPress),
      ('control', k.text, k.control, k.controlHover, k.controlPress),
      for (final (n, st) in statuses(k)) ...[
        ('$n.fill', st.onFill, st.fill, st.fillHover, st.fillPress),
        ('$n.tint', st.text, st.tint, st.tintHover, st.tintPress),
      ],
    ]) ...[
      if (cr(press, fill) < cr(hover, fill) + 0.02)
        '$name press is no deeper than hover',
      if (!name.endsWith('.tint') &&
          cr(label, press) + 0.01 < cr(label, hover) &&
          cr(label, press) < 7)
        '$name press moves toward its label',
    ],
  ];
}

/// Soft contrast's floor for a form control's boundary (field, checkbox
/// and radio edge): iOS-faint, never gone.
const softBoundaryMin = 1.3;

/// Soft contrast's floor for the switch's off track and the knob on it.
const softRailMin = 1.2;

/// Soft contrast's floor for decorative edges (separators, chips, the
/// secondary button).
const softDecorativeMin = 1.12;

/// Soft contrast keeps a non-color cue where a boundary is faint: the
/// field's edge line, the knob's shadow on the off track, the slider
/// thumb's shadow.
List<String> softCues(DsShadows s, DsColors k) => [
  if (k.borderField.a == 0) 'soft: the field has no edge line',
  if (!s.knob.any((x) => x.blur > 0 && !x.inset))
    'soft: the knob has no shadow',
];

/// Every budget failure of one palette.
List<String> budgetFailures(
  DsPalette p, {
  required bool dark,
  required DsContrast level,
}) => [
  for (final r in rules(p.colors, p.shadows, dark: dark, level: level))
    ?r.check(withMax: true),
  if (dark) ...darkChroma(p.colors),
  if (level == DsContrast.soft) ...softCues(p.shadows, p.colors),
  ...hoverRaisesContrast(p.colors),
  ...pressBeyondHover(p.colors),
  ...accentEdgeOnlyWhereNeeded(p.colors),
  ...signalChroma(p.colors),
  ...markFailures(p.colors, dark: dark),
];

/// Soft contrast only relaxes boundaries: every text role is exactly
/// standard's, and no boundary is stronger than standard's.
List<String> softKeepsText(DsPalette std, DsPalette soft) {
  final a = std.colors, b = soft.colors;
  final same = <String, Color Function(DsColors)>{
    'text': (k) => k.text,
    'textMuted': (k) => k.textMuted,
    'textSubtle': (k) => k.textSubtle,
    'link': (k) => k.link,
    'accentText': (k) => k.accentText,
    'onSelection': (k) => k.onSelection,
    'onDisabled': (k) => k.onDisabled,
    'focus': (k) => k.focus,
    for (final (name, _) in statuses(a))
      '$name.text': (k) => statuses(k).firstWhere((e) => e.$1 == name).$2.text,
  };
  double on(Color fg, DsColors k) => DsColorUtils.contrastRatio(fg, k.surface);
  final edges = <String, Color Function(DsColors)>{
    'border': (k) => k.border,
    'borderControl': (k) => k.borderControl,
    'borderField': (k) => k.borderField,
    'borderChip': (k) => k.borderChip,
    'rail': (k) => k.rail,
  };
  return [
    for (final MapEntry(key: name, value: get) in same.entries)
      if (get(a) != get(b)) '$name differs at soft contrast',
    for (final MapEntry(key: name, value: get) in edges.entries)
      if (on(get(b), b) > on(get(a), a) + 0.01)
        '$name is stronger at soft contrast',
  ];
}

/// The multi-select tags, read from the component's default style:
/// labels 4.5:1 and the remove cross 3:1 on resting and active tags, the
/// active tag apart from the rest. No tag draws an edge its fill does not
/// need, at any level.
List<String> tagFailures(DsThemeData t) {
  final failures = <String>[];
  void need(String what, Color fg, Color bg, Color well, double min) {
    // Translucent colors lie over the fill, the fill over the well.
    final under = DsColorUtils.flatten(bg, well);
    final r = DsColorUtils.contrastRatio(
      DsColorUtils.flatten(fg, under),
      under,
    );
    if (r < min) failures.add('$what: ${r.toStringAsFixed(2)} < $min');
  }

  final defaults = DsAutocomplete.defaultStyle(t);
  DsAutocompleteStyle tag(Set<WidgetState> states) =>
      DsAutocompleteStyle.resolveLayers([defaults], states);
  final field = DsTextField.defaultStyle(t);
  final well = field.background!;

  for (final (name, s) in [
    ('tag', tag(const {})),
    ('active tag', tag(const {WidgetState.selected})),
  ]) {
    final fill = s.tagBackground!;
    need('$name label', s.tagForeground!, fill, well, 4.5);
    final remove = s.tagRemoveStyle!;
    need('$name remove cross', remove.foreground!, fill, well, 3);
    for (final state in [WidgetState.hovered, WidgetState.pressed]) {
      final r = remove.resolve({state});
      // The button's fill lies over the tag's.
      final under = DsColorUtils.flatten(r.background!, fill);
      need('$name remove cross ${state.name}', r.foreground!, under, well, 3);
    }
  }

  // The active tag is told apart by more than its label color: by its
  // fill, or (a bright accent, near the gray in lightness) by its edge.
  final rest = DsColorUtils.flatten(tag(const {}).tagBackground!, well);
  final activeStyle = tag(const {WidgetState.selected});
  final active = DsColorUtils.flatten(activeStyle.tagBackground!, well);
  final activeEdge = DsColorUtils.flatten(activeStyle.tagBorderColor!, active);
  final apart = [
    DsColorUtils.contrastRatio(rest, active),
    DsColorUtils.contrastRatio(rest, activeEdge),
  ].reduce((a, b) => a > b ? a : b);
  if (apart < 1.5) {
    failures.add('active tag vs tag: ${apart.toStringAsFixed(2)} < 1.5');
  }

  for (final (name, s) in [
    ('tag', tag(const {})),
    ('disabled tag', tag(const {WidgetState.disabled})),
  ]) {
    if (s.tagBorderColor!.a > 0) failures.add('$name draws an edge');
  }
  return failures;
}
