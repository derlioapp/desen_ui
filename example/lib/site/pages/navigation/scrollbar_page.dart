import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';

class ScrollbarPage extends StatelessWidget {
  const ScrollbarPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Navigation',
    title: 'Scrollbar',
    lead:
        'A thin thumb along the edge of a scrolling area, with no track. '
        'On desktop, `DsScrollBehavior` (installed by `DsApp`) adds one to '
        'every scrollable, so you rarely build one yourself. On phones '
        'there is none, as on the platform.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          DocText(
            'The thumb shows while the content scrolls and fades away '
            'after. It gets stronger under the pointer and stronger still '
            'while dragged. Dragging it scrolls; a click beside it pages '
            'toward the click.',
          ),
          Example(snippet: 'scrollbar-overview', child: _Demo()),
        ],
      ),
      DocSection(
        title: 'Always visible',
        children: [
          DocText(
            '`alwaysVisible: true` keeps the thumb at rest, for a pane whose '
            'length the reader should see at a glance, such as a long '
            'settings column. The thumb shows before any scroll, so give it '
            'the scrollable\'s `controller`.',
          ),
          Example(
            snippet: 'scrollbar-always',
            child: _Demo(alwaysVisible: true),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Pass `style` to one scrollbar, or put a `DsScrollbarTheme` '
            'around part of the app: it also reaches the scrollbars that '
            '`DsScrollBehavior` adds. `hovered` and `pressed` style the '
            'thumb under the pointer and while dragged. The theme can also '
            'make every thumb `alwaysVisible`.',
          ),
          CodeBlock(
            'DsScrollbarTheme(\n'
            '  data: DsScrollbarThemeData(\n'
            '    alwaysVisible: true,\n'
            '    style: DsScrollbarStyle(\n'
            '      thickness: 8,\n'
            '      hovered: DsScrollbarStyle(thickness: 10),\n'
            '    ),\n'
            '  ),\n'
            '  child: settingsPane,\n'
            ')',
          ),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The scrollbar is a pointer aid; keyboard users scroll with the '
                'arrow, Page and Home/End keys of the scrollable, and screen '
                'readers with their own gestures.',
            'It follows reduced motion: the fade is a short tone change, '
                'with no movement.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          DocHeading('DsScrollbar'),
          ApiTable([
            ('child', 'Widget', 'The scrollable, or a widget around one.'),
            (
              'controller',
              'ScrollController?',
              'The scrollable\'s controller; needed for `alwaysVisible`.',
            ),
            (
              'alwaysVisible',
              'bool?',
              'Keeps the thumb at rest. Defaults to the theme, then false.',
            ),
            (
              'interactive',
              'bool',
              'Whether the thumb drags and the lane pages. Default true.',
            ),
            (
              'notificationPredicate',
              'ScrollNotificationPredicate?',
              'Which scroll notifications to follow; the nearest '
                  'scrollable by default.',
            ),
            (
              'scrollbarOrientation',
              'ScrollbarOrientation?',
              'The edge the bar runs along.',
            ),
            (
              'style',
              'DsScrollbarStyle?',
              'Thumb color, thickness, margins and minimum length, per '
                  'state.',
            ),
          ]),
        ],
      ),
    ],
  );
}

class _Demo extends StatefulWidget {
  const _Demo({this.alwaysVisible = false});

  final bool alwaysVisible;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final rows = [
      for (var i = 1; i <= 30; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            'Row $i',
            style: t.typography.body.copyWith(color: t.colors.text),
          ),
        ),
    ];
    return SizedBox(
      width: 280,
      height: 200,
      // The page's scroll behavior would add a second bar.
      child: ScrollConfiguration(
        behavior: const DsScrollBehavior().copyWith(scrollbars: false),
        child: _bar(rows),
      ),
    );
  }

  Widget _bar(List<Widget> rows) {
    if (widget.alwaysVisible) {
      // #region scrollbar-always
      return DsScrollbar(
        controller: _controller,
        alwaysVisible: true,
        child: ListView(controller: _controller, children: rows),
      );
      // #endregion
    }
    // #region scrollbar-overview
    return DsScrollbar(
      controller: _controller,
      child: ListView(controller: _controller, children: rows),
    );
    // #endregion
  }
}
