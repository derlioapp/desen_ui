import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import 'doc.dart';
import 'links.dart';
import 'pages.dart';
import 'registry.dart';
import 'search.dart';
import 'settings.dart';

/// Below this width the sidebar folds into a menu button.
const double kSidebarBreakpoint = 960;

/// The frame around every page: a header with search and settings, the
/// navigation, and the page itself.
class SiteShell extends StatelessWidget {
  const SiteShell({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final page = pageAt(path);
    final k = DsTheme.colorsOf(context);
    return Title(
      title: page == null ? 'Desen UI' : '${page.title} · Desen UI',
      color: k.accent,
      child: ColoredBox(
        color: k.canvas,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= kSidebarBreakpoint;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(path: path, compact: !wide),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (wide) _Nav(path: path),
                      Expanded(
                        child: KeyedSubtree(
                          key: ValueKey(path),
                          child: page?.builder(context) ?? _NotFound(path),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound(this.path);

  final String path;

  @override
  Widget build(BuildContext context) => DocPage(
    title: 'Page not found',
    lead: 'There is no page at `$path`. [Go to the introduction](/).',
  );
}

class _Nav extends StatelessWidget {
  const _Nav({required this.path, this.onOpened});

  final String path;

  /// Called after a page is chosen, e.g. to close the menu panel.
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context) {
    final links = SiteLinks.of(context);
    final items = [
      for (final group in siteGroups) ...[
        DsSidebarSection(label: Text(group.title.toUpperCase())),
        for (final page in group.pages)
          DsSidebarItem(
            label: Text(page.title),
            selected: page.path == path,
            onPressed: () {
              links.go(page.path);
              onOpened?.call();
            },
          ),
      ],
    ];
    if (onOpened != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      );
    }
    return DsSidebar(
      semanticLabel: 'Documentation',
      style: const DsSidebarStyle(width: 248),
      children: items,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.path, required this.compact});

  final String path;
  final bool compact;

  void _openMenu(BuildContext context) => showDsPanel<void>(
    context: context,
    builder: (panel) => DsPanel(
      title: const Text('Desen UI'),
      child: _Nav(path: path, onOpened: () => Navigator.of(panel).pop()),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final settings = SiteSettingsScope.of(context);
    final dark = t.isDark;
    final narrow = MediaQuery.sizeOf(context).width < 640;
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: narrow ? 8 : 16),
      decoration: BoxDecoration(
        color: k.surface,
        border: Border(bottom: BorderSide(color: k.border)),
      ),
      child: Row(
        spacing: 8,
        children: [
          if (compact)
            DsButton.icon(
              variant: .ghost,
              semanticLabel: 'Menu',
              icon: const DsIcon(DsIcons.menu),
              onPressed: () => _openMenu(context),
            ),
          const _Logo(),
          const Spacer(),
          SiteSearchButton(compact: narrow),
          DsTooltip(
            message: dark ? 'Light appearance' : 'Dark appearance',
            child: DsButton.icon(
              variant: .ghost,
              semanticLabel: dark ? 'Light appearance' : 'Dark appearance',
              icon: DsIcon(dark ? DsIcons.sun : DsIcons.moon),
              onPressed: () => settings.onChanged(
                settings.settings.copyWith(
                  mode: dark ? DsThemeMode.light : DsThemeMode.dark,
                ),
              ),
            ),
          ),
          DsPopover(
            align: DsAlign.end,
            semanticLabel: 'Settings',
            contentBuilder: (_) => const SettingsForm(),
            builder: (context, controller, _) => DsTooltip(
              message: 'Theme settings',
              child: DsButton.icon(
                variant: .ghost,
                semanticLabel: 'Theme settings',
                icon: const DsIcon(DsIcons.slidersHorizontal),
                onPressed: controller.toggle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return Semantics(
      link: true,
      label: 'Desen UI, home',
      child: DsPressable(
        onPressed: () => SiteLinks.of(context).go('/'),
        builder: (context, states, _) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: DsBoxDecoration(
                color: k.accent,
                borderRadius: BorderRadius.circular(t.radii.control(26)),
              ),
              child: Text(
                'D',
                style: t.typography.labelStrong.copyWith(
                  color: k.onAccent,
                  fontSize: 15,
                ),
              ),
            ),
            ExcludeSemantics(
              child: Text(
                'Desen UI',
                style: t.typography.heading.copyWith(color: k.text),
              ),
            ),
            // Room for the header's buttons on a phone.
            if (MediaQuery.sizeOf(context).width >= 480)
              ExcludeSemantics(
                child: DsBadge(label: const Text('0.1 dev'), dot: false),
              ),
          ],
        ),
      ),
    );
  }
}

/// The theme settings, in the header's popover.
class SettingsForm extends StatelessWidget {
  const SettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = SiteSettingsScope.of(context);
    final s = scope.settings;
    void set(SiteSettings next) => scope.onChanged(next);
    Widget seg<T>(
      String label,
      T value,
      Map<T, String> options,
      SiteSettings Function(T) apply,
    ) => DsField(
      label: Text(label),
      child: DsSegmentedControl<T>(
        value: value,
        onChanged: (v) => set(apply(v)),
        segments: [
          for (final e in options.entries)
            DsSegment(value: e.key, label: Text(e.value)),
        ],
      ),
    );
    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          DsField(
            label: const Text('Tone'),
            description: Text(siteTones[s.tone].note),
            child: DsSelect<int>(
              value: s.tone,
              onChanged: (v) => set(s.copyWith(tone: v)),
              options: [
                for (final (i, tone) in siteTones.indexed)
                  DsSelectOption(
                    value: i,
                    label: tone.name,
                    leading: _Swatch(tone.seed),
                  ),
              ],
            ),
          ),
          seg('Appearance', s.mode, const {
            DsThemeMode.light: 'Light',
            DsThemeMode.dark: 'Dark',
            DsThemeMode.system: 'System',
          }, (v) => s.copyWith(mode: v)),
          seg('Contrast', s.contrast, const {
            DsContrast.soft: 'Soft',
            DsContrast.standard: 'Standard',
          }, (v) => s.copyWith(contrast: v)),
          seg('Corners', s.corners, const {
            DsCornerStyle.sharp: 'Sharp',
            DsCornerStyle.standard: 'Standard',
            DsCornerStyle.soft: 'Soft',
            DsCornerStyle.pill: 'Pill',
          }, (v) => s.copyWith(corners: v)),
          seg('Density', s.density, const {
            DsDensity.compact: 'Compact',
            DsDensity.touch: 'Touch',
          }, (v) => s.copyWith(density: v)),
          seg('Selection', s.selection, const {
            DsSelectionStyle.soft: 'Soft',
            DsSelectionStyle.strong: 'Strong',
          }, (v) => s.copyWith(selection: v)),
          DsField(
            label: const Text('Example language'),
            description: const Text(
              'Built-in strings, dates and direction in the examples.',
            ),
            child: DsSelect<String>(
              value: previewLocaleKey(s.previewLocale),
              onChanged: (v) =>
                  set(s.copyWith(previewLocale: previewLocaleOf(v!))),
              options: [
                for (final e in previewLanguages.entries)
                  DsSelectOption(value: e.key, label: e.value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Each tone's accent, generated once.
final _accents = <DsSeed, Color>{};

class _Swatch extends StatelessWidget {
  const _Swatch(this.seed);

  final DsSeed seed;

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: DsBoxDecoration(
      color: (_accents[seed] ??= DsThemeData(seed: seed).colors.accent),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

/// The page registered at [path], if any.
SitePage? pageAt(String path) {
  for (final group in siteGroups) {
    for (final page in group.pages) {
      if (page.path == path) return page;
    }
  }
  return null;
}
