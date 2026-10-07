import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';
import '../../icon_catalog.dart';
import 'common.dart';

/// Every built-in icon, searchable, with sizing and other icon sets.
class IconsPage extends StatelessWidget {
  const IconsPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Foundations',
    title: 'Icons',
    lead:
        '${iconCatalog.length} stroke icons from Desen\'s fork of Lucide, '
        'drawn from SVG paths. Icons an app does not use add nothing to its '
        'size. '
        'Components take icons as widgets, so any other icon set works too.',
    sections: [
      const DocSection(
        title: 'All icons',
        children: [
          DocText(
            'Desen\'s icons are a fork of [Lucide](https://lucide.dev): the '
            'shapes come from Lucide 1.52.0 and Lucide Lab, under the ISC '
            'license, and Desen keeps its own copy. Changes made upstream '
            'after that are taken in only once they are reviewed, so an icon '
            'never changes or disappears with a Lucide release.',
          ),
          DocText(
            'Search by name, alias or meaning, and click an icon to copy its '
            'name. Names follow Lucide\'s in camel case (`triangle-alert` is '
            '`DsIcons.triangleAlert`); some icons also have a more common '
            'alias (`volume2` is also `volumeUp`).',
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
        title: 'Filled icons',
        children: [
          DocText(
            '`fill` fills each closed shape of an icon, for solid states such '
            'as a play button or a selected tab. The stroke still runs '
            'around the fill, so the solid icon is the same size as the '
            'outlined one. A mark inside a filled shape (the "!" in an '
            'alert) is cut out so it stays visible. Open strokes stay '
            'strokes: icons drawn from them come out partly filled or '
            'unchanged, so look at the filled form of the icon you pick. '
            'Set it on `DsIconData` for a shape that is always solid, or on '
            '`DsIcon` to switch the same icon.',
          ),
          Example(
            snippet: 'icons-fill',
            child: Wrap(
              spacing: 20,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // #region icons-fill
                DsIcon(DsIcons.play, size: 24),
                DsIcon(DsIcons.play, size: 24, fill: true),
                DsIcon(DsIcons.pause, size: 24, fill: true),
                DsIcon(DsIcons.heart, size: 24, fill: true),
                DsIcon(DsIcons.star, size: 24, fill: true),
                // #endregion
              ],
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
              'fill',
              'bool?',
              'Fill the paths as well. Null follows the icon\'s own (off) '
                  'and the icon theme\'s `fill` (on at 0.5 or more, as in a '
                  'selected bottom navigation item).',
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

class _IconBrowser extends StatefulWidget {
  const _IconBrowser();

  @override
  State<_IconBrowser> createState() => _IconBrowserState();
}

class _IconBrowserState extends State<_IconBrowser> {
  String _query = '';
  bool _filled = false;

  List<IconEntry> get _matches {
    final q = dsFoldCase(_query.trim());
    if (q.isEmpty) return iconCatalog;
    bool hit(String word) => dsFoldCase(word).contains(q);
    return [
      for (final icon in iconCatalog)
        if (hit(icon.name) ||
            hit(icon.category) ||
            icon.aliases.any(hit) ||
            icon.tags.any(hit))
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
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: DsTextField(
                onChanged: (v) => setState(() => _query = v),
                placeholder: 'Search ${iconCatalog.length} icons',
                semanticLabel: 'Search icons',
                leading: const DsIcon(DsIcons.search),
                clearable: true,
              ),
            ),
            DsSegmentedControl<bool>(
              value: _filled,
              onChanged: (v) => setState(() => _filled = v),
              semanticLabel: 'Icon style',
              segments: const [
                DsSegment(value: false, label: Text('Outline')),
                DsSegment(value: true, label: Text('Filled')),
              ],
            ),
          ],
        ),
        if (matches.isEmpty)
          DsEmptyState(
            icon: const DsIcon(DsIcons.searchX),
            title: const Text('No icons found'),
            description: Text('Nothing matches “$_query”. Try a shorter word.'),
          )
        else
          // A lazy grid with its own scroll: building every tile at once
          // would cost thousands of widgets.
          SizedBox(
            height: 480,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 112,
                mainAxisExtent: 80,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: matches.length,
              itemBuilder: (context, i) {
                final entry = matches[i];
                final words = [...entry.aliases, ...entry.tags].take(6);
                // An icon whose details merge when filled shows outlined,
                // as its docs recommend.
                final unfilled = _filled && !entry.fills;
                return _IconTile(
                  name: entry.name,
                  icon: entry.icon,
                  filled: _filled && entry.fills,
                  meaning: unfilled
                      ? 'Use outlined: its details merge when filled'
                      : words.join(', '),
                  onPressed: () => _copy(entry.name),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.name,
    required this.icon,
    required this.filled,
    required this.meaning,
    required this.onPressed,
  });

  final String name;
  final DsIconData icon;
  final bool filled;
  final String meaning;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final tile = DsPressable(
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
              DsIcon(icon, size: 20, color: k.text, fill: filled),
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
    );
    return meaning.isEmpty ? tile : DsTooltip(message: meaning, child: tile);
  }
}
