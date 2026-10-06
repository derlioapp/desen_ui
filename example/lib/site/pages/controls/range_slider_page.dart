import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class RangeSliderPage extends StatelessWidget {
  const RangeSliderPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Selection controls',
    title: 'Range slider',
    lead:
        'Picks a range with two thumbs on one track, for filters such as a '
        'price or a time window. It looks and steps like the '
        '[Slider](/components/slider) and shares its style and theme.',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          DocText(
            'The fill lies between the thumbs. Drag a thumb, or press the '
            'track to move the nearer one there. The thumbs never cross: a '
            'thumb dragged into the other stops at it. When both sit on the '
            'same spot, the direction of the drag picks the thumb.',
          ),
          Example(snippet: 'range-slider-overview', child: _PriceDemo()),
        ],
      ),
      const DocSection(
        title: 'Steps and a minimum gap',
        children: [
          DocText(
            '`divisions` splits the range into equal steps, with a tick for '
            'each, as on the slider. `minDistance` keeps the thumbs apart by '
            'at least that much; on a stepped slider a thumb stops at the '
            'last step that keeps the gap.',
          ),
          Example(snippet: 'range-slider-steps', child: _HoursDemo()),
        ],
      ),
      const DocSection(
        title: 'Saving when the drag ends',
        children: [
          DocText(
            '`onChanged` fires on every move with both values. To filter a '
            'list from a server, query in `onChangeEnd`: it fires once per '
            'tap or drag, with the values the gesture produced.',
          ),
          Example(snippet: 'range-slider-change-end', child: _ChangeEndDemo()),
        ],
      ),
      DocSection(
        title: 'Disabled',
        children: [
          const DocText('A null `onChanged` disables the slider.'),
          Example(
            snippet: 'range-slider-disabled',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region range-slider-disabled
              child: const DsRangeSlider(
                values: DsRangeValues(start: 0.2, end: 0.6),
                onChanged: null,
                semanticLabel: 'Quiet hours',
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'It takes a `DsSliderStyle`, and `DsSliderTheme` styles sliders '
            'and range sliders alike. Each thumb resolves the style for its '
            'own states, so `hovered` and `pressed` styles reach only the '
            'thumb under the pointer.',
          ),
          Example(
            snippet: 'range-slider-custom',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region range-slider-custom
              child: DsRangeSlider(
                values: const DsRangeValues(start: 0.3, end: 0.8),
                onChanged: (v) {},
                semanticLabel: 'Range',
                style: const DsSliderStyle(
                  trackHeight: 4,
                  thumbSize: 16,
                  fillColor: Color(0xFF0B6E4F),
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          DocText(
            'Each thumb is its own focus stop, the start thumb first, as in '
            'the WAI-ARIA multi-thumb slider pattern.',
          ),
          KeyboardTable([
            ('Tab', 'Moves focus to the start thumb, then the end thumb.'),
            (
              'Right / Up',
              'Increases the focused thumb by one step (a hundredth of the '
                  'range without `divisions`). In right-to-left layouts, Left '
                  'increases.',
            ),
            (
              'Left / Down',
              'Decreases by one step. In right-to-left layouts, Right '
                  'decreases.',
            ),
            ('Page Up / Page Down', 'Moves by a tenth of the range.'),
            (
              'Home / End',
              'Moves the thumb as far as it can go: to `min` or `max`, or '
                  'up to the other thumb (less `minDistance`).',
            ),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Each thumb is announced as its own slider, named by '
                '`semanticLabel` and its end: "Price, Minimum" and "Price, '
                'Maximum", in the app\'s language.',
            'Values are read as a percentage unless `semanticFormatter` '
                'says otherwise. Increase and decrease stop at the other '
                'thumb.',
            'Hovering with a mouse rings the thumb a press would move; the '
                'keyboard focus ring outlines the focused thumb only.',
            'On touch screens the track sits in a 44px band, so both thumbs '
                'are easy to grab while they look the same size.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'values',
              'DsRangeValues',
              'The current range: `start` and `end`, between `min` and `max`.',
            ),
            (
              'onChanged',
              'ValueChanged<DsRangeValues>?',
              'Called while either value changes. Null disables the slider.',
            ),
            ('min / max', 'double', 'The range; defaults to 0 and 1.'),
            ('divisions', 'int?', 'Number of equal steps; null is continuous.'),
            (
              'minDistance',
              'double',
              'The smallest gap between the thumbs; defaults to 0.',
            ),
            (
              'onChangeStart / onChangeEnd',
              'ValueChanged<DsRangeValues>?',
              'Called once when a tap or drag starts and ends.',
            ),
            (
              'semanticLabel',
              'String?',
              'Names the slider for screen readers, before each thumb\'s '
                  'end.',
            ),
            (
              'semanticFormatter',
              'String Function(double)?',
              'Turns a value into what screen readers say.',
            ),
            ('style', 'DsSliderStyle?', 'Laid over the theme and defaults.'),
            (
              'startFocusNode / endFocusNode',
              'FocusNode?',
              'Focus nodes of the thumbs; created when null.',
            ),
          ]),
        ],
      ),
    ],
  );
}

/// A label row above a slider: the name and the value.
class _LabelRow extends StatelessWidget {
  const _LabelRow(this.name, this.value);

  final String name, value;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: t.typography.bodyStrong.copyWith(color: t.colors.text),
          ),
        ),
        Text(
          value,
          style: t.typography
              .numeric(t.typography.body)
              .copyWith(color: t.colors.textMuted),
        ),
      ],
    );
  }
}

class _PriceDemo extends StatefulWidget {
  const _PriceDemo();

  @override
  State<_PriceDemo> createState() => _PriceDemoState();
}

class _PriceDemoState extends State<_PriceDemo> {
  DsRangeValues _price = const DsRangeValues(start: 80, end: 320);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _LabelRow(
          'Price',
          '\$${_price.start.round()} – \$${_price.end.round()}',
        ),
        // #region range-slider-overview
        DsRangeSlider(
          values: _price,
          min: 0,
          max: 500,
          divisions: 50,
          semanticLabel: 'Price',
          semanticFormatter: (v) => '\$${v.round()}',
          onChanged: (v) => setState(() => _price = v),
        ),
        // #endregion
      ],
    ),
  );
}

class _HoursDemo extends StatefulWidget {
  const _HoursDemo();

  @override
  State<_HoursDemo> createState() => _HoursDemoState();
}

class _HoursDemoState extends State<_HoursDemo> {
  DsRangeValues _hours = const DsRangeValues(start: 9, end: 17);

  static String _time(double h) => '${h.round().toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _LabelRow(
          'Delivery window',
          '${_time(_hours.start)} – ${_time(_hours.end)}',
        ),
        // #region range-slider-steps
        DsRangeSlider(
          values: _hours,
          min: 6,
          max: 22,
          divisions: 16,
          // At least two hours apart.
          minDistance: 2,
          semanticLabel: 'Delivery window',
          semanticFormatter: _time,
          onChanged: (v) => setState(() => _hours = v),
        ),
        // #endregion
      ],
    ),
  );
}

class _ChangeEndDemo extends StatefulWidget {
  const _ChangeEndDemo();

  @override
  State<_ChangeEndDemo> createState() => _ChangeEndDemoState();
}

class _ChangeEndDemoState extends State<_ChangeEndDemo> {
  DsRangeValues _size = const DsRangeValues(start: 40, end: 90);
  DsRangeValues _queried = const DsRangeValues(start: 40, end: 90);

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    String text(DsRangeValues v) => '${v.start.round()}–${v.end.round()} m²';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _LabelRow('Floor area', text(_size)),
          // #region range-slider-change-end
          DsRangeSlider(
            values: _size,
            min: 20,
            max: 200,
            divisions: 36,
            semanticLabel: 'Floor area',
            semanticFormatter: (v) => '${v.round()} m²',
            onChanged: (v) => setState(() => _size = v),
            onChangeEnd: (v) => setState(() => _queried = v),
          ),
          // #endregion
          Text(
            'Searched: ${text(_queried)}',
            style: t.typography
                .numeric(t.typography.small)
                .copyWith(color: t.colors.textSubtle),
          ),
        ],
      ),
    );
  }
}
