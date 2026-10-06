import 'dart:ui' show ImageFilter;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Floating layers are opaque; this guide turns them into frosted glass.
class GlassPage extends StatelessWidget {
  const GlassPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Overlays',
    title: 'Layers and glass',
    lead:
        'Menus, popovers, dialogs, panels, toasts, toolbars and tooltips '
        'are opaque by default. Each of their styles takes a '
        '`backdropFilter`, so you can turn them into frosted glass where '
        'your design calls for it.',
    sections: [
      const DocSection(
        title: 'Opaque by default',
        children: [
          DocText(
            'An opaque layer reads the same over any content: a photo, a '
            'chart, a busy table. Desen checks the contrast of every text '
            'and icon color against the layer\'s fill, and those checks '
            'assume nothing shows through. That is why glass is not built '
            'in.',
          ),
        ],
      ),
      DocSection(
        title: 'Frosted glass',
        children: [
          const DocText(
            'Give the layer a translucent `background` and an '
            '`ImageFilter.blur` as its `backdropFilter`. The blur sits under '
            'the fill and is clipped to the layer\'s corners; the shadows '
            'stay outside. Set it once for a part of the app with '
            '`DsComponentThemes`, so every menu, popover and toolbar below '
            'it changes. Turn glass off below to compare, and open the menu '
            'and the popover.',
          ),
          Example(
            snippet: 'glass-themes',
            padding: EdgeInsets.zero,
            child: const _GlassDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Contrast is your responsibility',
        children: [
          Callout(
            'With a translucent fill, text contrast depends on whatever '
            'lies behind the layer, which Desen cannot know. Its contrast '
            'guarantees hold for opaque layers only: in the example above, '
            'the red "Delete page" fades where the menu crosses a red shape. '
            'Test your glass over '
            'the busiest content it can float on, in light and dark mode, '
            'and raise the fill\'s opacity or the blur until text keeps '
            '4.5:1. Consider keeping layers opaque when the user asks for '
            'more contrast (`MediaQuery.highContrastOf`).',
            title: 'Contrast',
            status: DsStatus.warning,
          ),
        ],
      ),
      DocSection(
        title: 'Styles that take a backdrop filter',
        children: [
          DocTable(
            columns: const ['Style', 'Used by'],
            flex: const [4, 6],
            rows: [
              for (final (style, users) in const [
                (
                  'DsMenuStyle',
                  '`DsMenu`, `DsMenuAnchor`, `DsContextMenuRegion`, the list '
                      'of a `DsSelect`',
                ),
                (
                  'DsPopoverStyle',
                  '`DsPopover`, the date and time picker panels',
                ),
                ('DsDialogStyle', '`DsDialog`'),
                ('DsPanelStyle', '`DsPanel` (side panel and bottom sheet)'),
                ('DsToastStyle', '`DsToast`, `showDsToast`'),
                ('DsToolbarStyle', '`DsToolbar`'),
                ('DsTooltipStyle', '`DsTooltip`'),
                ('DsBottomNavStyle', '`DsBottomNav`'),
                (
                  'DsTextSelectionToolbarStyle',
                  'The cut, copy and paste bar of text fields',
                ),
              ])
                [_Mono(style), DocText(users)],
            ],
          ),
        ],
      ),
      DocSection(
        title: 'Custom layers',
        children: [
          const DocText(
            '`DsSurface` is the box every one of these layers is drawn '
            'with: a `DsBoxDecoration` around the content, with an optional '
            '`backdropFilter` for what shows through. Use it for floating '
            'layers of your own, such as a player bar or a selection summary, '
            'and they match the built-in ones, glass or not.',
          ),
          Example(
            snippet: 'glass-surface',
            padding: EdgeInsets.zero,
            child: const _SurfaceDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Cost',
        children: [
          DocText(
            'A backdrop blur reads and blurs what lies behind the layer each '
            'time that area repaints. Keep glass to small floating layers '
            'and avoid stacking several blurred layers on top of each other, '
            'especially on low-end phones.',
          ),
        ],
      ),
    ],
  );
}

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

/// Colorful shapes in the theme's own colors, for something to see
/// through the glass.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child, this.minHeight = 380});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    Widget blob(Color color, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(t.radii.card),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [k.accentTint, k.info.tint, k.success.tint],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Behind the middle, where the layers float.
            for (final (x, y, color, size) in [
              (-0.45, -0.75, k.accent, 200.0),
              (0.4, -0.35, k.warning.fill, 150.0),
              (-0.15, 0.55, k.danger.fill, 170.0),
              (0.75, 0.9, k.success.fill, 130.0),
              (-0.95, 0.8, k.info.fill, 110.0),
            ])
              Positioned.fill(
                child: Align(
                  alignment: Alignment(x, y),
                  child: blob(color, size),
                ),
              ),
            Padding(padding: const EdgeInsets.all(24), child: child),
          ],
        ),
      ),
    );
  }
}

class _GlassDemo extends StatefulWidget {
  const _GlassDemo();

  @override
  State<_GlassDemo> createState() => _GlassDemoState();
}

class _GlassDemoState extends State<_GlassDemo> {
  bool _glass = true;
  bool _bold = true;
  bool _italic = false;

  @override
  Widget build(BuildContext context) {
    final stage = _Backdrop(
      child: Column(
        spacing: 20,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: DsToolbar(
              semanticLabel: 'Formatting',
              // The stage scrolls the bar, so its items always show; the
              // menu and the popover they open have no form in a menu.
              overflow: .scroll,
              children: [
                DsToolbarToggle(
                  icon: const DsIcon(DsIcons.bold),
                  semanticLabel: 'Bold',
                  selected: _bold,
                  onChanged: (v) => setState(() => _bold = v),
                ),
                DsToolbarToggle(
                  icon: const DsIcon(DsIcons.italic),
                  semanticLabel: 'Italic',
                  selected: _italic,
                  onChanged: (v) => setState(() => _italic = v),
                ),
                const DsToolbarDivider(),
                DsMenuAnchor(
                  semanticLabel: 'Insert',
                  items: [
                    DsMenuItem(
                      leading: const DsIcon(DsIcons.link),
                      label: const Text('Link'),
                      shortcut: '⌘K',
                      onPressed: () {},
                    ),
                    DsMenuItem(
                      leading: const DsIcon(DsIcons.calendar),
                      label: const Text('Date'),
                      onPressed: () {},
                    ),
                    DsMenuItem(
                      leading: const DsIcon(DsIcons.user),
                      label: const Text('Mention'),
                      shortcut: '@',
                      onPressed: () {},
                    ),
                  ],
                  builder: (context, controller, _) => DsButton(
                    variant: .ghost,
                    size: .sm,
                    trailing: const DsIcon(DsIcons.chevronDown),
                    onPressed: controller.toggle,
                    child: const Text('Insert'),
                  ),
                ),
                DsPopover(
                  semanticLabel: 'Share',
                  align: .end,
                  style: const DsPopoverStyle(width: 260),
                  contentBuilder: (context) => const _ShareForm(),
                  builder: (context, controller, _) => DsButton(
                    size: .sm,
                    onPressed: controller.toggle,
                    child: const Text('Share'),
                  ),
                ),
              ],
            ),
          ),
          DsMenu(
            semanticLabel: 'Page',
            children: [
              DsMenuItem(
                leading: const DsIcon(DsIcons.copy),
                label: const Text('Duplicate page'),
                shortcut: '⌘D',
                onPressed: () {},
              ),
              DsMenuItem(
                leading: const DsIcon(DsIcons.folder),
                label: const Text('Move to…'),
                onPressed: () {},
              ),
              const DsMenuDivider(),
              DsMenuItem(
                leading: const DsIcon(DsIcons.trash),
                label: const Text('Delete page'),
                destructive: true,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 120,
              child: DsSwitch(
                value: _glass,
                onChanged: (v) => setState(() => _glass = v),
                label: const Text('Glass'),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: _glass ? _GlassScope(child: stage) : stage,
        ),
      ],
    );
  }
}

/// Applies the glass styles to [child].
class _GlassScope extends StatelessWidget {
  const _GlassScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // #region glass-themes
    // One translucent fill and one blur for every floating layer below.
    final fill = DsTheme.colorsOf(context).overlay.withValues(alpha: .6);
    final blur = ImageFilter.blur(sigmaX: 24, sigmaY: 24);
    return DsComponentThemes(
      themes: [
        DsMenuThemeData(
          style: DsMenuStyle(background: fill, backdropFilter: blur),
        ),
        DsPopoverThemeData(
          style: DsPopoverStyle(background: fill, backdropFilter: blur),
        ),
        DsToolbarThemeData(
          style: DsToolbarStyle(background: fill, backdropFilter: blur),
        ),
      ],
      child: child,
    );
    // #endregion
  }
}

class _ShareForm extends StatefulWidget {
  const _ShareForm();

  @override
  State<_ShareForm> createState() => _ShareFormState();
}

class _ShareFormState extends State<_ShareForm> {
  bool _comments = true;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Text('Share this page', style: t.typography.bodyStrong),
        Text(
          'Anyone in Northwind with the link can view it.',
          style: t.typography.caption.copyWith(color: t.colors.textMuted),
        ),
        DsSwitch(
          value: _comments,
          onChanged: (v) => setState(() => _comments = v),
          label: const Text('Allow comments'),
        ),
      ],
    );
  }
}

class _SurfaceDemo extends StatelessWidget {
  const _SurfaceDemo();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _Backdrop(
        minHeight: 200,
        child: Container(
          height: 152,
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            // #region glass-surface
            child: DsSurface(
              decoration: DsBoxDecoration(
                color: k.overlay.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(t.radii.overlay),
                shadows: t.shadows.overlay,
              ),
              backdropFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      '4 tasks selected',
                      style: t.typography.bodyStrong.copyWith(color: k.text),
                    ),
                  ),
                  DsButton(
                    variant: .ghost,
                    size: .sm,
                    onPressed: () {},
                    child: const Text('Clear'),
                  ),
                  DsButton(
                    size: .sm,
                    onPressed: () {},
                    child: const Text('Move'),
                  ),
                ],
              ),
            ),
            // #endregion
          ),
        ),
      ),
    );
  }
}
