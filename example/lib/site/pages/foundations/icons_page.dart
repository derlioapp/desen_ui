import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';
import 'common.dart';

/// Every built-in icon, searchable, with sizing and other icon sets.
class IconsPage extends StatelessWidget {
  const IconsPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Foundations',
    title: 'Icons',
    lead:
        '${_icons.length} stroke icons in the Lucide style, drawn from SVG '
        'paths. Desen uses them inside its components. Your own UI can use '
        'them, or any other icon set: components take icons as widgets.',
    sections: [
      const DocSection(
        title: 'All icons',
        children: [
          DocText(
            'Search by name or meaning, and click an icon to copy its name. '
            'The shapes come from [Lucide](https://lucide.dev) under the ISC '
            'license.',
          ),
          Board(child: _IconBrowser()),
        ],
      ),
      DocSection(
        title: 'Size and color',
        children: [
          const DocText(
            '`DsIcon` takes its size and color from the ambient `IconTheme`: '
            '16px in the text color under `DsScope`. Components set both for '
            'the icons you pass them: 14, 16, 16 and 20px for the four '
            'control sizes, in the control\'s ink. The stroke scales with the '
            'size, like an SVG on the web: a 2-unit stroke on the 24-unit '
            'grid is 1.33px at 16px.',
          ),
          Example(
            snippet: 'icons-size',
            child: Builder(
              builder: (context) {
                final k = DsTheme.colorsOf(context);
                return Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // #region icons-size
                    const DsIcon(DsIcons.bell, size: 14),
                    const DsIcon(DsIcons.bell),
                    const DsIcon(DsIcons.bell, size: 20),
                    const DsIcon(DsIcons.bell, size: 24),
                    DsIcon(DsIcons.bell, size: 32, color: k.accentText),
                    const DsIcon(DsIcons.bell, size: 32, strokeWidth: 1.5),
                    // #endregion
                  ],
                );
              },
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'An icon is decorative by default and hidden from screen '
                'readers. Give it a `semanticLabel` when it carries meaning '
                'on its own.',
            'An icon-only button is named by the button\'s own '
                '`semanticLabel`, not by the icon.',
            'Icons with a direction (`chevronLeft`, `chevronRight`) mirror '
                'in right-to-left text through `matchTextDirection`.',
          ]),
        ],
      ),
      DocSection(
        title: 'Your own icons',
        children: [
          const DocText(
            '`DsIconData` takes SVG path strings on a square grid, 24 units '
            'by default, drawn as strokes. A path from a 24px stroke icon set '
            'pastes in as it is.',
          ),
          Example(
            snippet: 'icons-custom',
            child: Builder(
              builder: (context) =>
                  // #region icons-custom
                  DsButton(
                    variant: .secondary,
                    leading: const DsIcon(
                      DsIconData([
                        'M12 3l2.5 6.5L21 12l-6.5 2.5L12 21l-2.5-6.5L3 12l6.5-2.5z',
                      ]),
                    ),
                    onPressed: () {},
                    child: const Text('Summarize'),
                  ),
              // #endregion
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Another icon set',
        children: [
          DocText(
            'Every slot that shows an icon (`leading`, `trailing`, `icon`) '
            'takes a widget, so any icon works there: Flutter\'s `Icon` with '
            'an icon font, an SVG or an image. Flutter\'s `Icon` reads the '
            'same `IconTheme`, so it gets the size and color the component '
            'sets.',
          ),
          CodeBlock(
            '// Any IconData from an icon font package.\n'
            'DsButton(\n'
            '  leading: const Icon(MyIcons.plus),\n'
            '  onPressed: () {},\n'
            "  child: const Text('New task'),\n"
            ')',
          ),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('icon', 'DsIconData', 'The shape to draw.'),
            (
              'size',
              'double?',
              'Width and height. Defaults to the `IconTheme` size, then 16.',
            ),
            ('color', 'Color?', 'Defaults to the `IconTheme` color.'),
            (
              'strokeWidth',
              'double?',
              'In grid units; overrides the icon\'s own (2).',
            ),
            (
              'semanticLabel',
              'String?',
              'Read by screen readers. Without it the icon is hidden.',
            ),
          ]),
        ],
      ),
    ],
  );
}

/// The built-in icons with what they mean (from the dartdoc of each
/// icon); `DsIcons.all` guards that none is missing.
const _icons = <(String, DsIconData, String)>[
  ('plus', DsIcons.plus, 'Plus'),
  ('minus', DsIcons.minus, 'Minus'),
  ('check', DsIcons.check, 'Check mark'),
  ('x', DsIcons.x, 'Close / clear'),
  ('chevronDown', DsIcons.chevronDown, 'Chevron pointing down'),
  ('chevronUp', DsIcons.chevronUp, 'Chevron pointing up'),
  ('chevronLeft', DsIcons.chevronLeft, 'Chevron pointing left'),
  ('chevronRight', DsIcons.chevronRight, 'Chevron pointing right'),
  ('ellipsis', DsIcons.ellipsis, 'Horizontal ellipsis (more)'),
  ('search', DsIcons.search, 'Magnifier'),
  ('circleAlert', DsIcons.circleAlert, 'Error'),
  ('circleCheck', DsIcons.circleCheck, 'Success'),
  ('info', DsIcons.info, 'Information'),
  ('triangleAlert', DsIcons.triangleAlert, 'Warning'),
  ('mail', DsIcons.mail, 'Envelope'),
  ('calendar', DsIcons.calendar, 'Calendar'),
  ('layoutGrid', DsIcons.layoutGrid, 'Grid layout'),
  ('list', DsIcons.list, 'List layout'),
  ('bold', DsIcons.bold, 'Bold text'),
  ('italic', DsIcons.italic, 'Italic text'),
  ('underline', DsIcons.underline, 'Underlined text'),
  ('bell', DsIcons.bell, 'Notifications'),
  ('inbox', DsIcons.inbox, 'Inbox'),
  ('user', DsIcons.user, 'Person'),
  ('arrowUpRight', DsIcons.arrowUpRight, 'External link'),
  ('volumeLow', DsIcons.volumeLow, 'Volume, low'),
  ('volumeHigh', DsIcons.volumeHigh, 'Volume, high'),
  ('chevronsUpDown', DsIcons.chevronsUpDown, 'A switcher or sort'),
  ('sun', DsIcons.sun, 'Light appearance'),
  ('moon', DsIcons.moon, 'Dark appearance'),
  ('menu', DsIcons.menu, 'Menu (navigation)'),
  ('folder', DsIcons.folder, 'Folder'),
  ('house', DsIcons.house, 'Home'),
  ('globe', DsIcons.globe, 'Language or web'),
  ('logOut', DsIcons.logOut, 'Sign out'),
  ('share', DsIcons.share, 'Share'),
  ('link', DsIcons.link, 'Link'),
  ('copy', DsIcons.copy, 'Copy'),
  ('trash', DsIcons.trash, 'Delete'),
  ('slidersHorizontal', DsIcons.slidersHorizontal, 'Filters'),
  ('eye', DsIcons.eye, 'Show a password'),
  ('eyeOff', DsIcons.eyeOff, 'Hide a password'),
  ('command', DsIcons.command, 'Command key (⌘)'),
  ('option', DsIcons.option, 'Option key (⌥)'),
  ('shift', DsIcons.shift, 'Shift key (⇧)'),
  ('backspace', DsIcons.backspace, 'Backspace key (⌫)'),
  ('enter', DsIcons.enter, 'Return key (⏎)'),
  ('upload', DsIcons.upload, 'Upload'),
  ('fileText', DsIcons.fileText, 'File with text lines'),
  ('clock', DsIcons.clock, 'Clock'),
  ('arrowUp', DsIcons.arrowUp, 'Arrow up, ascending sort'),
  ('arrowDown', DsIcons.arrowDown, 'Arrow down, descending sort'),
  ('searchX', DsIcons.searchX, 'Nothing found'),
  ('imageOff', DsIcons.imageOff, 'An image that cannot be shown'),
  ('settings', DsIcons.settings, 'Settings (gear)'),
];

class _IconBrowser extends StatefulWidget {
  const _IconBrowser();

  @override
  State<_IconBrowser> createState() => _IconBrowserState();
}

class _IconBrowserState extends State<_IconBrowser> {
  String _query = '';

  List<(String, DsIconData, String)> get _matches {
    final q = dsFoldCase(_query.trim());
    assert(
      _icons.length == DsIcons.all.length,
      'the icons page lists ${_icons.length} of ${DsIcons.all.length} icons',
    );
    if (q.isEmpty) return _icons;
    return [
      for (final icon in _icons)
        if (dsFoldCase(icon.$1).contains(q) || dsFoldCase(icon.$3).contains(q))
          icon,
    ];
  }

  Future<void> _copy(String name) async {
    var copied = true;
    try {
      await Clipboard.setData(ClipboardData(text: 'DsIcons.$name'));
    } on Object {
      // The browser may refuse clipboard access.
      copied = false;
    }
    if (!mounted) return;
    showDsToast(
      context: context,
      title: copied ? 'Copied DsIcons.$name' : 'Could not copy DsIcons.$name',
      status: copied ? DsStatus.success : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: DsTextField(
              onChanged: (v) => setState(() => _query = v),
              placeholder: 'Search ${_icons.length} icons',
              semanticLabel: 'Search icons',
              leading: const DsIcon(DsIcons.search),
              clearable: true,
            ),
          ),
        ),
        if (matches.isEmpty)
          DsEmptyState(
            icon: const DsIcon(DsIcons.searchX),
            title: const Text('No icons found'),
            description: Text('Nothing matches “$_query”. Try a shorter word.'),
          )
        else
          TokenGrid(
            minWidth: 96,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (name, icon, meaning) in matches)
                _IconTile(
                  name: name,
                  icon: icon,
                  meaning: meaning,
                  onPressed: () => _copy(name),
                ),
            ],
          ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.name,
    required this.icon,
    required this.meaning,
    required this.onPressed,
  });

  final String name;
  final DsIconData icon;
  final String meaning;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return DsTooltip(
      message: meaning,
      child: DsPressable(
        onPressed: onPressed,
        semanticLabel: 'Copy DsIcons.$name',
        builder: (context, states, _) {
          final hovered = states.contains(WidgetState.hovered);
          final pressed = states.contains(WidgetState.pressed);
          return Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: DsBoxDecoration(
              color: pressed ? k.press : (hovered ? k.hover : null),
              borderRadius: BorderRadius.circular(
                t.radii.nested(t.radii.card, DsSpace.s4),
              ),
              shadows: [
                if (states.contains(WidgetState.focused))
                  DsShadow.innerRing(k.focus, width: 2),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10,
              children: [
                DsIcon(icon, size: 20, color: k.text),
                // Long names shrink a little rather than lose letters.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: t.typography
                        .mono(t.typography.caption)
                        .copyWith(color: k.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
