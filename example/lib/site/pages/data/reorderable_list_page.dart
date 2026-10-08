import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';

class ReorderableListPage extends StatelessWidget {
  const ReorderableListPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Data display',
    title: 'Reorderable list',
    lead:
        'A list whose items people put in their own order: favorites, a '
        'playlist, a task list, the order of a menu. Drag an item by its '
        'handle, or long-press it on a phone.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          DocText(
            'Each item gets a grip handle at its end. The lifted item floats '
            'above the others, which make room, and the list scrolls when '
            'it is dragged near an edge. Your data stays yours: `onReorder` '
            'gets the item\'s index and the index it ends up at, counted '
            'after the move.',
          ),
          Example(snippet: 'reorderable-overview', child: _Demo()),
          DocText(
            'Every item needs a key that moves with it, such as '
            '`ValueKey(item.id)`, so the list can tell which item went '
            'where.',
          ),
        ],
      ),
      DocSection(
        title: 'Edit mode',
        children: [
          DocText(
            'A null `onReorder` turns reordering off: no handles, no '
            'actions, a plain list. Pass it only while an "Edit" toggle is '
            'on to keep the handles out of the way the rest of the time.',
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Pass `style` to one list, or put a `DsReorderableListTheme` '
            'around part of the app: the handle\'s color, size and spacing '
            'per state, and the lifted item\'s fill, shadow, corners and '
            'scale.',
          ),
          CodeBlock(
            'DsReorderableList(\n'
            '  itemCount: items.length,\n'
            '  itemBuilder: buildRow,\n'
            '  onReorder: move,\n'
            '  style: DsReorderableListStyle(\n'
            '    liftedScale: 1,\n'
            '    hovered: DsReorderableListStyle(handleColor: accent),\n'
            '  ),\n'
            ')',
          ),
        ],
      ),
      DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            ('Tab', 'Moves focus to the next handle.'),
            ('↑ / ↓', 'On a handle, moves its item one place.'),
            ('Home / End', 'On a handle, moves its item to the start or end.'),
            (
              'Alt + ↑ / ↓',
              'Moves the item from anywhere inside it, such as a focused '
                  'row.',
            ),
          ]),
          DocText('Focus stays on the item as it moves.'),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Screen readers get actions on each item: "Move up", "Move '
                'down", "Move to the start" and "Move to the end", in the '
                'app\'s language under `DsApp`. The handle itself is not '
                'announced.',
            'A lift and a drop each tick as the platform\'s selection '
                'haptic; keyboard and screen reader moves are silent.',
            'The handle is at least the theme\'s tap target: 24px on '
                'desktop, 44px on iOS and Android.',
            'With reduced motion the lifted item does not grow; it still '
                'shows its shadow. The other items still slide to make room: '
                'Flutter 3.47\'s reorderable list has no setting for that '
                'motion.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          DocHeading('DsReorderableList'),
          ApiTable([
            ('itemCount', 'int', 'How many items there are.'),
            (
              'itemBuilder',
              'IndexedWidgetBuilder',
              'Builds an item; each needs a key that moves with it.',
            ),
            (
              'onReorder',
              'void Function(int from, int to)?',
              'An item moved; `to` counts after the move. Null turns '
                  'reordering off.',
            ),
            ('controller', 'ScrollController?', 'The scroll position.'),
            ('physics', 'ScrollPhysics?', 'How the list scrolls.'),
            (
              'shrinkWrap',
              'bool',
              'Takes the height of its items, inside a page that scrolls.',
            ),
            ('padding', 'EdgeInsetsGeometry?', 'Space around the items.'),
            (
              'style',
              'DsReorderableListStyle?',
              'Handle and lifted item, per state.',
            ),
          ]),
        ],
      ),
    ],
  );
}

class _Demo extends StatefulWidget {
  const _Demo();

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  final _stations = ['Radio Nova', 'Jazz FM', 'KEXP', 'NTS 1', 'FIP'];

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 340,
    child: DsCard(
      style: const DsCardStyle(padding: EdgeInsets.zero),
      // #region reorderable-overview
      child: DsReorderableList(
        shrinkWrap: true,
        itemCount: _stations.length,
        itemBuilder: (context, i) => DsListRow(
          key: ValueKey(_stations[i]),
          leading: const DsIcon(DsIcons.radio),
          title: Text(_stations[i]),
        ),
        onReorder: (from, to) =>
            setState(() => _stations.insert(to, _stations.removeAt(from))),
      ),
      // #endregion
    ),
  );
}
