import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import 'common.dart';

/// The spacing scale, control sizes per density and tap areas.
class SpacingPage extends StatelessWidget {
  const SpacingPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Foundations',
    title: 'Spacing and sizes',
    lead:
        'A 4px spacing rhythm, four control heights shared by every '
        'component, and tap areas that follow the platform: 24px with a '
        'mouse, 44px on phones, without making anything look bigger.',
    sections: [
      const DocSection(
        title: 'Spacing',
        children: [
          DocText(
            '`DsSpace` is the spacing scale: 4, 8, 12, 16, 20, 24 and 28 '
            'inside components, then the layout steps 32, 40, 48 and 64 '
            'between groups and sections of a page. The half steps 3, 5 and 6 are for concentric insets inside '
            'channels, such as the thumb of a segmented control, where the '
            'inner radius must follow the outer one.',
          ),
          Board(child: _SpaceScale()),
        ],
      ),
      DocSection(
        title: 'Control sizes',
        children: [
          const DocText(
            'Buttons, fields, selects and segmented controls share four '
            'heights through `DsSize`: `xs` 28, `sm` 32, `md` 40 (the '
            'default) and `lg` 48. Icons in them are 14, 16, 16 and 20 '
            '(`DsSizes.iconSize`, adjustable like the heights through '
            '`adjustSizes`). Controls grow taller when the text is '
            'scaled up; the height is a minimum.',
          ),
          const Board(child: _Heights()),
          const DocText(
            'Rows have their own heights: `row` for menu and sidebar rows, '
            '`listRow` for settings-style list rows, `day` for a calendar '
            'day. Read them from `DsTheme.sizesOf(context)`. Phones default '
            'to touch density; "Compact on a phone" is compact density '
            'chosen explicitly on iOS or Android.',
          ),
          DocTable(
            columns: const ['Token', 'Compact', 'Touch', 'Compact on a phone'],
            flex: const [3, 2, 2, 3],
            rows: [
              for (final (name, pick) in _tokens)
                [
                  _Mono(name),
                  _Num(pick(DsSizes.compact)),
                  _Num(pick(DsSizes.touch)),
                  _Num(pick(DsSizes.compactOnTouchPlatform)),
                ],
            ],
          ),
        ],
      ),
      DocSection(
        title: 'Tap areas',
        children: [
          const DocText(
            'With a mouse, every control can be hit across at least 24px '
            '(WCAG 2.5.8). On iOS and Android each small control gets an '
            'invisible 44px tap area around it and keeps its drawn size. The '
            'area takes real layout space, so side-by-side small controls sit '
            'a little further apart. The dashed lines show it.',
          ),
          Example(snippet: 'spacing-platform', child: const _TapAreas()),
          const DocText(
            'The theme\'s `platform` decides, and it defaults to the platform '
            'the app runs on, mobile web included. Pin it in golden tests so '
            'a layout does not depend on the machine. Rows are their own tap '
            'surface and get no extra area. For a custom control that does '
            'not use `DsPressable`, wrap it in `DsMinTapTarget`.',
          ),
        ],
      ),
      DocSection(
        title: 'Density',
        children: [
          const DocText(
            'A theme without a density follows the platform, as Apple\'s '
            'do: `DsDensity.touch` on iOS and Android (their browsers '
            'included), `DsDensity.compact` on desktop and desktop '
            'browsers. Pass one to pin it. `DsDensity.touch`: '
            'controls keep their sizes and get 44px tap areas, menu, '
            'sidebar and list rows grow to 44 and 48, and text steps up to '
            'the touch type ramp (body 16). See [Typography](/foundations/typography).',
          ),
          Example(
            snippet: 'spacing-density',
            padding: const EdgeInsets.all(24),
            child: const _DensityDemo(),
          ),
          const DocText(
            'To change the numbers themselves, use `adjustSizes` on the '
            'theme; it runs again whenever the density changes. See '
            '[Theming](/theming).',
          ),
        ],
      ),
    ],
  );
}

final _tokens = <(String, double Function(DsSizes))>[
  ('xs', (s) => s.xs),
  ('sm', (s) => s.sm),
  ('md', (s) => s.md),
  ('lg', (s) => s.lg),
  ('row', (s) => s.row),
  ('listRow', (s) => s.listRow),
  ('day', (s) => s.day),
  ('minTapTarget', (s) => s.minTapTarget),
];

class _Mono extends StatelessWidget {
  const _Mono(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Text(
      text,
      style: t.typography
          .mono(t.typography.small)
          .copyWith(color: t.colors.text),
    );
  }
}

class _Num extends StatelessWidget {
  const _Num(this.value);

  final double value;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Text(
      value.toStringAsFixed(0),
      style: t.typography
          .numeric(t.typography.small)
          .copyWith(color: t.colors.text),
    );
  }
}

class _SpaceScale extends StatelessWidget {
  const _SpaceScale();

  static const _steps = [
    ('s3', DsSpace.s3),
    ('s4', DsSpace.s4),
    ('s5', DsSpace.s5),
    ('s6', DsSpace.s6),
    ('s8', DsSpace.s8),
    ('s12', DsSpace.s12),
    ('s16', DsSpace.s16),
    ('s20', DsSpace.s20),
    ('s24', DsSpace.s24),
    ('s28', DsSpace.s28),
    ('s32', DsSpace.s32),
    ('s40', DsSpace.s40),
    ('s48', DsSpace.s48),
    ('s64', DsSpace.s64),
  ];

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        for (final (name, value) in _steps)
          Row(
            spacing: 12,
            children: [
              SizedBox(width: 112, child: _Mono('DsSpace.$name')),
              SizedBox(
                width: 40,
                child: Caption('${value.toStringAsFixed(0)}px'),
              ),
              // The largest steps would overflow a phone; the bar takes
              // what is left.
              Flexible(
                child: Container(
                  width: value * 4,
                  height: 12,
                  decoration: DsBoxDecoration(
                    color: value == 3 || value == 5 || value == 6
                        ? k.textSubtle
                        : k.indicator,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 4),
        Caption(
          'Bars drawn at four times their size; half steps in gray.',
          color: k.textSubtle,
        ),
      ],
    );
  }
}

class _Heights extends StatelessWidget {
  const _Heights();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final size in DsSize.values)
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Container(
                width: 72,
                height: t.sizes.height(size),
                alignment: Alignment.center,
                decoration: DsBoxDecoration(
                  color: k.control,
                  borderRadius: BorderRadius.circular(
                    t.radii.control(t.sizes.height(size)),
                  ),
                  shadows: t.shadows.control,
                ),
                child: DsIcon(
                  DsIcons.plus,
                  size: t.sizes.iconSize(size),
                  color: k.text,
                ),
              ),
              _Mono(size.name),
              Caption(
                '${t.sizes.height(size).toStringAsFixed(0)} · icon '
                '${t.sizes.iconSize(size).toStringAsFixed(0)}',
              ),
            ],
          ),
      ],
    );
  }
}

class _TapAreas extends StatefulWidget {
  const _TapAreas();

  @override
  State<_TapAreas> createState() => _TapAreasState();
}

class _TapAreasState extends State<_TapAreas> {
  bool _phone = true;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final k = DsTheme.colorsOf(context);
    Widget area(Widget child) => DsDashedBorder(
      color: k.textSubtle,
      width: 1,
      dashLength: 3,
      dashGap: 3,
      child: child,
    );
    return Column(
      spacing: 24,
      children: [
        DsSegmentedControl<bool>(
          value: _phone,
          onChanged: (v) => setState(() => _phone = v),
          segments: const [
            DsSegment(value: false, label: Text('Desktop')),
            DsSegment(value: true, label: Text('Phone')),
          ],
        ),
        ThemePreview(
          followPlatform: false,
          // #region spacing-platform
          theme: DsThemeData(
            platform: _phone ? TargetPlatform.iOS : TargetPlatform.macOS,
          ),
          // #endregion
          child: Wrap(
            spacing: 4,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              area(
                DsButton.icon(
                  variant: .ghost,
                  size: .xs,
                  icon: const DsIcon(DsIcons.bold),
                  semanticLabel: 'Bold',
                  onPressed: () {},
                ),
              ),
              area(
                DsButton.icon(
                  variant: .ghost,
                  size: .xs,
                  icon: const DsIcon(DsIcons.italic),
                  semanticLabel: 'Italic',
                  onPressed: () {},
                ),
              ),
              area(
                DsCheckbox(
                  value: _done,
                  onChanged: (v) => setState(() => _done = v ?? false),
                  semanticLabel: 'Done',
                ),
              ),
              area(
                DsButton(
                  size: .sm,
                  variant: .secondary,
                  onPressed: () {},
                  child: const Text('Share'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DensityDemo extends StatefulWidget {
  const _DensityDemo();

  @override
  State<_DensityDemo> createState() => _DensityDemoState();
}

class _DensityDemoState extends State<_DensityDemo> {
  DsDensity _density = DsDensity.touch;

  @override
  Widget build(BuildContext context) => Column(
    spacing: 20,
    children: [
      DsSegmentedControl<DsDensity>(
        value: _density,
        onChanged: (v) => setState(() => _density = v),
        segments: const [
          DsSegment(value: DsDensity.compact, label: Text('Compact')),
          DsSegment(value: DsDensity.touch, label: Text('Touch')),
        ],
      ),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: ThemePreview(
          followDensity: false,
          // #region spacing-density
          theme: DsThemeData(density: _density),
          // #endregion
          child: DsListSection(
            header: const Text('Account'),
            children: [
              DsListRow(
                leading: const DsIcon(DsIcons.user),
                title: const Text('Profile'),
                showChevron: true,
                onPressed: () {},
              ),
              DsListRow(
                leading: const DsIcon(DsIcons.bell),
                title: const Text('Notifications'),
                detail: const Text('On'),
                showChevron: true,
                onPressed: () {},
              ),
              DsListRow(
                leading: const DsIcon(DsIcons.globe),
                title: const Text('Language'),
                detail: const Text('English'),
                showChevron: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
