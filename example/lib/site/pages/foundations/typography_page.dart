import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';
import 'common.dart';

/// The type scale, numbers, code and fonts.
class TypographyPage extends StatelessWidget {
  const TypographyPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Foundations',
    title: 'Typography',
    lead:
        'One type scale for pages, components and controls, in two ramps: '
        'compact for pointer screens, touch for phones. Set in Schibsted '
        'Grotesk, or San Francisco in iOS and macOS apps, with Geist Mono for '
        'code. Styles carry no color, so the same role reads right on any '
        'surface.',
    sections: [
      DocSection(
        title: 'Type roles',
        children: [
          const DocText(
            'Eleven roles in `DsTypography`. At compact density the sizes '
            'step 11, 12, 13, 14, 16, 22 and 30; most text is 13 or 14. The '
            'values below are read from the theme on this page: switch the '
            'density in the settings menu to see the touch ramp.',
          ),
          const Board(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _Roles(),
          ),
          const DocText(
            'Tracking is set in em, like CSS `letter-spacing`, and line '
            'height is a multiplier, like CSS `line-height`. The leading is '
            'split evenly above and below the glyphs, so text sits in a box '
            'where it would in a browser. `dsTextStyle` builds a style the '
            'same way.',
          ),
        ],
      ),
      const DocSection(
        title: 'Density',
        children: [
          DocText(
            'The theme sets its typography for its density. At '
            '`DsDensity.touch` every role steps up, so text reads at arm\'s '
            'length while the hierarchy stays the same: body text is 16 on a '
            '22px line, as on a phone. Controls keep their heights and their '
            'labels stay centered; rows grow with the density.',
          ),
          _Ramps(),
          DocText(
            'Roles you replace with `copyWith` keep your values at both '
            'densities; the others follow the ramp. To set a role per '
            'density, build the theme\'s typography for the density you give '
            'it: `DsTypography(density: density).copyWith(…)`.',
          ),
        ],
      ),
      DocSection(
        title: 'Using a role',
        children: [
          const DocText(
            'Read the scale from the theme and add a color from `DsColors`. '
            'Components already do this; you need it for your own text.',
          ),
          Example(
            snippet: 'type-usage',
            alignment: AlignmentDirectional.centerStart,
            child: Builder(
              builder: (context) {
                // #region type-usage
                // In a build method:
                final t = DsTheme.of(context);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      'Invite your team',
                      style: t.typography.title.copyWith(color: t.colors.text),
                    ),
                    Text(
                      'Members can edit every project in this workspace.',
                      style: t.typography.small.copyWith(
                        color: t.colors.textMuted,
                      ),
                    ),
                  ],
                );
                // #endregion
              },
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Numbers',
        children: [
          const DocText(
            '`numeric(style)` turns on tabular figures (OpenType `tnum`) in '
            'the text family: every digit takes the same width, so columns '
            'line up and a changing value does not jitter. Use it for '
            'amounts, counters, dates, times, table figures and progress. '
            'Running text keeps proportional figures. In Schibsted Grotesk '
            'the period, comma and colon take a digit\'s width too, which is '
            'why text fields keep proportional figures for what people '
            'type.',
          ),
          const Example(snippet: 'type-numeric', child: _Figures()),
        ],
      ),
      const DocSection(
        title: 'Code',
        children: [
          DocText(
            '`mono(style)` sets text in Geist Mono with tabular figures. It is '
            'for code and keycaps only, such as a search field\'s ⌘K hint. '
            'Numbers stay in the text family: a mono face makes amounts and '
            'dates read like a console, and its slashed zero like "Ø".',
          ),
          _MonoSample(),
        ],
      ),
      const DocSection(
        title: 'Fonts',
        children: [
          DocText(
            'In iOS and macOS apps text is set in the system font, San '
            'Francisco, with Apple\'s tracking for each size and the display '
            'cut for titles. On the web, Android, Windows and Linux it is '
            'Schibsted Grotesk. A family you pass is used everywhere, Apple '
            'platforms included.',
          ),
          DocText(
            'The two typefaces ship in the optional `desen_ui_fonts` package, '
            'under the SIL Open Font License. Add it for Desen\'s look. '
            'Without it, text falls back to the platform font; the small '
            'tracking values suit system fonts too.',
          ),
          CodeBlock(
            'dependencies:\n'
            '  desen_ui_fonts:\n'
            '    path: ../desen_ui/desen_ui_fonts',
            language: 'yaml',
          ),
          DocText(
            'To use your own families, declare them in your app and pass '
            'their names. `package: null` means the fonts are declared in '
            'your app rather than in a package.',
          ),
          CodeBlock(
            'DsThemeData(\n'
            '  typography: DsTypography(\n'
            "    family: 'Inter',\n"
            "    monoFamily: 'JetBrains Mono',\n"
            '    package: null,\n'
            '  ),\n'
            ')',
          ),
          DocText(
            'Titles (`display` and `title`) can use a face of their own, '
            'such as a serif; the other roles stay in the text family.',
          ),
          CodeBlock(
            'DsThemeData(\n'
            '  typography: DsTypography(\n'
            "    displayFamily: 'Fraunces',\n"
            '    displayPackage: null,\n'
            '  ),\n'
            ')',
          ),
          DocText(
            'To change single roles, start from the default scale: '
            '`DsTypography().copyWith(display: …)`. Text follows the '
            'platform\'s text scale; see [Accessibility](/accessibility).',
          ),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'DsTypography()',
              'DsTypography',
              'The default scale. Takes `family` (null: the platform\'s), '
                  '`monoFamily`, `package`, `displayFamily`, '
                  '`displayPackage` and `density`.',
            ),
            (
              'forDensity(density)',
              'DsTypography',
              'The scale in the same fonts for another density. The theme '
                  'calls it.',
            ),
            (
              'controlLabel(size)',
              'TextStyle',
              'The label of a control of that size, as buttons use.',
            ),
            (
              'systemFamily',
              'String',
              'The system font in iOS and macOS apps; '
                  '`systemDisplayFamily` for its display cut.',
            ),
            (
              'numeric(style)',
              'TextStyle',
              '`style` in the text family with tabular figures.',
            ),
            (
              'mono(style)',
              'TextStyle',
              '`style` in the mono family, for code and keycaps.',
            ),
            ('copyWith', 'DsTypography', 'Replaces single roles.'),
            (
              'dsTextStyle',
              'TextStyle',
              'A style with CSS-like tracking (em) and even leading.',
            ),
          ]),
        ],
      ),
    ],
  );
}

class _Roles extends StatelessWidget {
  const _Roles();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final y = t.typography;
    final k = t.colors;
    final roles = [
      ('display', y.display, 'Quarterly report', 'Page titles.'),
      (
        'title',
        y.title,
        'Invite your team',
        'Card, dialog and empty state titles.',
      ),
      ('heading', y.heading, 'Notifications', 'Section and card headers.'),
      (
        'body',
        y.body,
        'Changes are saved as you type and synced to every device.',
        'Body text.',
      ),
      (
        'bodyStrong',
        y.bodyStrong,
        'Payment method',
        'Emphasis, large button labels.',
      ),
      (
        'small',
        y.small,
        'Edited 3 minutes ago by Deniz',
        'Descriptions, secondary text.',
      ),
      ('label', y.label, 'Save changes', 'Control labels, menu rows.'),
      ('labelStrong', y.labelStrong, 'Billing', 'Emphasized labels.'),
      (
        'caption',
        y.caption,
        'Use at least 8 characters.',
        'Help text and meta.',
      ),
      ('fieldLabel', y.fieldLabel, 'Email address', 'The label above a field.'),
      (
        'overline',
        y.overline,
        'WORKSPACE',
        'Sidebar section headers, uppercase.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (name, style, sample, use)) in roles.indexed)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: i == 0 ? null : Border(top: BorderSide(color: k.border)),
            ),
            child: LayoutBuilder(
              builder: (context, box) {
                final spec = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      name,
                      style: y.mono(y.caption).copyWith(color: k.text),
                    ),
                    Caption(_spec(style)),
                    Caption(use, color: k.textSubtle),
                  ],
                );
                final text = Text(sample, style: style.copyWith(color: k.text));
                if (box.maxWidth < 560) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [text, spec],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 24,
                  children: [
                    Expanded(child: text),
                    SizedBox(width: 200, child: spec),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  /// `30 / 700 / −0.02em / 1.1`.
  static String _spec(TextStyle s) {
    final size = s.fontSize ?? 14;
    final tracking = (s.letterSpacing ?? 0) / size;
    final parts = [
      size.toStringAsFixed(0),
      '${s.fontWeight?.value ?? 400}',
      if (tracking.abs() > 1e-6)
        '${tracking < 0 ? '−' : '+'}${tracking.abs().toStringAsFixed(2)}em',
      if (s.height case final h?)
        'lh ${h.toStringAsFixed(h == h.roundToDouble() ? 0 : 2)}',
    ];
    return parts.join(' / ');
  }
}

/// The two ramps side by side, from the default scale.
class _Ramps extends StatelessWidget {
  const _Ramps();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final compact = DsTypography();
    final touch = DsTypography(density: DsDensity.touch);
    // `16 / 22px`: the size, and the line where it is set in pixels.
    String spec(TextStyle s) {
      final size = s.fontSize ?? 14;
      final line = s.height == null ? '' : ' / ${(size * s.height!).round()}px';
      return '${size.toStringAsFixed(0)}$line';
    }

    final figures = t.typography
        .numeric(t.typography.small)
        .copyWith(color: k.text);
    final name = t.typography.mono(t.typography.small).copyWith(color: k.text);
    final rows = [
      ('display', compact.display, touch.display),
      ('title', compact.title, touch.title),
      ('heading', compact.heading, touch.heading),
      ('body', compact.body, touch.body),
      ('small', compact.small, touch.small),
      ('label', compact.label, touch.label),
      ('caption', compact.caption, touch.caption),
      ('overline', compact.overline, touch.overline),
    ];
    return DocTable(
      columns: const ['Role', 'Compact', 'Touch'],
      flex: const [4, 3, 3],
      rows: [
        for (final (role, a, b) in rows)
          [
            Text(role, style: name),
            Text(spec(a), style: figures),
            Text(spec(b), style: figures),
          ],
      ],
    );
  }
}

class _Figures extends StatelessWidget {
  const _Figures();

  static const _amounts = ['1,111.11', '8,808.80', '42,170.05', '974.36'];

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final y = t.typography;
    final k = t.colors;
    Widget title(String text) =>
        Text(text, style: y.fieldLabel.copyWith(color: k.textMuted));
    return Wrap(
      spacing: 48,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 6,
          children: [
            title('Proportional'),
            for (final amount in _amounts)
              Text(amount, style: y.body.copyWith(color: k.text)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 6,
          children: [
            title('Tabular'),
            for (final amount in _amounts)
              // #region type-numeric
              Text(amount, style: t.typography.numeric(t.typography.body)),
            // #endregion
          ],
        ),
      ],
    );
  }
}

class _MonoSample extends StatelessWidget {
  const _MonoSample();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final y = t.typography;
    final k = t.colors;
    Widget item(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Caption(label, color: k.textSubtle),
        child,
      ],
    );
    return Board(
      child: Wrap(
        spacing: 40,
        runSpacing: 20,
        children: [
          item(
            'Code: mono',
            Text(
              'git checkout -b fix/login',
              style: y.mono(y.small).copyWith(color: k.text),
            ),
          ),
          item(
            'Keycap: mono',
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Text('Search', style: y.small.copyWith(color: k.textSubtle)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: DsBoxDecoration(
                    color: k.control,
                    borderRadius: BorderRadius.circular(t.radii.control(20)),
                    shadows: [DsShadow.innerRing(k.borderControl)],
                  ),
                  child: Text(
                    '⌘K',
                    style: y.mono(y.caption).copyWith(color: k.textMuted),
                  ),
                ),
              ],
            ),
          ),
          item(
            'Date and amount: numeric',
            Text(
              'Due 05.10.2026 · 1,250.00',
              style: y.numeric(y.small).copyWith(color: k.text),
            ),
          ),
        ],
      ),
    );
  }
}
