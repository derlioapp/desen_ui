import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import 'common.dart';

/// The corner rules across the corner styles, continuous corners,
/// hairlines, shadow stacks and `DsBoxDecoration`.
class CornersPage extends StatelessWidget {
  const CornersPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Foundations',
    title: 'Corners and shadows',
    lead:
        'Three rules give every corner, the corner style picks their '
        'numbers, and corners are continuous, as on Apple platforms. '
        'Edges, elevation and '
        'focus rings are shadows, drawn by `DsBoxDecoration`, which also '
        'paints inset shadows the way CSS does. Decorative lines are '
        'hairlines, one device pixel wide.',
    sections: [
      const DocSection(
        title: 'Three rules',
        children: [
          DocText(
            'Desen keeps no list of radii per component. Every corner comes '
            'from one of three rules, and `DsRadii` holds their numbers.',
          ),
          DocText(
            '**Controls are rounded by their height.** A button, a text '
            'field, a select, a chip, a segmented control, a tooltip, a '
            'calendar day, an icon box or the floating bottom navigation '
            'takes its height times a factor: `radii.control(height)`. At '
            'the standard 0.25 a 40px control gets 10, a 28px one 7 and a '
            '48px one 12, so a small button is not nearly a capsule while '
            'a large one looks boxy. A field and a button of the same '
            'height always match. At 0.5 every control is a capsule. '
            'The height is the one the control ends up with: a style that '
            'only sets `height: 56` gets 14px corners (a capsule in the '
            'pill style), while a `borderRadius` set in a style always '
            'wins.',
          ),
          DocText(
            '**Containers have one radius.** Cards, list sections, tables '
            'and alerts use `radii.card`; floating layers (menus, popovers, '
            'dialogs, panels, toasts) use `radii.overlay`. Both are 14 by '
            'default, whatever the size of the box, and neither ever turns '
            'into a capsule.',
          ),
          DocText(
            '**Nested pieces follow what holds them.** A piece inset inside '
            'another takes the outer radius minus the inset: '
            '`radii.nested(outer, inset)`. Its corners run parallel to the '
            'outer ones instead of looking fatter. A segmented control\'s '
            'thumb, a stepper\'s buttons, menu and list rows, toolbar '
            'toggles, bottom-navigation items, tags in a multi-select '
            'field and media in a card all follow it. When the inset is as '
            'large as the radius, a small floor (`nestedMin`) keeps the '
            'piece from going square, and inside a capsule the piece is a '
            'capsule too.',
          ),
          DocText(
            'The checkbox is the one exception: `radii.checkbox(size)` '
            'rounds it by its own size, and never past a third of it, so '
            'it cannot be mistaken for a radio button.',
          ),
        ],
      ),
      DocSection(
        title: 'Corner styles',
        children: [
          const DocText(
            'The corner style is an end-user setting that only changes the '
            'numbers. `sharp` rounds controls by a tenth of their height '
            'and containers by 4. `standard`, the default, by a quarter and '
            '14. `soft` by three eighths and 21. `pill` makes every control '
            'a capsule, text fields included, while cards and floating '
            'layers keep the standard 14. Each row below is the same set of '
            'components in one style.',
          ),
          Example(
            snippet: 'corners-style',
            padding: const EdgeInsets.all(24),
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 28,
              children: [
                for (final style in DsCornerStyle.values)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Caption(style.name, mono: true),
                      ThemePreview(
                        followCorners: false,
                        // #region corners-style
                        theme: DsThemeData(cornerStyle: style),
                        // #endregion
                        child: const _CornerRow(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'The numbers',
        children: [
          DocText(
            'The table is computed from `DsRadii.forStyle`, so it always '
            'shows what components draw. A capsule is a radius of half the '
            'height.',
          ),
          _RadiusTable(),
        ],
      ),
      DocSection(
        title: 'Continuous corners',
        children: [
          const DocText(
            'A rounded box is a rounded superellipse rather than a rectangle '
            'with quarter circles at the corners: the curve leaves the '
            'straight edge gradually, so there is no visible kink where the '
            'arc starts. At the same radius a continuous corner looks a '
            'little tighter than a circular one. Fully round shapes are the '
            'exception: when a corner reaches half the shorter side '
            '(capsules, circles, the round end of a range band) the ends stay '
            'true half circles.',
          ),
          const DocText(
            'Every rounded box in Desen takes this shape: fills, rings, '
            'shadows, focus rings, clips and hit testing all follow the same '
            'outline, so an edge always stays concentric with its fill. '
            'Your own boxes get it by using `DsBoxDecoration`, and '
            '`DsShapeClip` clips content to the same outline; Flutter\'s '
            '`BoxDecoration` and `ClipRRect` still draw circular corners.',
          ),
          Example(
            snippet: 'corners-continuous',
            padding: const EdgeInsets.all(24),
            child: const _ContinuousDemo(),
          ),
        ],
      ),
      DocSection(
        title: 'Hairlines',
        children: [
          const DocText(
            'Decorative lines are one device pixel wide: separators in '
            'lists, menus, toolbars, tabs and tables, and the edges of cards '
            'and floating layers. On a 3x phone that is a third of a logical '
            'pixel, crisp instead of soft. A hairline is drawn more opaque, '
            'so it carries as much ink as the logical pixel it replaces and '
            'reads about as strong. On a 1x screen it is the plain 1px line.',
          ),
          const DocText(
            'Edges that tell the user where to act keep their full width: '
            'text field and select outlines, checkbox and radio edges, the '
            'switch track, button borders and focus rings.',
          ),
          Example(
            snippet: 'corners-hairline',
            padding: const EdgeInsets.all(24),
            child: const _HairlineDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Shadows',
        children: [
          DocText(
            'Desen has three elevation tiers, named like the color and '
            'radius roles. `surface` (cards, list groups, tables) gets a '
            'hairline ring. `control` gets a ring and a small lift. '
            '`overlay` (menus, popovers, toasts, dialogs) gets a soft, '
            'deeper shadow. The other stacks in `DsShadows` belong to '
            'one component each, and every one is built from the theme\'s '
            'colors.',
          ),
          Board(padding: EdgeInsets.all(24), child: _ShadowBoard()),
          DocText(
            'In dark mode nothing glows. Depth comes from lighter layers and '
            'edges, and a raised control gets a faint top highlight instead '
            'of a drop shadow.',
          ),
        ],
      ),
      DocSection(
        title: 'DsBoxDecoration',
        children: [
          const DocText(
            'Desen draws edges with shadows rather than borders. A 1px ring '
            'is a shadow with no blur and a spread of 1: it follows rounded '
            'corners exactly and takes no layout space. `DsBoxDecoration` '
            'paints like CSS: outer shadows, then the fill, then inset '
            'shadows, the first shadow in the list on top. Outer shadows '
            'never show through a translucent fill, and the box snaps to '
            'whole device pixels so hairlines stay crisp. Pass '
            '`hairline: true` to a ring or line to make it one device pixel '
            'wide.',
          ),
          Example(
            snippet: 'corners-decoration',
            padding: const EdgeInsets.all(24),
            child: const _Decorations(),
          ),
          const DocText(
            'For a floating box with a frosted backdrop, `DsSurface` splits '
            'the decoration around a blur. See [Layers and glass]'
            '(/guides/glass).',
          ),
        ],
      ),
      const DocSection(
        title: 'Adjusting',
        children: [
          DocText(
            'Change the rules or the stacks with `adjustRadii` and '
            '`adjustShadows` on the theme. They run again after every '
            'regeneration, so a change survives switches of corner style, '
            'mode and contrast. See [Theming](/theming).',
          ),
          DocText(
            '`adjustRadii: (r, style) => r.copyWith(controlFactor: .3)` '
            'rounds every control a little more, fields and buttons alike; '
            '`r.copyWith(card: r.card + 4)` rounds cards and what is nested '
            'in them. Your own boxes take the same rules: '
            '`radii.control(height)` for something the user presses or types '
            'in, `radii.card` or `radii.overlay` for a container, and '
            '`radii.nested(outer, inset)` for a piece inside one.',
          ),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'DsShadow.ring',
              'DsShadow',
              'A crisp ring of `width` outside the box.',
            ),
            (
              'DsShadow.innerRing',
              'DsShadow',
              'A crisp ring along the inside edge.',
            ),
            (
              'DsShadow.outline',
              'DsShadow',
              'A ring `gap` away from the box, like CSS `outline-offset`.',
            ),
            (
              'DsShadow.topLine / bottomLine',
              'DsShadow',
              'An inset hairline along one edge.',
            ),
            (
              'DsShadow(…, hairline: true)',
              'DsShadow',
              'Lengths in device pixels, color strengthened to match.',
            ),
            (
              'DsShapeClip',
              'Widget',
              'Clips its child to the continuous outline of a radius.',
            ),
            (
              'DsLine',
              'Widget',
              'A separator: a hairline in a one-pixel slot.',
            ),
            (
              'DsShadow(…, inset: true)',
              'DsShadow',
              'Any shadow, drawn inside the box.',
            ),
            (
              'DsRadii.forStyle',
              'DsRadii',
              'The default rules for a `DsCornerStyle`.',
            ),
            (
              'DsRadii.control(height)',
              'double',
              'A control\'s radius: `height × controlFactor`.',
            ),
            (
              'DsRadii.controlCorners(radius, height)',
              'BorderRadiusGeometry',
              'What a control draws: the `radius` its style sets, else '
                  '`control(height)`.',
            ),
            (
              'DsRadii.card / overlay',
              'double',
              'Cards and boxes on the page; floating layers.',
            ),
            (
              'DsRadii.nested(outer, inset)',
              'double',
              'An inset piece: `outer − inset`, at least `nestedMin`.',
            ),
            (
              'DsRadii.nestedCorners(radius, outer, inset)',
              'BorderRadiusGeometry',
              'The same for each corner of a container\'s resolved corners, '
                  'unless a style sets `radius`.',
            ),
            (
              'DsRadii.checkbox(size)',
              'double',
              'The checkbox, never rounder than a third of its size.',
            ),
          ]),
        ],
      ),
    ],
  );
}

/// The same components in every corner style: buttons of three sizes, a
/// field, a chip and a segmented control; then a list section with a
/// highlighted row and a card with media.
class _CornerRow extends StatelessWidget {
  const _CornerRow();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final r = t.radii;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final size in [DsSize.sm, DsSize.md, DsSize.lg])
              DsButton(
                variant: .secondary,
                size: size,
                onPressed: () {},
                child: Text(size.name),
              ),
            const SizedBox(
              width: 160,
              child: DsTextField(
                initialValue: 'Team retro',
                semanticLabel: 'Event',
              ),
            ),
            DsChip(
              label: const Text('Weekly'),
              selected: true,
              onChanged: (_) {},
            ),
            DsSegmentedControl<int>(
              value: 0,
              onChanged: (_) {},
              segments: const [
                DsSegment(value: 0, label: Text('Day')),
                DsSegment(value: 1, label: Text('Week')),
              ],
            ),
          ],
        ),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 240,
              child: DsListSection(
                children: [
                  DsListRow(
                    leading: const DsIcon(DsIcons.bell),
                    title: const Text('Notifications'),
                    showChevron: true,
                    // Highlighted, to show the row's corners.
                    style: DsListRowStyle(background: k.hover),
                    onPressed: () {},
                  ),
                  DsListRow(
                    leading: const DsIcon(DsIcons.globe),
                    title: const Text('Language'),
                    showChevron: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 200,
              child: DsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    // Media inset by the card's 16px padding.
                    Container(
                      height: 56,
                      decoration: DsBoxDecoration(
                        color: k.accentTint,
                        borderRadius: BorderRadius.circular(
                          r.nested(r.card, DsSpace.s16),
                        ),
                      ),
                    ),
                    Text('Cover', style: t.typography.bodyStrong),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RadiusTable extends StatelessWidget {
  const _RadiusTable();

  /// Name, use, the radius under a set of rules, and for a control the
  /// height it is for (to tell a capsule).
  static final _rows = <(String, String, double Function(DsRadii), double?)>[
    ('controlFactor', 'Control radius ÷ height', (r) => r.controlFactor, null),
    ('control(28)', 'Extra-small button', (r) => r.control(28), 28),
    ('control(32)', 'Small button, chip, tooltip', (r) => r.control(32), 32),
    ('control(40)', 'Button, text field, select', (r) => r.control(40), 40),
    ('control(48)', 'Large button, icon box', (r) => r.control(48), 48),
    ('card', 'Cards, list sections, tables', (r) => r.card, null),
    ('overlay', 'Menus, popovers, dialogs, panels', (r) => r.overlay, null),
    ('nested(overlay, 6)', 'Menu rows', (r) => r.nested(r.overlay, 6), null),
    ('nested(card, 5)', 'List rows', (r) => r.nested(r.card, 5), null),
    (
      'nested(control(38), 3)',
      'Segmented thumb, stepper buttons',
      (r) => r.nested(r.control(38), 3),
      32,
    ),
    ('nested(card, 16)', 'Media in a card', (r) => r.nested(r.card, 16), null),
    ('nestedMin', 'Floor of a nested radius', (r) => r.nestedMin, null),
    ('checkbox(18)', 'Checkbox', (r) => r.checkbox(18), null),
  ];

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final y = t.typography;
    final styles = [for (final s in DsCornerStyle.values) DsRadii.forStyle(s)];
    String value(double v, double? height) {
      if (height != null && v >= height / 2) return 'capsule';
      // At most three decimals, no trailing zeros: 0.25, 10, 9.5.
      final text = v.toStringAsFixed(3);
      return text
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }

    return DocTable(
      columns: const ['Rule', 'Used for', 'sharp', 'standard', 'soft', 'pill'],
      flex: const [4, 4, 2, 2, 2, 2],
      rows: [
        for (final (name, use, pick, height) in _rows)
          [
            Text(name, style: y.mono(y.small).copyWith(color: k.text)),
            Text(use, style: y.small.copyWith(color: k.textMuted)),
            for (final r in styles)
              Text(
                value(pick(r), height),
                style: y.numeric(y.small).copyWith(color: k.text),
              ),
          ],
      ],
    );
  }
}

class _ShadowBoard extends StatelessWidget {
  const _ShadowBoard();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final s = t.shadows;
    final r = t.radii;
    final tiles = [
      ('surface', 'Cards, lists, tables', k.surface, s.surface, r.card),
      (
        'surfaceRaised',
        'A pressable card on hover',
        k.surface,
        s.surfaceRaised,
        r.card,
      ),
      ('control', 'Secondary buttons', k.control, s.control, r.control(56)),
      ('overlay', 'Menus, popovers, dialogs', k.overlay, s.overlay, r.overlay),
      ('tooltip', 'Tooltips', k.tooltip, s.tooltip, r.control(56)),
      (
        'focusOffset',
        'Focus on filled controls',
        k.accent,
        s.focusOffset,
        r.control(56),
      ),
      (
        'focusTight',
        'Focus on bordered controls',
        k.control,
        s.focusTight,
        r.control(56),
      ),
    ];
    return TokenGrid(
      minWidth: 150,
      spacing: 24,
      runSpacing: 28,
      children: [
        for (final (name, use, color, shadows, radius) in tiles)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Container(
                height: 56,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: DsBoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(radius),
                  shadows: shadows,
                ),
              ),
              Text(
                name,
                style: t.typography
                    .mono(t.typography.caption)
                    .copyWith(color: k.text),
              ),
              Caption(use),
            ],
          ),
      ],
    );
  }
}

class _Decorations extends StatelessWidget {
  const _Decorations();

  @override
  Widget build(BuildContext context) {
    final k = DsTheme.colorsOf(context);
    final r = DsTheme.radiiOf(context);
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: [
        // #region corners-decoration
        // A well: an inner outline and a soft inset shadow at the top.
        Container(
          width: 160,
          height: 56,
          decoration: DsBoxDecoration(
            color: k.field,
            borderRadius: BorderRadius.circular(r.control(56)),
            shadows: [
              DsShadow.innerRing(k.borderField),
              DsShadow(
                color: k.press,
                offset: const Offset(0, 2),
                blur: 4,
                inset: true,
              ),
            ],
          ),
        ),
        // A ring with a gap, like CSS outline-offset.
        Container(
          width: 160,
          height: 56,
          decoration: DsBoxDecoration(
            color: k.accent,
            borderRadius: BorderRadius.circular(r.control(56)),
            shadows: [DsShadow.outline(k.focus, width: 2, gap: 2)],
          ),
        ),
        // A header with a bottom line that takes no layout space.
        Container(
          width: 160,
          height: 56,
          decoration: DsBoxDecoration(
            color: k.sidebar,
            shadows: [DsShadow.bottomLine(k.borderControl)],
          ),
        ),
        // #endregion
      ],
    );
  }
}

class _ContinuousDemo extends StatelessWidget {
  const _ContinuousDemo();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final r = t.radii;
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: [
        // #region corners-continuous
        // A card-like box: continuous corners, ring and fill concentric.
        Container(
          width: 160,
          height: 96,
          decoration: DsBoxDecoration(
            color: k.surface,
            borderRadius: BorderRadius.circular(r.card),
            shadows: t.shadows.surface,
          ),
        ),
        // A capsule keeps true half-circle ends.
        Container(
          width: 160,
          height: 40,
          decoration: DsBoxDecoration(
            color: k.accent,
            borderRadius: BorderRadius.circular(DsRadii.pill),
          ),
        ),
        // #endregion
      ],
    );
  }
}

class _HairlineDemo extends StatelessWidget {
  const _HairlineDemo();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: DecoratedBox(
        decoration: DsBoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(t.radii.card),
          shadows: t.shadows.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Wi-Fi')),
            // #region corners-hairline
            // A separator: one device pixel wide.
            DsLine(color: k.border),
            // #endregion
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bluetooth'),
            ),
          ],
        ),
      ),
    );
  }
}
