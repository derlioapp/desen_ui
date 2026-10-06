import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import 'common.dart';

/// How one seed becomes every color role, with live swatches and a seed
/// playground.
class ColorsPage extends StatelessWidget {
  const ColorsPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Foundations',
    title: 'Colors',
    lead:
        'Every color in a theme comes from one brand color, the seed. The '
        'palette engine works in OKLCH and measures contrast as it goes, so '
        'any brand color gives readable text and visible controls in light '
        'and dark mode, at every contrast level.',
    sections: [
      DocSection(
        title: 'One seed, every role',
        children: [
          const DocText(
            'Give the theme a brand color with `DsSeed.color`. Desen reads '
            'its lightness, chroma and hue in OKLCH, a color space where '
            'equal steps look equal. Each brand role (accent, selection, '
            'links, focus) is a fixed rule on the seed\'s hue: a lightness, a '
            'share of its chroma and an opacity. Neutral roles follow the '
            'same kind of rules on one shared gray. That is why any brand '
            'color yields the same hierarchy.',
          ),
          Example(
            snippet: 'colors-seed',
            padding: const EdgeInsets.all(24),
            child: ThemePreview(
              // #region colors-seed
              theme: DsThemeData(seed: DsSeed.color(const Color(0xFF0F766E))),
              // #endregion
              child: const _Sampler(),
            ),
          ),
          const DocList([
            '**Neutrals belong to no brand.** The page, surfaces, text, '
                'edges, channels and shadows share one cool slate gray (hue '
                '255°, chroma 0.012 or less) whatever the seed: a purple, red '
                'or yellow cast reads as a dirty gray. The brand shows in one '
                'clean accent. A neutral seed, such as `graphite` or a warm '
                'stone gray, is the brand\'s own gray and keeps its hue.',
            '**Contrast is measured, not assumed.** A seed too light for a '
                'white label is darkened, hue kept, until the label reaches '
                '4.5:1. Seeds that already pass, every preset included, keep '
                'their exact color.',
            '**Dark mode is its own palette.** The dark accent keeps the '
                'light one\'s chroma, as iOS does with its blue, so dark mode '
                'is as vivid as light mode; it is never more saturated, and '
                'never above 0.21. A bright fill with a dark label stays at '
                '0.148, so no brand turns neon.',
            '**Status colors have fixed hues.** Danger sits at 27°, success '
                'near 155° and info at 240°. They move only when the seed is '
                'close to them, as the clash rule below describes.',
          ]),
          const DocText(
            'Six seeds ship as presets: `DsSeed.blue` (the default), `navy`, '
            '`graphite`, `oxblood`, `forest` and `indigo`. `DsSeed.oklch(l, '
            'c, h)` takes the values directly.',
          ),
        ],
      ),
      DocSection(
        title: 'Roles',
        children: [
          const DocText(
            'These are the roles of the theme on this page, read live from '
            '`DsTheme.colorsOf(context)`. Each ratio is computed on the spot '
            'against the background the role is meant for. Change the tone, '
            'mode or contrast in the settings at the top and watch them '
            'update.',
          ),
          for (final group in _groups(context)) ...[
            DocHeading(group.title),
            DocText(group.text),
            Board(child: TokenGrid(minWidth: 140, children: group.swatches)),
          ],
          const DocHeading('Status'),
          const DocText(
            'Five statuses share nine roles each: a solid `fill` with '
            '`onFill` on it, hover and pressed steps, a `tint` for badges and '
            'soft buttons, `text` for status-colored text, and `signal`. The '
            'danger label reaches 4.5:1 on its fill. Success, warning and '
            'info fills carry icons and bold labels at 3:1, never body text.',
          ),
          const DocText(
            'A fill has to carry a label, so a green or orange fill is darker '
            'than the status color you picture. `signal` is that vivid color, '
            'like iOS\'s system colors, for marks with no text on them: '
            'status dots, alert and toast icons, the icons of an uploaded '
            'file. It is only as dark (light mode) or as light (dark mode) as '
            '3:1 against the page, the surfaces and floating layers needs. '
            'Never set text in it; that is what `text` is for.',
          ),
          const DocText(
            'The colored tints are opaque in both modes. In light mode they '
            'are soft, clean washes that read the same on the page and on a '
            'card. In dark mode they are deep colors, as saturated as that '
            'depth allows, with vivid status text on them. Alerts do not use '
            'them in dark mode: there an alert is a neutral raised block with '
            'a `signal` icon and a title in `text`, because a large deep '
            'tint reads brown or maroon. The neutral tint, behind tags and '
            'neutral badges, is a translucent slate: light on a card and '
            'still apart from the page.',
          ),
          const Board(child: _Statuses()),
        ],
      ),
      DocSection(
        title: 'The clash rule',
        children: [
          const DocText(
            'A brand red would make a selected row look like an error, and a '
            'brand green like a success. So when the seed lies within 35° of '
            'danger or success, the nearby status color shifts away from the '
            'brand. In light mode the soft selection turns 20° the other way; '
            'in dark mode it is gray, as for every warm brand (below). The '
            'filled selection becomes a darker shade of the brand, and links '
            'and focus use the brand\'s dark ink. A seed with almost no chroma '
            '(below 0.03) is neutral: selection becomes a mid gray with '
            'full-ink text.',
          ),
          const Board(child: _ClashBoard()),
          const DocText(
            'The branch a seed fell into is `DsTheme.of(context).seedRole`: '
            '`free`, `nearStatus`, `neutral`, or `manual` when you turn the '
            'rule off with `autoClashRule: false` and pass your own '
            '`dangerOverride`, `successOverride` and `warningOverride`. '
            'Info moves aside the '
            'same way when the seed sits near 240°, so a blue brand\'s info '
            'badges do not read as brand.',
          ),
        ],
      ),
      const DocSection(
        title: 'Selection in dark mode',
        children: [
          DocText(
            'In light mode the soft selection is a pale tint of the brand. '
            'In dark mode it depends on the hue. Cool brands (hue 180° to '
            '330°: blue, violet, teal) keep a colored selection, with as much '
            'chroma as keeps the faintest text 4.5:1 on it, at most 0.09. '
            'Warm brands (red, orange, yellow, green) would turn brown or '
            'olive that dark and read as status colors, so they select in '
            'the slate gray with the brand in the text. Seeds near danger or '
            'success count as warm.',
          ),
          Board(child: _SelectionModes()),
        ],
      ),
      DocSection(
        title: 'Bright brand colors',
        children: [
          const DocText(
            'Yellow, amber, orange, lime, mint and cyan cannot carry a white '
            'label, but they carry a dark one at 7:1 or more. Desen keeps '
            'such a seed as the fill and labels it with a deep ink tinted '
            'toward the seed. Hover and pressed get lighter, not darker, so '
            'the label gains contrast.',
          ),
          Example(
            snippet: 'colors-bright',
            padding: const EdgeInsets.all(24),
            child: ThemePreview(
              // #region colors-bright
              theme: DsThemeData(seed: DsSeed.color(const Color(0xFFFFC72C))),
              // #endregion
              child: const _Sampler(),
            ),
          ),
          const DocText(
            'Everything without a label on it uses a darkened version of the '
            'seed: the progress fill, the tab underline, the text caret, the '
            'focus outline and accent text. A fill that melts into a white '
            'card gets a 1px `accentEdge`, and the switch knob gets a dark '
            'edge on the bright track. Mid-light seeds such as a light blue '
            'or magenta keep a white label and are darkened instead. In dark '
            'mode a white-labeled fill, held dark by its label, gives checked '
            'controls a faint light `accentEdge`, so they stand 3:1 off the '
            'floating layers too.',
          ),
        ],
      ),
      DocSection(
        title: 'Playground',
        children: [
          const DocText(
            'Pick a color or type a hex value. The palette and the components '
            'below are generated from it with the current mode and contrast.',
          ),
          Example(
            snippet: 'colors-playground',
            padding: const EdgeInsets.all(20),
            alignment: AlignmentDirectional.topStart,
            child: const _Playground(),
          ),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'seed',
              'DsSeed',
              'The brand color. `DsSeed.color(Color)`, `DsSeed.oklch(l, c, '
                  'h)` or a preset. Defaults to `DsSeed.blue`.',
            ),
            (
              'autoClashRule',
              'bool',
              'Shifts danger, success and info away from a seed close to '
                  'them. Defaults to true.',
            ),
            (
              'dangerOverride',
              'Color?',
              'Your own danger color; its shades are derived from it.',
            ),
            (
              'successOverride',
              'Color?',
              'Your own success color; its shades are derived from it.',
            ),
            (
              'warningOverride',
              'Color?',
              'Your own warning color. Its shades are derived from it; it '
                  'keeps the dark label while that reads better than white, '
                  'and its text takes the nearest lightness that reads 4.5:1.',
            ),
            (
              'adjustColors',
              'DsColorsAdjuster?',
              'Edits generated colors, again after every regeneration. See '
                  '[Theming](/theming).',
            ),
            (
              'DsColors.toMap()',
              'Map<String, Color>',
              'Every role by name, status sets expanded.',
            ),
            (
              'DsColorUtils.contrastRatio',
              'double',
              'The WCAG ratio of two colors, translucent ones flattened '
                  'first.',
            ),
          ]),
        ],
      ),
    ],
  );
}

// Roles -------------------------------------------------------------------

/// A contrast check shown under a swatch: [fg] on [bg], with the target.
class _Check {
  const _Check(this.label, this.fg, this.bg, {this.min, this.max});

  final String label;
  final Color fg, bg;
  final double? min, max;
}

class _Group {
  const _Group(this.title, this.text, this.swatches);

  final String title, text;
  final List<Widget> swatches;
}

List<_Group> _groups(BuildContext context) {
  final t = DsTheme.of(context);
  final k = t.colors;
  final soft = t.contrast == DsContrast.soft;
  // Decorative edges have a ceiling: present, never loud.
  _Check edge(Color c, Color on, String label) =>
      _Check(label, c, on, min: soft ? 1.12 : 1.2, max: 1.8);
  // A form control's boundary: 3:1, or soft contrast's iOS-faint floor.
  final boundary = soft ? 1.3 : 3.0, railMin = soft ? 1.2 : 3.0;
  return [
    _Group(
      'Surfaces',
      'Layers from the page up. `canvas` is the page, `surface` holds cards, '
          'lists and tables, `control` is a raised control such as a '
          'secondary button, `overlay` is a menu, popover or dialog, and '
          '`field` is the well of a text field. In dark mode each layer is a '
          'step lighter than the one below it.',
      [
        _Swatch('canvas', k.canvas, ink: k.text, check: _text(k, k.canvas)),
        _Swatch(
          'surface',
          k.surface,
          ink: k.text,
          check: _Check('text', k.text, k.surface, min: 7),
        ),
        _Swatch('sidebar', k.sidebar, ink: k.text, check: _text(k, k.sidebar)),
        _Swatch('control', k.control, ink: k.text, check: _text(k, k.control)),
        _Swatch('overlay', k.overlay, ink: k.text, check: _text(k, k.overlay)),
        _Swatch('field', k.field, ink: k.text, check: _text(k, k.field)),
      ],
    ),
    _Group(
      'Text',
      'Three steps of ink: `text` for content, `textMuted` for secondary '
          'text and field labels, `textSubtle` for placeholders and meta. '
          'The steps sit clearly apart (in light mode about 17, 6.4 and '
          '5.2:1 on a card), so secondary text does not read like body '
          'text. '
          '`link` and `accentText` carry the brand into text. All of them '
          'reach 4.5:1 on the page, surfaces, controls and floating layers; '
          'primary text reaches 7:1 on a surface.',
      [
        _Swatch.ink(
          'text',
          k.text,
          _Check('on surface', k.text, k.surface, min: 7),
        ),
        _Swatch.ink(
          'textMuted',
          k.textMuted,
          _Check('on surface', k.textMuted, k.surface, min: 4.5),
        ),
        _Swatch.ink(
          'textSubtle',
          k.textSubtle,
          _Check('on surface', k.textSubtle, k.surface, min: 4.5),
        ),
        _Swatch.ink(
          'link',
          k.link,
          _Check('on surface', k.link, k.surface, min: 4.5),
        ),
        _Swatch.ink(
          'accentText',
          k.accentText,
          _Check('on surface', k.accentText, k.surface, min: 4.5),
        ),
      ],
    ),
    _Group(
      'Accent',
      'The brand fill and its states. `onAccent` is the label on it: white, '
          'or a dark ink on a bright brand color. `indicator` draws accent '
          'marks with no label (progress and slider fill, tab underline, '
          'caret). `accentTint` is a translucent wash such as a date range '
          'band, and `accentEdge` the 1px edge a checked control wears where '
          'its fill stands under 3:1 off a layer.',
      [
        _Swatch(
          'accent',
          k.accent,
          ink: k.onAccent,
          check: _Check('label', k.onAccent, k.accent, min: 4.5),
        ),
        _Swatch(
          'accentHover',
          k.accentHover,
          ink: k.onAccent,
          check: _Check('label', k.onAccent, k.accentHover, min: 4.5),
        ),
        _Swatch(
          'accentPress',
          k.accentPress,
          ink: k.onAccent,
          check: _Check('label', k.onAccent, k.accentPress, min: 4.5),
        ),
        _Swatch(
          'indicator',
          k.indicator,
          check: _Check('on track', k.indicator, k.channelStrong, min: 3),
        ),
        _Swatch(
          'accentTint',
          k.accentTint,
          ink: k.text,
          check: _Check('text', k.text, k.accentTint, min: 4.5),
        ),
        _Swatch(
          'accentEdge',
          k.accentEdge,
          check: k.accentEdge.a == 0
              ? null
              : _Check(
                  'on surface',
                  DsColorUtils.flatten(k.accentEdge, k.accent),
                  k.surface,
                  min: 3,
                ),
          note: k.accentEdge.a == 0
              ? 'Transparent: the fill stands alone'
              : null,
        ),
      ],
    ),
    _Group(
      'Selection',
      'Selected items. The soft pair (`selection`, `onSelection`) is the '
          'default; the strong pair fills the item when the theme\'s '
          'selection style is `strong`. Each has a hover step, so a selected '
          'item still answers the pointer and shows keyboard focus.',
      [
        _Swatch(
          'selection',
          k.selection,
          ink: k.onSelection,
          check: _Check('label', k.onSelection, k.selection, min: 4.5),
        ),
        _Swatch(
          'selectionHover',
          k.selectionHover,
          ink: k.onSelection,
          check: _Check('label', k.onSelection, k.selectionHover, min: 4.5),
        ),
        _Swatch(
          'selectionStrong',
          k.selectionStrong,
          ink: k.onSelectionStrong,
          check: _Check(
            'label',
            k.onSelectionStrong,
            k.selectionStrong,
            min: 4.5,
          ),
        ),
        _Swatch(
          'selectionStrongHover',
          k.selectionStrongHover,
          ink: k.onSelectionStrong,
          check: _Check(
            'label',
            k.onSelectionStrong,
            k.selectionStrongHover,
            min: 4.5,
          ),
        ),
      ],
    ),
    _Group(
      'Borders and channels',
      'Edges are 1px rings. Decorative edges (`border`, `borderControl`, '
          '`borderChip`) stay between 1.2:1 and 1.8:1, so cards and dividers '
          'stay quiet. Form control boundaries (`borderField`, and `rail`, '
          'the track of a switch that is off) reach 3:1 because they show '
          'where to act; at soft contrast they are as faint as iOS draws '
          'them (about 1.5:1 and 1.3:1). `channel`, '
          'the recess of segmented controls and steppers (and skeleton '
          'blocks), is translucent in both modes: light on a white card, and '
          'still 1.15:1 off the page. `channelStrong` is a step stronger: the '
          'unfilled part of slider and progress tracks.',
      [
        _Swatch(
          'border',
          k.border,
          check: edge(k.border, k.surface, 'on surface'),
        ),
        _Swatch(
          'borderControl',
          k.borderControl,
          check: edge(k.borderControl, k.control, 'on control'),
        ),
        _Swatch(
          'borderChip',
          k.borderChip,
          check: edge(k.borderChip, k.surface, 'on surface'),
        ),
        _Swatch(
          'borderField',
          k.borderField,
          check: _Check('on field', k.borderField, k.field, min: boundary),
        ),
        _Swatch(
          'rail',
          k.rail,
          check: _Check('on surface', k.rail, k.surface, min: railMin),
        ),
        _Swatch(
          'channel',
          k.channel,
          check: _Check('on page', k.channel, k.canvas, min: 1.15),
        ),
        _Swatch(
          'channelStrong',
          k.channelStrong,
          check: _Check('on surface', k.channelStrong, k.surface, min: 1.15),
        ),
      ],
    ),
    _Group(
      'Focus',
      '`focus` draws the keyboard focus outline, a single line, and stands '
          '3:1 off the page and surfaces.',
      [
        _Swatch(
          'focus',
          k.focus,
          check: _Check('on surface', k.focus, k.surface, min: 3),
        ),
      ],
    ),
    _Group(
      'Interaction and overlays',
      '`hover` and `press` are translucent layers laid over whatever is '
          'underneath. Disabled text stays readable (3:1) yet distinct from '
          'enabled text. In light mode the '
          '`disabled` fill is translucent like the track. `scrim` dims the '
          'page under a dialog.',
      [
        _Swatch('hover', k.hover),
        _Swatch('press', k.press),
        _Swatch(
          'disabled',
          k.disabled,
          ink: k.onDisabled,
          check: _Check('label', k.onDisabled, k.disabled, min: 3, max: 4.5),
        ),
        _Swatch('scrim', k.scrim),
        _Swatch(
          'tooltip',
          k.tooltip,
          ink: k.onTooltip,
          check: _Check('label', k.onTooltip, k.tooltip, min: 4.5),
        ),
      ],
    ),
  ];
}

_Check _text(DsColors k, Color on) => _Check('text', k.text, on, min: 4.5);

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color, {this.ink, this.check, this.note})
    : asInk = false;

  /// A text role: drawn as ink on the surface.
  const _Swatch.ink(this.name, this.color, this.check)
    : asInk = true,
      ink = null,
      note = null;

  final String name;
  final Color color;
  final Color? ink;
  final _Check? check;
  final String? note;
  final bool asInk;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final y = t.typography;
    final sample = asInk ? color : ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Container(
          height: 52,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsetsDirectional.only(start: 12),
          alignment: AlignmentDirectional.centerStart,
          decoration: DsBoxDecoration(
            color: asInk ? k.surface : color,
            borderRadius: BorderRadius.circular(
              t.radii.nested(t.radii.card, DsSpace.s16),
            ),
            shadows: [DsShadow.innerRing(k.border)],
          ),
          child: sample == null
              ? null
              : Text('Aa', style: y.heading.copyWith(color: sample)),
        ),
        Text(name, style: y.mono(y.caption).copyWith(color: k.text)),
        Caption(color.a == 0 ? 'transparent' : hexOf(color)),
        if (check case final c?) _Ratio(c),
        if (note case final n?) Caption(n),
      ],
    );
  }
}

class _Ratio extends StatelessWidget {
  const _Ratio(this.check);

  final _Check check;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final r = DsColorUtils.contrastRatio(
      check.fg,
      check.bg,
      backdrop: k.surface,
    );
    final c = check;
    String n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
    final target = switch ((c.min, c.max)) {
      (final min?, final max?) => '${n(min)}–${n(max)}',
      (final min?, null) => '≥ ${n(min)}',
      _ => null,
    };
    final miss = (c.min != null && r < c.min! - .005);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${c.label} ',
            style: TextStyle(color: k.textMuted),
          ),
          TextSpan(
            text: ratioText(r),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: miss ? k.danger.text : k.text,
            ),
          ),
          if (target != null)
            TextSpan(
              text: '  $target',
              style: TextStyle(color: k.textSubtle),
            ),
        ],
      ),
      style: t.typography.caption,
    );
  }
}

class _Statuses extends StatelessWidget {
  const _Statuses();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final y = t.typography;
    return TokenGrid(
      minWidth: 150,
      children: [
        for (final status in DsStatus.values)
          Builder(
            builder: (context) {
              final s = k.status(status);
              final strong = status == DsStatus.danger;
              Widget strip(Color bg, Color ink, String role, double min) =>
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Container(
                        height: 36,
                        padding: const EdgeInsetsDirectional.only(start: 10),
                        alignment: AlignmentDirectional.centerStart,
                        decoration: DsBoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(
                            t.radii.nested(t.radii.card, DsSpace.s16),
                          ),
                        ),
                        child: Text(
                          role,
                          style: y
                              .mono(y.caption)
                              .copyWith(
                                color: ink,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      _Ratio(_Check('', ink, bg, min: min)),
                    ],
                  );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Text(
                    status.name,
                    style: y.labelStrong.copyWith(color: k.text),
                  ),
                  strip(s.fill, s.onFill, 'fill', strong ? 4.5 : 3),
                  strip(s.tint, s.text, 'tint', 4.5),
                  strip(k.surface, s.text, 'text', 4.5),
                  // The signal is never text: shown as a dot, labeled in
                  // muted ink.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Container(
                        height: 36,
                        padding: const EdgeInsetsDirectional.only(start: 10),
                        decoration: DsBoxDecoration(
                          color: k.surface,
                          borderRadius: BorderRadius.circular(
                            t.radii.nested(t.radii.card, DsSpace.s16),
                          ),
                        ),
                        child: Row(
                          spacing: 8,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: DsBoxDecoration(
                                color: s.signal,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            Text(
                              'signal',
                              style: y
                                  .mono(y.caption)
                                  .copyWith(color: k.textMuted),
                            ),
                          ],
                        ),
                      ),
                      _Ratio(_Check('', s.signal, k.surface, min: 3)),
                    ],
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

// Clash rule ----------------------------------------------------------------

class _ClashBoard extends StatelessWidget {
  const _ClashBoard();

  static const _seeds = [
    ('Blue', DsSeed.blue),
    ('Oxblood', DsSeed.oxblood),
    ('Forest', DsSeed.forest),
    ('Graphite', DsSeed.graphite),
  ];

  @override
  Widget build(BuildContext context) {
    final site = DsTheme.of(context);
    final y = site.typography;
    final k = site.colors;
    return TokenGrid(
      minWidth: 150,
      children: [
        for (final (name, seed) in _seeds)
          Builder(
            builder: (context) {
              final theme = DsThemeData(
                seed: seed,
                brightness: site.brightness,
                contrast: site.contrast,
              );
              final c = theme.colors;
              Widget row(String role, Color color) => Row(
                spacing: 8,
                children: [
                  Container(
                    width: 28,
                    height: 20,
                    decoration: DsBoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(
                        site.radii.control(20),
                      ),
                      shadows: [DsShadow.innerRing(k.border)],
                    ),
                  ),
                  Expanded(child: Caption(role, mono: true)),
                  Caption('${DsOklch.fromColor(color).h.round()}°'),
                ],
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Text(name, style: y.labelStrong.copyWith(color: k.text)),
                  Caption(theme.seedRole.name, mono: true, color: k.accentText),
                  row('accent', c.accent),
                  row('selection', c.selection),
                  row('danger', c.danger.fill),
                  row('success', c.success.fill),
                ],
              );
            },
          ),
      ],
    );
  }
}

// Selection in dark mode ----------------------------------------------------

/// A cool and a warm brand's soft selection, light and dark.
class _SelectionModes extends StatelessWidget {
  const _SelectionModes();

  static const _brands = [
    ('Indigo', DsSeed.indigo),
    ('Oxblood', DsSeed.oxblood),
  ];

  @override
  Widget build(BuildContext context) {
    final site = DsTheme.of(context);
    return TokenGrid(
      minWidth: 150,
      runSpacing: 20,
      children: [
        for (final (name, seed) in _brands)
          for (final brightness in [Brightness.light, Brightness.dark])
            Builder(
              builder: (context) {
                final theme = DsThemeData(
                  seed: seed,
                  brightness: brightness,
                  contrast: site.contrast,
                );
                final mode = brightness == Brightness.dark ? 'dark' : 'light';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 6,
                  children: [
                    ThemePreview(
                      theme: theme,
                      followBrightness: false,
                      followContrast: false,
                      followSelection: false,
                      child: const _MiniMenu(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$name, $mode',
                      style: site.typography.labelStrong.copyWith(
                        color: site.colors.text,
                      ),
                    ),
                    Caption(
                      'selection ${hexOf(theme.colors.selection)}',
                      mono: true,
                    ),
                  ],
                );
              },
            ),
      ],
    );
  }
}

/// Three menu rows, the middle one selected, in the ambient theme.
class _MiniMenu extends StatelessWidget {
  const _MiniMenu();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    Widget row(DsIconData icon, String label, {bool selected = false}) =>
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: DsBoxDecoration(
            color: selected ? k.selection : null,
            borderRadius: BorderRadius.circular(t.radii.control(32)),
          ),
          child: Row(
            spacing: 8,
            children: [
              DsIcon(
                icon,
                size: 16,
                color: selected ? k.onSelection : k.textMuted,
              ),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.typography.small.copyWith(
                    color: selected ? k.onSelection : k.text,
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
        );
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: DsBoxDecoration(
          color: k.overlay,
          borderRadius: BorderRadius.circular(t.radii.card),
          shadows: [DsShadow.innerRing(k.border)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 2,
          children: [
            row(DsIcons.inbox, 'Inbox'),
            row(DsIcons.user, 'Assigned', selected: true),
            row(DsIcons.folder, 'Projects'),
          ],
        ),
      ),
    );
  }
}

// Previews ------------------------------------------------------------------

/// A few components that show off a palette: fills, labels, checked
/// controls, a selection, a progress fill and status badges.
class _Sampler extends StatefulWidget {
  const _Sampler();

  @override
  State<_Sampler> createState() => _SamplerState();
}

class _SamplerState extends State<_Sampler> {
  bool _sync = true;
  bool _archived = true;
  String _view = 'board';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 340),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DsButton(onPressed: () {}, child: const Text('Publish')),
            DsButton(
              variant: .secondary,
              onPressed: () {},
              child: const Text('Preview'),
            ),
            DsSegmentedControl<String>(
              value: _view,
              onChanged: (v) => setState(() => _view = v),
              segments: const [
                DsSegment(value: 'board', label: Text('Board')),
                DsSegment(value: 'list', label: Text('List')),
              ],
            ),
          ],
        ),
        DsSwitch(
          value: _sync,
          onChanged: (v) => setState(() => _sync = v),
          label: const Text('Sync across devices'),
        ),
        DsCheckbox(
          value: _archived,
          onChanged: (v) => setState(() => _archived = v ?? false),
          label: const Text('Show archived projects'),
        ),
        const DsProgressBar(value: .64, semanticLabel: 'Upload'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const DsBadge(label: Text('Live'), status: DsStatus.success),
            const DsBadge(label: Text('Review'), status: DsStatus.warning),
            const DsBadge(label: Text('Failed'), status: DsStatus.danger),
            const DsBadge(label: Text('Draft')),
            const SizedBox(width: 4),
            DsLink(label: 'Changelog', onPressed: () {}),
          ],
        ),
      ],
    ),
  );
}

// Playground ----------------------------------------------------------------

class _Playground extends StatefulWidget {
  const _Playground();

  @override
  State<_Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<_Playground> {
  static const _presets = [
    ('Navy', Color(0xFF2D4D8B)),
    ('Teal', Color(0xFF0F766E)),
    ('Violet', Color(0xFF7C3AED)),
    ('Rose', Color(0xFFE11D48)),
    ('Green', Color(0xFF16A34A)),
    ('Amber', Color(0xFFF59E0B)),
    ('Yellow', Color(0xFFFFC72C)),
    ('Sky', Color(0xFF38BDF8)),
    ('Pink', Color(0xFFEC4899)),
    ('Ink', Color(0xFF1F2937)),
  ];

  Color _brand = _presets.first.$2;
  late final _hex = TextEditingController(text: hexOf(_brand));
  bool _invalid = false;

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _pick(Color c) => setState(() {
    _brand = c;
    _invalid = false;
    _hex.text = hexOf(c);
  });

  void _typed(String text) {
    final c = parseHex(text);
    setState(() {
      _invalid = c == null;
      if (c != null) _brand = c;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            DsField(
              label: const Text('Brand color'),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (name, c) in _presets)
                    _ColorDot(
                      name: name,
                      color: c,
                      selected: c == _brand && !_invalid,
                      onPressed: () => _pick(c),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 150,
              child: DsField(
                label: const Text('Hex'),
                errorText: _invalid ? 'Use #RRGGBB' : null,
                child: DsTextField(
                  controller: _hex,
                  onChanged: _typed,
                  placeholder: '#2D4D8B',
                  error: _invalid,
                ),
              ),
            ),
          ],
        ),
        ThemePreview(
          // #region colors-playground
          theme: DsThemeData(seed: DsSeed.color(_brand)),
          // #endregion
          child: const _PlaygroundResult(),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.name,
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return DsTooltip(
      message: name,
      child: DsPressable(
        onPressed: onPressed,
        semanticLabel: name,
        selected: selected,
        builder: (context, states, _) => Container(
          width: 28,
          height: 28,
          decoration: DsBoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            shadows: [
              if (states.contains(WidgetState.focused)) ...t.focusShadows,
              if (selected) ...[
                DsShadow.ring(k.text, width: 2),
                DsShadow.innerRing(k.surface, width: 2),
              ] else
                DsShadow.innerRing(k.border),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaygroundResult extends StatelessWidget {
  const _PlaygroundResult();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final roles = [
      ('accent', k.accent),
      ('accentHover', k.accentHover),
      ('indicator', k.indicator),
      ('link', k.link),
      ('selection', k.selection),
      ('selectionStrong', k.selectionStrong),
      ('focus', k.focus),
      ('danger', k.danger.fill),
      ('success', k.success.fill),
      ('warning', k.warning.fill),
      ('info', k.info.fill),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DsBoxDecoration(
        color: k.canvas,
        borderRadius: BorderRadius.circular(t.radii.card),
        shadows: [DsShadow.innerRing(k.border)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Caption('Seed role', color: k.textMuted),
              Caption(t.seedRole.name, mono: true, color: k.text),
              Caption(
                'onAccent on accent '
                '${ratioText(DsColorUtils.contrastRatio(k.onAccent, k.accent))}',
                color: k.textMuted,
              ),
            ],
          ),
          TokenGrid(
            minWidth: 116,
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final (name, color) in roles)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Container(
                      height: 32,
                      decoration: DsBoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(
                          t.radii.nested(t.radii.card, DsSpace.s16),
                        ),
                        shadows: [DsShadow.innerRing(k.border)],
                      ),
                    ),
                    Caption(name, mono: true),
                  ],
                ),
            ],
          ),
          const _Sampler(),
        ],
      ),
    );
  }
}
