import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';
import '../../settings.dart';
import '../foundations/common.dart';

/// Theme data, dark mode, adjust hooks, raw themes, reading tokens and the
/// animated switch.
class ThemingPage extends StatelessWidget {
  const ThemingPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Get started',
    title: 'Theming',
    lead:
        'A theme is generated from a brand color and a few settings. When a '
        'user switches to dark mode, another contrast level, corner style or '
        'density, Desen generates it again, and your adjustments are applied '
        'again on top.',
    sections: [
      DocSection(
        title: 'DsThemeData',
        children: [
          const DocText(
            'Pass a `DsThemeData` to `DsApp` or `DsScope`. The seed is the '
            'only thing most apps set; everything else has a default.',
          ),
          Example(
            snippet: 'theming-data',
            padding: const EdgeInsets.all(24),
            child: ThemePreview(
              followCorners: false,
              followSelection: false,
              // #region theming-data
              theme: DsThemeData(
                seed: DsSeed.color(const Color(0xFF6D28D9)),
                cornerStyle: DsCornerStyle.soft,
                selectionStyle: DsSelectionStyle.strong,
              ),
              // #endregion
              child: const _Workspace(),
            ),
          ),
          const DocList([
            '**Brand:** `seed`, `selectionStyle`, `typography` and `motion` '
                'are yours to choose.',
            '**End user:** `contrast`, `cornerStyle` and `density` are meant '
                'to be offered as settings, like the menu at the top of this '
                'site. Brightness comes from `themeMode`.',
            '**Platform:** `platform` sets the tap areas (24px with a mouse, '
                '44px on iOS and Android). It defaults to the running '
                'platform.',
          ]),
        ],
      ),
      const DocSection(
        title: 'Tones',
        children: [
          DocText(
            'Six seeds ship as presets. Pick one to switch this whole site; '
            'the note says what the palette engine does with it. Any color '
            'works through `DsSeed.color`; see [Colors](/foundations/colors) '
            'for the rules and a playground.',
          ),
          DocText(
            'The default blue is the most vivid blue that still carries a '
            'white label at AA, and dark mode keeps its color rather than '
            'dulling it. Status colors follow the same idea: fills that '
            'carry a label, and a vivid `signal` for dots and status icons.',
          ),
          _Tones(),
        ],
      ),
      const DocSection(
        title: 'Selection style',
        children: [
          DocText(
            'Selected chips, sidebar items, calendar days, pagination and '
            'toolbar toggles share one look, set once for the theme. `soft` '
            '(the default) is a tinted background with accent ink; `strong` '
            'is a filled accent background with a contrasting label. In dark '
            'mode a warm brand (red, orange, yellow, green) selects `soft` '
            'items in gray with the brand in the text, so a selection never '
            'reads as a status; see [Colors](/foundations/colors).',
          ),
          Board(child: _SelectionStyles()),
        ],
      ),
      const DocSection(
        title: 'Dark mode',
        children: [
          DocText(
            '`themeMode` picks the brightness: `system` (the default) '
            'follows the platform, `light` and `dark` pin it. Without a '
            '`darkTheme`, the dark theme is your theme generated again with '
            'dark brightness, hooks included, so one definition covers both '
            'modes.',
          ),
          CodeBlock(
            'DsApp(\n'
            '  theme: DsThemeData(seed: DsSeed.color(brand)),\n'
            '  themeMode: DsThemeMode.system,\n'
            '  home: const HomePage(),\n'
            ')\n'
            '\n'
            '// A different seed in dark mode:\n'
            'DsApp(\n'
            '  theme: DsThemeData(seed: DsSeed.navy),\n'
            '  darkTheme: DsThemeData.dark(seed: DsSeed.indigo),\n'
            '  home: const HomePage(),\n'
            ')',
          ),
          DocText(
            '`DsScope` also follows the platform\'s request for more '
            'contrast (`followPlatformContrast`: a soft theme turns '
            'standard) and its reduce motion setting.',
          ),
        ],
      ),
      DocSection(
        title: 'Adjusting generated tokens',
        children: [
          const DocText(
            'To change generated tokens, use the `adjust…` hooks instead of '
            'replacing the tokens. A hook runs again after every '
            'regeneration, so your change survives a switch of mode, '
            'contrast, corners or density. `adjustColors` receives the '
            'brightness, so one hook serves light and dark.',
          ),
          Example(
            snippet: 'theming-adjust',
            padding: const EdgeInsets.all(24),
            child: ThemePreview(
              // #region theming-adjust
              theme: DsThemeData(
                seed: DsSeed.color(const Color(0xFF0B6E4F)),
                adjustColors: (k, brightness) => k.copyWith(
                  link: brightness == Brightness.dark
                      ? const Color(0xFF6EE7B7)
                      : const Color(0xFF047857),
                ),
                adjustRadii: (r, style) => r.copyWith(card: r.card + 6),
                adjustShadows: (s, k, brightness) =>
                    s.copyWith(surface: s.surfaceRaised),
              ),
              // #endregion
              child: const _Article(),
            ),
          ),
          const DocText(
            'Colors are adjusted before shadows are built, so an adjusted '
            'edge or focus color also reaches the matching shadow stack. '
            '`adjustSizes` edits the size scale for a density. Theme '
            'equality ignores the hook functions, so a hook written inline '
            'in `build` does not count as a theme change.',
          ),
        ],
      ),
      const DocSection(
        title: 'Hand-built themes',
        children: [
          DocText(
            '`DsThemeData.raw` takes every token set by hand, for full '
            'control. It cannot be regenerated without losing your tokens, '
            'so it comes with three rules:',
          ),
          DocList([
            'Give `DsScope` (or `DsApp`) a `darkTheme` of its own. Without '
                'one, the light tokens are kept in dark mode and a debug '
                'warning is printed.',
            '`copyWith` of a setting that feeds generation (`seed`, '
                '`brightness`, `contrast`…) asserts in debug builds. '
                '`selectionStyle`, `typography`, `motion` and `extensions` change '
                'freely.',
            'When the platform asks for more contrast, a raw soft theme '
                'keeps your tokens and only takes the standard setting.',
          ]),
          CodeBlock(
            'final light = DsThemeData();\n'
            'final custom = DsThemeData.raw(\n'
            '  brightness: Brightness.light,\n'
            '  seed: light.seed,\n'
            '  contrast: DsContrast.standard,\n'
            '  cornerStyle: DsCornerStyle.standard,\n'
            '  density: DsDensity.compact,\n'
            '  platform: light.platform,\n'
            '  selectionStyle: DsSelectionStyle.soft,\n'
            '  autoClashRule: true,\n'
            '  dangerOverride: null,\n'
            '  successOverride: null,\n'
            '  seedRole: light.seedRole,\n'
            '  colors: myColors,\n'
            '  shadows: myShadows,\n'
            '  radii: DsRadii.standard,\n'
            '  sizes: DsSizes.compact,\n'
            '  typography: DsTypography(),\n'
            '  motion: const DsMotion(),\n'
            ');',
          ),
        ],
      ),
      DocSection(
        title: 'Reading tokens',
        children: [
          const DocText(
            '`DsTheme.of(context)` returns the whole theme. `colorsOf`, '
            '`shadowsOf`, `radiiOf`, `sizesOf`, `typographyOf` and '
            '`motionOf` return one group and rebuild the caller only when '
            'that group changes. Without any `DsScope` above, a default '
            'theme that follows the platform brightness is returned, so '
            'components work anywhere.',
          ),
          Example(
            snippet: 'theming-read',
            child: Builder(
              builder: (context) {
                // #region theming-read
                // Read only the groups you use.
                final k = DsTheme.colorsOf(context);
                final r = DsTheme.radiiOf(context);
                final y = DsTheme.typographyOf(context);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpace.s12,
                    vertical: DsSpace.s8,
                  ),
                  decoration: DsBoxDecoration(
                    color: k.info.tint,
                    borderRadius: BorderRadius.circular(r.control(32)),
                  ),
                  child: Text(
                    'Storage is 82% full',
                    style: y.label.copyWith(color: k.info.text),
                  ),
                );
                // #endregion
              },
            ),
          ),
          const DocText(
            'To theme part of an app differently, wrap it in `DsTheme` with '
            'other data, or in a nested `DsScope`, which also sets the '
            'default text and icon styles.',
          ),
          const CodeBlock(
            'DsTheme(\n'
            '  data: DsTheme.of(context).copyWith(seed: DsSeed.forest),\n'
            '  child: const BillingSection(),\n'
            ')',
          ),
        ],
      ),
      const DocSection(
        title: 'App tokens',
        children: [
          DocText(
            'Tokens of your own (a brand gradient, chart colors) ride on the '
            'theme as extensions: subclass `DsThemeExtension`, attach '
            'instances with `extensions:` and read them with '
            '`DsTheme.extensionOf<T>(context)`, which rebuilds the caller '
            'only when extensions change. One extension per type. Desen\'s '
            'components never read them.',
          ),
          DocList([
            '`resolve(theme)` derives values from the theme the extension '
                'lands in: its mode, contrast, density or tokens. It runs '
                'again on every regeneration (a switch to dark), on the '
                'extension the theme holds, so keep what you resolve from.',
            '`lerp` moves the values with the rest of the theme in '
                '`DsAnimatedTheme`.',
            'Themes compare their extensions: implement `==` and '
                '`hashCode`.',
          ]),
          CodeBlock(
            '@immutable\n'
            'class Brand extends DsThemeExtension<Brand> {\n'
            '  const Brand({required this.light, required this.dark, Color? glow})\n'
            '    : glow = glow ?? light;\n'
            '\n'
            '  final Color light, dark;\n'
            '  final Color glow; // the one for the current mode\n'
            '\n'
            '  @override\n'
            '  Brand resolve(DsThemeData theme) =>\n'
            '      copyWith(glow: theme.isDark ? dark : light);\n'
            '\n'
            '  @override\n'
            '  Brand copyWith({Color? glow}) =>\n'
            '      Brand(light: light, dark: dark, glow: glow ?? this.glow);\n'
            '\n'
            '  @override\n'
            '  Brand lerp(Brand? other, double t) => other == null\n'
            '      ? this\n'
            '      : Brand(\n'
            '          light: other.light,\n'
            '          dark: other.dark,\n'
            '          glow: Color.lerp(glow, other.glow, t),\n'
            '        );\n'
            '\n'
            '  // == and hashCode over light, dark and glow.\n'
            '}\n'
            '\n'
            'DsScope(\n'
            '  theme: DsThemeData(extensions: [Brand(light: a, dark: b)]),\n'
            '  child: app,\n'
            ')\n'
            '\n'
            'final glow = DsTheme.extensionOf<Brand>(context)!.glow;',
          ),
        ],
      ),
      const DocSection(
        title: 'Animated theme switch',
        children: [
          DocText(
            'When the colors change, as when switching to dark, `DsScope` '
            'switches at once in a single rebuild and fades a snapshot of '
            'the previous frame out over it, like the web\'s View '
            'Transitions. Nothing dips through a lighter or darker shade on '
            'the way. A change that moves the layout (density, corners, text '
            'size) does not fade. Turn it off with `animateChanges: false`.',
          ),
          Board(child: _SwitchDemo()),
          DocText(
            '`DsAnimatedTheme` is the alternative for a subtree: it '
            'interpolates every token on every frame, so everything that '
            'reads the theme rebuilds once per frame while it runs.',
          ),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('seed', 'DsSeed', 'The brand color. Defaults to `DsSeed.blue`.'),
            (
              'brightness',
              'Brightness',
              'Light or dark. Under `DsScope`, set by `themeMode`.',
            ),
            (
              'contrast',
              'DsContrast',
              '`soft` (the iOS look: faint control edges, below WCAG '
                  '1.4.11 there) or `standard` (AA including 1.4.11, the '
                  'default; what the platform\'s "Increase contrast" gets).',
            ),
            (
              'cornerStyle',
              'DsCornerStyle',
              '`sharp`, `standard`, `soft` or `pill`.',
            ),
            (
              'density',
              'DsDensity?',
              '`compact` or `touch`; without one, `touch` on iOS and Android '
                  'and `compact` elsewhere.',
            ),
            (
              'selectionStyle',
              'DsSelectionStyle',
              '`soft` (default) or `strong`.',
            ),
            (
              'platform',
              'TargetPlatform?',
              'Sets the tap areas. Defaults to the running platform.',
            ),
            (
              'typography',
              'DsTypography?',
              'The type scale and fonts, set for the density.',
            ),
            ('motion', 'DsMotion', 'Springs, delays and reduced motion.'),
            (
              'adjustColors',
              'DsColorsAdjuster?',
              'Edits colors after each generation.',
            ),
            (
              'adjustShadows',
              'DsShadowsAdjuster?',
              'Edits shadow stacks after each generation.',
            ),
            (
              'adjustRadii',
              'DsRadiiAdjuster?',
              'Edits the corner rules for a corner style.',
            ),
            (
              'adjustSizes',
              'DsSizesAdjuster?',
              'Edits the size scale for a density.',
            ),
          ]),
        ],
      ),
    ],
  );
}

/// A small settings card that shows off a theme.
class _Workspace extends StatefulWidget {
  const _Workspace();

  @override
  State<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<_Workspace> {
  bool _mentions = true;
  String _digest = 'daily';
  final _topics = {'Releases'};

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  'Notifications',
                  style: t.typography.heading.copyWith(color: k.text),
                ),
                Text(
                  'Choose what reaches your inbox.',
                  style: t.typography.small.copyWith(color: k.textMuted),
                ),
              ],
            ),
            DsSwitch(
              value: _mentions,
              onChanged: (v) => setState(() => _mentions = v),
              label: const Text('Mentions and replies'),
            ),
            DsSegmentedControl<String>(
              value: _digest,
              onChanged: (v) => setState(() => _digest = v),
              segments: const [
                DsSegment(value: 'off', label: Text('Off')),
                DsSegment(value: 'daily', label: Text('Daily')),
                DsSegment(value: 'weekly', label: Text('Weekly')),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final topic in ['Releases', 'Billing', 'Security'])
                  DsChip(
                    label: Text(topic),
                    selected: _topics.contains(topic),
                    onChanged: (v) => setState(
                      () => v ? _topics.add(topic) : _topics.remove(topic),
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                DsButton(
                  variant: .ghost,
                  onPressed: () {},
                  child: const Text('Reset'),
                ),
                DsButton(onPressed: () {}, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Article extends StatelessWidget {
  const _Article();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              'Release 4.2',
              style: t.typography.heading.copyWith(color: k.text),
            ),
            Text(
              'Faster sync, offline drafts and a new export dialog.',
              style: t.typography.small.copyWith(color: k.textMuted),
            ),
            DsLink(label: 'Read the release notes', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

class _Tones extends StatelessWidget {
  const _Tones();

  @override
  Widget build(BuildContext context) {
    final scope = SiteSettingsScope.of(context);
    final site = DsTheme.of(context);
    return TokenGrid(
      minWidth: 240,
      children: [
        for (final (i, tone) in siteTones.indexed)
          if (i < 6)
            Builder(
              builder: (context) {
                final selected = scope.settings.tone == i;
                final accent = DsThemeData(
                  seed: tone.seed,
                  brightness: site.brightness,
                ).colors.accent;
                final k = site.colors;
                final y = site.typography;
                return DsCard(
                  semanticLabel: '${tone.name} tone',
                  onPressed: () =>
                      scope.onChanged(scope.settings.copyWith(tone: i)),
                  style: selected
                      ? DsCardStyle(
                          shadows: [DsShadow.innerRing(k.indicator, width: 2)],
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: DsBoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tone.name,
                              style: y.labelStrong.copyWith(color: k.text),
                            ),
                          ),
                          if (selected)
                            DsIcon(DsIcons.check, color: k.accentText),
                        ],
                      ),
                      Text(
                        tone.note,
                        style: y.caption.copyWith(color: k.textMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
      ],
    );
  }
}

class _SelectionStyles extends StatelessWidget {
  const _SelectionStyles();

  @override
  Widget build(BuildContext context) {
    final k = DsTheme.colorsOf(context);
    final y = DsTheme.typographyOf(context);
    return TokenGrid(
      minWidth: 220,
      spacing: 24,
      children: [
        for (final style in DsSelectionStyle.values)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(
                style.name,
                style: y.mono(y.caption).copyWith(color: k.textMuted),
              ),
              ThemePreview(
                theme: DsTheme.of(context).copyWith(selectionStyle: style),
                followSelection: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DsSidebarItem(
                      leading: const DsIcon(DsIcons.inbox),
                      label: const Text('Inbox'),
                      count: 4,
                      selected: true,
                      onPressed: () {},
                    ),
                    DsSidebarItem(
                      leading: const DsIcon(DsIcons.folder),
                      label: const Text('Projects'),
                      onPressed: () {},
                    ),
                    DsSidebarItem(
                      leading: const DsIcon(DsIcons.settings),
                      label: const Text('Settings'),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _SwitchDemo extends StatefulWidget {
  const _SwitchDemo();

  @override
  State<_SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<_SwitchDemo> {
  bool? _dark;

  @override
  Widget build(BuildContext context) {
    final site = DsTheme.of(context);
    final dark = _dark ?? !site.isDark;
    final theme = site.copyWith(
      brightness: dark ? Brightness.dark : Brightness.light,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            DsSwitch(
              value: dark,
              onChanged: (v) => setState(() => _dark = v),
              label: const Text('Dark preview'),
            ),
            ThemePreview(
              theme: theme,
              followBrightness: false,
              animateChanges: true,
              child: Builder(
                builder: (context) {
                  final t = DsTheme.of(context);
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: DsBoxDecoration(
                      color: t.colors.canvas,
                      borderRadius: BorderRadius.circular(t.radii.card),
                      shadows: [DsShadow.innerRing(t.colors.border)],
                    ),
                    child: const _Workspace(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
