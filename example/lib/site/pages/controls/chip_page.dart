import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class ChipPage extends StatelessWidget {
  const ChipPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Selection controls',
    title: 'Chip',
    lead:
        'A compact toggle for filters: each chip turns one filter on or off, '
        'and several can be on at once. `DsChoiceChips` is the single-choice '
        'row of the same chips. For one choice that changes a view, use a '
        '[Segmented control](/components/segmented-control); for a status '
        'label that is not pressable, a [Badge](/components/badge).',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          DocText(
            'An unselected chip is transparent with a faint edge. A selected '
            'one takes the theme\'s selection style and a check before the '
            'label, so the state does not rest on a tint alone.',
          ),
          Example(snippet: 'chip-overview', child: _FilterDemo()),
        ],
      ),
      const DocSection(
        title: 'Icons',
        children: [
          DocText(
            '`leading` puts an icon before the label. While the chip is '
            'selected, the check takes the icon\'s place.',
          ),
          Example(snippet: 'chip-icons', child: _IconDemo()),
        ],
      ),
      const DocSection(
        title: 'Single choice',
        children: [
          DocText(
            '`DsChoiceChips` is a row of the same chips with exactly one '
            'selected, such as a list filter. It is one Tab stop with arrow '
            'keys inside, and screen readers hear a radio group. A row wider '
            'than its space scrolls sideways and fades the edge that hides '
            'chips. The selected chip is scrolled into view, clear of the '
            'fade, when the row appears and whenever the selection changes.',
          ),
          Example(snippet: 'chip-single', child: _SingleDemo()),
          DocText(
            'Use it for a filter that people change often, alongside the '
            'content. A [Segmented control](/components/segmented-control) '
            'suits two to five options that switch a view and always fit.',
          ),
        ],
      ),
      DocSection(
        title: 'Disabled',
        children: [
          const DocText(
            'A null `onChanged` disables the chip. It keeps its shape: an '
            'unselected chip its outline, a selected one its fill.',
          ),
          Example(
            snippet: 'chip-disabled',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                // #region chip-disabled
                const DsChip(
                  label: Text('Archived'),
                  selected: false,
                  onChanged: null,
                ),
                const DsChip(
                  label: Text('My tasks'),
                  selected: true,
                  onChanged: null,
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one chip with `style`, or every chip in a subtree with '
            '`DsChipTheme`. `showCheck: false` drops the check mark; do that '
            'only when the selected fill alone is clear enough, as with a '
            'strong brand color.',
          ),
          Example(
            snippet: 'chip-custom',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                // #region chip-custom
                DsChip(
                  label: const Text('Rounded'),
                  selected: true,
                  onChanged: (on) {},
                  style: DsChipStyle(
                    height: 28,
                    borderRadius: BorderRadius.circular(999),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 12,
                    ),
                  ),
                ),
                DsChip(
                  label: const Text('Brand fill'),
                  selected: true,
                  onChanged: (on) {},
                  style: const DsChipStyle(
                    showCheck: false,
                    selected: DsChipStyle(
                      background: Color(0xFF0B6E4F),
                      foreground: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          DocHeading('DsChip'),
          KeyboardTable([
            ('Tab', 'Moves focus to the next chip; every chip is a Tab stop.'),
            ('Space / Enter', 'Toggles the chip.'),
          ]),
          DocHeading('DsChoiceChips'),
          KeyboardTable([
            (
              'Tab',
              'Moves focus into the row, to the selected chip (or the first '
                  'enabled one when none is selected), and out again.',
            ),
            (
              'Right / Down',
              'Selects the next enabled chip; from the last it wraps to the '
                  'first. In right-to-left layouts, Left selects the next.',
            ),
            (
              'Left / Up',
              'Selects the previous enabled chip; from the first it wraps to '
                  'the last. In right-to-left layouts, Right selects the '
                  'previous.',
            ),
            ('Home / End', 'Selects the first or last enabled chip.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'A chip turns on and off on its own: it is announced as a '
                'checkbox with its label, checked or not. In '
                '`DsChoiceChips` each chip is a radio, checked or not, in a '
                'radio group named by `semanticLabel`.',
            'A label that does not fit ellipsizes; screen readers still get '
                'all of it.',
            '`semanticLabel` replaces the label, e.g. for an abbreviation.',
            'The selected state shows as a fill and a check, not by hue '
                'alone.',
            'Tap area: 24px on desktop, 44px on iOS and Android.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsChip'),
          ApiTable([
            ('label', 'Widget', 'The text, usually a short `Text`.'),
            ('selected', 'bool', 'Whether the chip is on.'),
            (
              'onChanged',
              'ValueChanged<bool>?',
              'Called with the new selected value. Null disables the chip.',
            ),
            ('leading', 'Widget?', 'An icon before the label.'),
            ('style', 'DsChipStyle?', 'Laid over the theme and defaults.'),
            (
              'semanticLabel',
              'String?',
              'Replaces the label for screen readers.',
            ),
          ]),
          DocHeading('DsChoiceChips'),
          ApiTable([
            (
              'options',
              'List<DsChipOption<T>>',
              'The chips, in order: `value`, `label`, and optionally '
                  '`leading`, `enabled` and `semanticLabel`.',
            ),
            (
              'value',
              'T',
              'The selected value. One that matches no option selects none.',
            ),
            (
              'onChanged',
              'ValueChanged<T>?',
              'Called with the newly selected value. Null disables the row.',
            ),
            (
              'style',
              'DsChipStyle?',
              'Laid over the chip theme and defaults, for every chip.',
            ),
            ('semanticLabel', 'String?', 'Names the group for screen readers.'),
          ]),
        ],
      ),
    ],
  );
}

class _FilterDemo extends StatefulWidget {
  const _FilterDemo();

  @override
  State<_FilterDemo> createState() => _FilterDemoState();
}

class _FilterDemoState extends State<_FilterDemo> {
  final _labels = ['Design', 'Engineering', 'Marketing', 'Support', 'Sales'];
  final _on = {'Design', 'Engineering'};

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.center,
    children: [
      // #region chip-overview
      for (final label in _labels)
        DsChip(
          label: Text(label),
          selected: _on.contains(label),
          onChanged: (on) =>
              setState(() => on ? _on.add(label) : _on.remove(label)),
        ),
      // #endregion
    ],
  );
}

class _IconDemo extends StatefulWidget {
  const _IconDemo();

  @override
  State<_IconDemo> createState() => _IconDemoState();
}

class _IconDemoState extends State<_IconDemo> {
  bool _mine = true, _due = false, _unread = false;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.center,
    children: [
      // #region chip-icons
      DsChip(
        leading: const DsIcon(DsIcons.user),
        label: const Text('Assigned to me'),
        selected: _mine,
        onChanged: (on) => setState(() => _mine = on),
      ),
      DsChip(
        leading: const DsIcon(DsIcons.clock),
        label: const Text('Due this week'),
        selected: _due,
        onChanged: (on) => setState(() => _due = on),
      ),
      DsChip(
        leading: const DsIcon(DsIcons.mail),
        label: const Text('Unread'),
        selected: _unread,
        onChanged: (on) => setState(() => _unread = on),
      ),
      // #endregion
    ],
  );
}

class _SingleDemo extends StatefulWidget {
  const _SingleDemo();

  @override
  State<_SingleDemo> createState() => _SingleDemoState();
}

class _SingleDemoState extends State<_SingleDemo> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    // #region chip-single
    child: DsChoiceChips<String>(
      value: _filter,
      onChanged: (v) => setState(() => _filter = v),
      semanticLabel: 'Show',
      options: const [
        DsChipOption(value: 'all', label: Text('All')),
        DsChipOption(value: 'unread', label: Text('Unread')),
        DsChipOption(value: 'flagged', label: Text('Flagged')),
        DsChipOption(value: 'mentions', label: Text('Mentions')),
        DsChipOption(value: 'attachments', label: Text('With attachments')),
        DsChipOption(value: 'archived', label: Text('Archived')),
      ],
    ),
    // #endregion
  );
}
