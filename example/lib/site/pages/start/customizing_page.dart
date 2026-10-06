import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';

/// `style:`, component themes, state styles, `resolveLayers` and building
/// on `DsPressable`.
class CustomizingPage extends StatelessWidget {
  const CustomizingPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Get started',
    title: 'Customizing components',
    lead:
        'Every component takes a `style:` for one instance, a component '
        'theme for a part of the app, and `DsComponentThemes` for the whole '
        'app. Styles are partial: whatever you leave out comes from the '
        'layer below.',
    sections: [
      const DocSection(
        title: 'How styles combine',
        children: [
          DocText(
            'A component builds its final style from layers, weakest first. '
            'Each layer is first resolved for the current states (hovered, '
            'pressed…) and then laid over the layers below it.',
          ),
          DocList([
            '**Desen\'s defaults**, made from the theme\'s tokens. Each '
                'component exposes them as a static `defaultStyle`.',
            '**The component theme**, such as `DsButtonTheme`, for every '
                'instance below it. Buttons also take a style per variant.',
            '**The instance\'s own** `style:`.',
          ]),
          DocText(
            'A value you set wins over Desen\'s state colors too: a '
            '`background` on a button also replaces its hover color. Give a '
            '`hovered` style when you want hover feedback in your own color. '
            'To change colors, sizes or corners everywhere, change the theme '
            'instead; see [Theming](/theming).',
          ),
        ],
      ),
      DocSection(
        title: 'One instance',
        children: [
          const DocText(
            'Pass a style to the component. `DsButtonStyle.solid` derives '
            'hover and pressed shades from one color in OKLCH, the way '
            'Desen\'s own accent behaves.',
          ),
          Example(
            snippet: 'customizing-style',
            child: Builder(
              builder: (context) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    // #region customizing-style
                    DsButton(
                      style: DsButtonStyle.solid(
                        background: const Color(0xFF7C3AED),
                        foreground: const Color(0xFFFFFFFF),
                        brightness: DsTheme.of(context).brightness,
                      ),
                      onPressed: () {},
                      child: const Text('Upgrade to Pro'),
                    ),
                    DsButton(
                      variant: .secondary,
                      style: DsButtonStyle(
                        borderRadius: BorderRadius.circular(999),
                        shadows: const [],
                      ),
                      onPressed: () {},
                      child: const Text('Compare plans'),
                    ),
                    // #endregion
                  ],
                );
              },
            ),
          ),
          const DocText(
            '`null` means "not set, keep the layer below". To remove '
            'something, pass an empty value: `shadows: const []` takes the '
            'lift off the secondary button above, and a transparent '
            '`borderColor` removes its edge.',
          ),
        ],
      ),
      DocSection(
        title: 'State styles',
        children: [
          const DocText(
            '`hovered`, `focused`, `pressed` and `disabled` are partial '
            'styles laid over the base while that state is on, like CSS '
            '`:hover` blocks. When several are on, they stack in a fixed '
            'order whatever order you wrote them in: focused, then hovered, '
            'then pressed, then disabled. Components with a selected state '
            'add `selected`, which nests its own state styles.',
          ),
          Example(
            snippet: 'customizing-states',
            child: Builder(
              builder: (context) {
                final k = DsTheme.colorsOf(context);
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    // #region customizing-states
                    DsButton(
                      variant: .ghost,
                      leading: const DsIcon(DsIcons.trash),
                      style: DsButtonStyle(
                        foreground: k.textMuted,
                        hovered: DsButtonStyle(
                          foreground: k.danger.text,
                          background: k.danger.tint,
                        ),
                        pressed: DsButtonStyle(background: k.danger.tintPress),
                      ),
                      onPressed: () {},
                      child: const Text('Discard draft'),
                    ),
                    // #endregion
                  ],
                );
              },
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Part of an app',
        children: [
          const DocText(
            'Every component has a theme widget (`DsButtonTheme`, '
            '`DsChipTheme`, `DsCardTheme`…) that sets its defaults for a '
            'subtree. Nested themes of the same type merge: an inner theme '
            'overrides only what it sets.',
          ),
          Example(
            snippet: 'customizing-theme',
            child: Builder(
              builder: (context) {
                final k = DsTheme.colorsOf(context);
                // #region customizing-theme
                return DsButtonTheme(
                  data: DsButtonThemeData(
                    size: .sm,
                    variant: .ghost,
                    variants: {
                      DsButtonVariant.ghost: DsButtonStyle(
                        foreground: k.textMuted,
                        hovered: DsButtonStyle(foreground: k.text),
                      ),
                    },
                  ),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      DsButton(
                        leading: const DsIcon(DsIcons.share),
                        onPressed: () {},
                        child: const Text('Share'),
                      ),
                      DsButton(
                        leading: const DsIcon(DsIcons.link),
                        onPressed: () {},
                        child: const Text('Copy link'),
                      ),
                      DsButton(
                        leading: const DsIcon(DsIcons.upload),
                        onPressed: () {},
                        child: const Text('Export'),
                      ),
                    ],
                  ),
                );
                // #endregion
              },
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'The whole app',
        children: [
          DocText(
            '`DsComponentThemes` applies several component themes at once. '
            'Put it in `DsApp`\'s `builder`, which runs inside the theme, so '
            'the styles can read tokens.',
          ),
          CodeBlock(
            'DsApp(\n'
            '  theme: DsThemeData(seed: DsSeed.navy),\n'
            '  builder: (context, child) => DsComponentThemes(\n'
            '    themes: [\n'
            '      const DsButtonThemeData(size: .sm),\n'
            '      DsChipThemeData(\n'
            '        style: DsChipStyle(\n'
            '          borderRadius: BorderRadius.circular(6),\n'
            '        ),\n'
            '      ),\n'
            '    ],\n'
            '    child: child!,\n'
            '  ),\n'
            '  home: const HomePage(),\n'
            ')',
          ),
        ],
      ),
      const DocSection(
        title: 'The same layers in your code',
        children: [
          DocText(
            'When you wrap a component or build one that should honor the '
            'same themes, stack the layers yourself. `resolveLayers` resolves '
            'each layer for the states and lays them over each other, '
            'weakest first. Null layers are skipped.',
          ),
          CodeBlock(
            'final t = DsTheme.of(context);\n'
            'final layers = [\n'
            '  DsCard.defaultStyle(t),\n'
            '  DsCardTheme.of(context).style,\n'
            '  widget.style,\n'
            '];\n'
            '\n'
            '// Inside a DsPressable builder:\n'
            'final s = DsCardStyle.resolveLayers(layers, states);',
          ),
        ],
      ),
      DocSection(
        title: 'Your own look on DsPressable',
        children: [
          const DocText(
            'Desen\'s buttons, chips, cards and rows are built on '
            '`DsPressable`, which you can use too. It handles pointer, touch and keyboard input, focus, the '
            'cursor, the tap area and semantics, and hands your builder the '
            'current states. It draws nothing, so the look is entirely '
            'yours.',
          ),
          Example(
            snippet: 'customizing-pressable',
            padding: const EdgeInsets.all(24),
            child: const _PlanPicker(),
          ),
          const DocList([
            '`focused` is only reported for keyboard focus, so a ring drawn '
                'for it never shows after a click. `DsFocusRing` draws the '
                'theme\'s ring around your box, matched to its corners, '
                'without changing the layout.',
            'A box that shrinks while pressed should scale by '
                '`DsPressEffect.scaleOf(context, scale)`, so a '
                '`DsPressEffect` scope can turn the motion off.',
            '`DsFieldSurface` draws the box of a text field, with its '
                'focus, error and disabled looks, for a control that should '
                'look like a field.',
            '`hovered` comes from a mouse only, so hover styles do not stick '
                'on phones.',
            'Enter fires on key down; Space shows the pressed state while '
                'held and fires on release.',
            'The hit area is at least the theme\'s `minTapTarget`.',
          ]),
          const DocText(
            'Floating layers (menus, popovers, dialogs) have their own '
            'surface style, and can turn into frosted glass. See [Layers and '
            'glass](/guides/glass).',
          ),
        ],
      ),
    ],
  );
}

class _PlanPicker extends StatefulWidget {
  const _PlanPicker();

  @override
  State<_PlanPicker> createState() => _PlanPickerState();
}

class _PlanPickerState extends State<_PlanPicker> {
  static const _plans = [
    ('Starter', 'Free', 'Up to 3 projects'),
    ('Team', '\$12', 'Per member, monthly'),
    ('Business', '\$24', 'SSO and audit log'),
  ];

  String _plan = 'Team';

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final y = t.typography;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final (name, price, note) in _plans)
          // #region customizing-pressable
          DsPressable(
            onPressed: () => setState(() => _plan = name),
            selected: _plan == name,
            semanticLabel: '$name, $price, $note',
            builder: (context, states, _) {
              final selected = _plan == name;
              final hovered = states.contains(WidgetState.hovered);
              final corners = BorderRadius.circular(t.radii.card);
              return DsFocusRing(
                focused: states.contains(WidgetState.focused),
                borderRadius: corners,
                child: AnimatedContainer(
                  duration: t.motion.toneDuration,
                  curve: t.motion.toneCurve,
                  width: 160,
                  padding: const EdgeInsets.all(DsSpace.s16),
                  decoration: DsBoxDecoration(
                    color: selected ? k.selection : k.surface,
                    borderRadius: corners,
                    shadows: [
                      DsShadow.innerRing(
                        selected
                            ? k.onSelection
                            : (hovered ? k.borderField : k.border),
                        width: selected ? 2 : 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(name, style: y.labelStrong.copyWith(color: k.text)),
                      Text(
                        price,
                        style: y.numeric(y.title).copyWith(color: k.text),
                      ),
                      Text(note, style: y.caption.copyWith(color: k.textMuted)),
                    ],
                  ),
                ),
              );
            },
          ),
        // #endregion
      ],
    );
  }
}
