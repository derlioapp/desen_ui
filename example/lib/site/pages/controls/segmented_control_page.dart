import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class SegmentedControlPage extends StatelessWidget {
  const SegmentedControlPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Selection controls',
    title: 'Segmented control',
    lead:
        'Picks one of two to five options that change how the same content '
        'is shown: a time range, a view, a unit. To move between different '
        'sections of a page, use [Tabs](/components/tabs); for a longer list '
        'of choices, a [Radio](/components/radio) group or a '
        '[Select](/components/select).',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [Example(snippet: 'segmented-overview', child: _RangeDemo())],
      ),
      const DocSection(
        title: 'Icons',
        children: [
          DocText(
            'A segment takes a `label`, an `icon`, or both. Icon-only '
            'segments need a `semanticLabel`; the constructor asserts it. '
            'Pair them with a tooltip when the icons are not obvious.',
          ),
          Example(snippet: 'segmented-icons', child: _ViewDemo()),
        ],
      ),
      const DocSection(
        title: 'Width',
        children: [
          DocText(
            'Every segment is as wide as the widest one, so the control '
            'looks even. In a narrower space the segments share what there '
            'is and labels ellipsize; screen readers still get the whole '
            'label. The selected label turns semibold, and every segment '
            'reserves that width, so moving the selection never resizes the '
            'control.',
          ),
          Example(snippet: 'segmented-width', child: _UnitDemo()),
        ],
      ),
      const DocSection(
        title: 'Disabled',
        children: [
          DocText(
            '`enabled: false` on a segment turns off that option; arrow '
            'keys skip it. A null `onChanged` disables the whole control.',
          ),
          Example(snippet: 'segmented-disabled', child: _DisabledDemo()),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one control with `style`, or every one in a subtree with '
            '`DsSegmentedControlTheme`. The indicator follows the theme\'s '
            'selection style: a raised thumb for `DsSelectionStyle.soft`, '
            'the strong selection fill for `DsSelectionStyle.strong`. See '
            '[Theming](/theming).',
          ),
          const Example(snippet: 'segmented-custom', child: _CustomDemo()),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          DocText(
            'The control is one Tab stop; the arrows move the selection.',
          ),
          KeyboardTable([
            ('Tab', 'Moves focus to the control.'),
            (
              'Right / Down',
              'Selects the next segment, skipping disabled ones and wrapping '
                  'around. In right-to-left layouts, Right selects the '
                  'previous one.',
            ),
            (
              'Left / Up',
              'Selects the previous segment. In right-to-left layouts, Left '
                  'selects the next one.',
            ),
            ('Home / End', 'Selects the first or last enabled segment.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a radio group, named by `semanticLabel`; each '
                'segment as a radio, with the selected one checked.',
            'The selection does not rest on the thumb alone: the selected '
                'label is also semibold and in full ink.',
            'A `value` that matches no segment selects none.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsSegmentedControl'),
          ApiTable([
            ('segments', 'List<DsSegment<T>>', 'The options, two or more.'),
            ('value', 'T', 'The selected value.'),
            (
              'onChanged',
              'ValueChanged<T>?',
              'Called with the newly selected value. Null disables the '
                  'control.',
            ),
            ('semanticLabel', 'String?', 'Names the group for screen readers.'),
            (
              'style',
              'DsSegmentedControlStyle?',
              'Laid over the theme and defaults.',
            ),
          ]),
          DocHeading('DsSegment'),
          ApiTable([
            ('value', 'T', 'The value this segment stands for.'),
            ('label', 'Widget?', 'A short `Text`.'),
            ('icon', 'Widget?', 'An icon, alone or before the label.'),
            (
              'semanticLabel',
              'String?',
              'Name for screen readers; required without a label.',
            ),
            ('enabled', 'bool', 'Whether this segment can be chosen.'),
          ]),
        ],
      ),
    ],
  );
}

class _RangeDemo extends StatefulWidget {
  const _RangeDemo();

  @override
  State<_RangeDemo> createState() => _RangeDemoState();
}

class _RangeDemoState extends State<_RangeDemo> {
  String _range = 'week';

  @override
  Widget build(BuildContext context) =>
      // #region segmented-overview
      DsSegmentedControl<String>(
        value: _range,
        onChanged: (v) => setState(() => _range = v),
        semanticLabel: 'Time range',
        segments: const [
          DsSegment(value: 'day', label: Text('Day')),
          DsSegment(value: 'week', label: Text('Week')),
          DsSegment(value: 'month', label: Text('Month')),
          DsSegment(value: 'year', label: Text('Year')),
        ],
      );
  // #endregion
}

class _ViewDemo extends StatefulWidget {
  const _ViewDemo();

  @override
  State<_ViewDemo> createState() => _ViewDemoState();
}

class _ViewDemoState extends State<_ViewDemo> {
  String _view = 'grid';
  String _layout = 'list';

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 24,
    runSpacing: 16,
    alignment: WrapAlignment.center,
    children: [
      // #region segmented-icons
      DsSegmentedControl<String>(
        value: _view,
        onChanged: (v) => setState(() => _view = v),
        semanticLabel: 'View',
        segments: const [
          DsSegment(
            value: 'grid',
            icon: DsIcon(DsIcons.layoutGrid),
            semanticLabel: 'Grid',
          ),
          DsSegment(
            value: 'list',
            icon: DsIcon(DsIcons.list),
            semanticLabel: 'List',
          ),
          DsSegment(
            value: 'calendar',
            icon: DsIcon(DsIcons.calendar),
            semanticLabel: 'Calendar',
          ),
        ],
      ),
      DsSegmentedControl<String>(
        value: _layout,
        onChanged: (v) => setState(() => _layout = v),
        semanticLabel: 'Layout',
        segments: const [
          DsSegment(
            value: 'grid',
            icon: DsIcon(DsIcons.layoutGrid),
            label: Text('Grid'),
          ),
          DsSegment(
            value: 'list',
            icon: DsIcon(DsIcons.list),
            label: Text('List'),
          ),
        ],
      ),
      // #endregion
    ],
  );
}

class _UnitDemo extends StatefulWidget {
  const _UnitDemo();

  @override
  State<_UnitDemo> createState() => _UnitDemoState();
}

class _UnitDemoState extends State<_UnitDemo> {
  String _unit = 'c';
  String _plan = 'monthly';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: [
      // #region segmented-width
      DsSegmentedControl<String>(
        value: _unit,
        onChanged: (v) => setState(() => _unit = v),
        semanticLabel: 'Temperature unit',
        segments: const [
          DsSegment(value: 'c', label: Text('°C')),
          DsSegment(value: 'f', label: Text('°F')),
        ],
      ),
      SizedBox(
        width: 240,
        child: DsSegmentedControl<String>(
          value: _plan,
          onChanged: (v) => setState(() => _plan = v),
          semanticLabel: 'Billing period',
          segments: const [
            DsSegment(value: 'monthly', label: Text('Monthly')),
            DsSegment(value: 'yearly', label: Text('Yearly, save 20%')),
            DsSegment(value: 'lifetime', label: Text('Lifetime')),
          ],
        ),
      ),
      // #endregion
    ],
  );
}

class _DisabledDemo extends StatefulWidget {
  const _DisabledDemo();

  @override
  State<_DisabledDemo> createState() => _DisabledDemoState();
}

class _DisabledDemoState extends State<_DisabledDemo> {
  String _format = 'pdf';

  @override
  Widget build(BuildContext context) =>
      // #region segmented-disabled
      DsSegmentedControl<String>(
        value: _format,
        onChanged: (v) => setState(() => _format = v),
        semanticLabel: 'Export format',
        segments: const [
          DsSegment(value: 'pdf', label: Text('PDF')),
          DsSegment(value: 'csv', label: Text('CSV')),
          DsSegment(value: 'xlsx', label: Text('Excel'), enabled: false),
        ],
      );
  // #endregion
}

class _CustomDemo extends StatefulWidget {
  const _CustomDemo();

  @override
  State<_CustomDemo> createState() => _CustomDemoState();
}

class _CustomDemoState extends State<_CustomDemo> {
  String _layout = 'board';

  @override
  Widget build(BuildContext context) =>
      // #region segmented-custom
      DsSegmentedControl<String>(
        value: _layout,
        onChanged: (v) => setState(() => _layout = v),
        semanticLabel: 'Layout',
        style: DsSegmentedControlStyle(
          height: 36,
          borderRadius: BorderRadius.circular(999),
          thumbRadius: BorderRadius.circular(999),
          itemPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        ),
        segments: const [
          DsSegment(value: 'board', label: Text('Board')),
          DsSegment(value: 'table', label: Text('Table')),
          DsSegment(value: 'timeline', label: Text('Timeline')),
        ],
      );
  // #endregion
}
