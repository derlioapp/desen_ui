import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class SliderPage extends StatelessWidget {
  const SliderPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Selection controls',
    title: 'Slider',
    lead:
        'Picks a value on a track by dragging, when the rough position '
        'matters more than the exact number: volume, zoom, density. When '
        'people need an exact number, use a '
        '[Number field](/components/number-field) or a '
        '[Stepper](/components/stepper). For a range with two thumbs, use '
        'the [Range slider](/components/range-slider).',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          DocText(
            'The slider fills the width it gets and has one thumb. It shows '
            'no number of its own; put the value in a label next to it, as '
            'here.',
          ),
          Example(snippet: 'slider-overview', child: _VolumeDemo()),
        ],
      ),
      const DocSection(
        title: 'Steps and ticks',
        children: [
          DocText(
            '`divisions` splits the range into equal steps: the thumb snaps '
            'to them, and a tick marks each one. Name the steps for screen '
            'readers with `semanticFormatter`; by default they hear a '
            'percentage.',
          ),
          Example(snippet: 'slider-steps', child: _DensityDemo()),
        ],
      ),
      const DocSection(
        title: 'Value label',
        children: [
          DocText(
            'Format the label the way the value reads in your product. Use '
            'the same text for `semanticFormatter`, so screen readers hear '
            'what is on screen.',
          ),
          Example(snippet: 'slider-label', child: _BudgetDemo()),
        ],
      ),
      const DocSection(
        title: 'Saving when the drag ends',
        children: [
          DocText(
            '`onChanged` fires on every move. When a change is costly, such '
            'as a request to a server, save in `onChangeEnd`: it fires once '
            'per tap or drag, with the value the gesture produced. '
            '`onChangeStart` pairs with it.',
          ),
          Example(snippet: 'slider-change-end', child: _ChangeEndDemo()),
        ],
      ),
      DocSection(
        title: 'Disabled',
        children: [
          const DocText('A null `onChanged` disables the slider.'),
          Example(
            snippet: 'slider-disabled',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region slider-disabled
              child: const DsSlider(
                value: 0.4,
                onChanged: null,
                semanticLabel: 'Brightness',
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
            'Change one slider with `style`, or every slider in a subtree '
            'with `DsSliderTheme`. `trackHeight`, `thumbSize` and '
            '`fillColor` cover most changes; `width` is used only under an '
            'unbounded width, such as in a `Row`.',
          ),
          Example(
            snippet: 'slider-custom',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region slider-custom
              child: DsSlider(
                value: 0.7,
                onChanged: (v) {},
                semanticLabel: 'Progress',
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
          KeyboardTable([
            ('Tab', 'Moves focus to the slider.'),
            (
              'Right / Up',
              'Increases by one step (a hundredth of the range without '
                  '`divisions`). In right-to-left layouts, Left increases.',
            ),
            (
              'Left / Down',
              'Decreases by one step. In right-to-left layouts, Right '
                  'decreases.',
            ),
            ('Page Up / Page Down', 'Moves by a tenth of the range.'),
            ('Home / End', 'Jumps to `min` or `max`.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a slider with its `semanticLabel` and value, with '
                'increase and decrease actions.',
            'The value is read as a percentage unless `semanticFormatter` '
                'says otherwise.',
            'The thumb is white with a soft shadow, like the switch knob, '
                'so it stays visible on light surfaces. Hovering it with '
                'a mouse rings it in the focus color. Ticks inside the fill '
                'take the track color, which stands 3:1 against the fill.',
            'The keyboard focus ring outlines the thumb.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('value', 'double', 'The current value, between `min` and `max`.'),
            (
              'onChanged',
              'ValueChanged<double>?',
              'Called while the value changes. Null disables the slider.',
            ),
            ('min / max', 'double', 'The range; defaults to 0 and 1.'),
            ('divisions', 'int?', 'Number of equal steps; null is continuous.'),
            (
              'onChangeStart / onChangeEnd',
              'ValueChanged<double>?',
              'Called once when a tap or drag starts and ends.',
            ),
            (
              'semanticLabel',
              'String?',
              'Names the slider for screen readers.',
            ),
            (
              'semanticFormatter',
              'String Function(double)?',
              'Turns a value into what screen readers say.',
            ),
            ('style', 'DsSliderStyle?', 'Laid over the theme and defaults.'),
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

class _VolumeDemo extends StatefulWidget {
  const _VolumeDemo();

  @override
  State<_VolumeDemo> createState() => _VolumeDemoState();
}

class _VolumeDemoState extends State<_VolumeDemo> {
  double _volume = 62;

  @override
  Widget build(BuildContext context) {
    final k = DsTheme.colorsOf(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _LabelRow('Volume', '${_volume.round()}'),
          Row(
            spacing: 12,
            children: [
              DsIcon(DsIcons.volumeLow, color: k.textMuted),
              Expanded(
                // #region slider-overview
                child: DsSlider(
                  value: _volume,
                  min: 0,
                  max: 100,
                  semanticLabel: 'Volume',
                  onChanged: (v) => setState(() => _volume = v),
                ),
                // #endregion
              ),
              DsIcon(DsIcons.volumeHigh, color: k.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _DensityDemo extends StatefulWidget {
  const _DensityDemo();

  @override
  State<_DensityDemo> createState() => _DensityDemoState();
}

class _DensityDemoState extends State<_DensityDemo> {
  static const _names = ['Tight', 'Compact', 'Default', 'Relaxed', 'Spacious'];
  double _density = 2;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _LabelRow('Row density', _names[_density.round()]),
        // #region slider-steps
        DsSlider(
          value: _density,
          min: 0,
          max: 4,
          divisions: 4,
          semanticLabel: 'Row density',
          semanticFormatter: (v) => _names[v.round()],
          onChanged: (v) => setState(() => _density = v),
        ),
        // #endregion
      ],
    ),
  );
}

class _BudgetDemo extends StatefulWidget {
  const _BudgetDemo();

  @override
  State<_BudgetDemo> createState() => _BudgetDemoState();
}

class _BudgetDemoState extends State<_BudgetDemo> {
  double _limit = 400;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _LabelRow('Monthly spend limit', '\$${_limit.round()}'),
        // #region slider-label
        DsSlider(
          value: _limit,
          min: 100,
          max: 1000,
          divisions: 18,
          semanticLabel: 'Monthly spend limit',
          semanticFormatter: (v) => '\$${v.round()}',
          onChanged: (v) => setState(() => _limit = v),
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
  double _zoom = 100, _saved = 100;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _LabelRow('Default zoom', '${_zoom.round()}%'),
          // #region slider-change-end
          DsSlider(
            value: _zoom,
            min: 50,
            max: 200,
            divisions: 30,
            semanticLabel: 'Default zoom',
            semanticFormatter: (v) => '${v.round()}%',
            onChanged: (v) => setState(() => _zoom = v),
            onChangeEnd: (v) => setState(() => _saved = v),
          ),
          // #endregion
          Text(
            'Saved: ${_saved.round()}%',
            style: t.typography
                .numeric(t.typography.small)
                .copyWith(color: t.colors.textSubtle),
          ),
        ],
      ),
    );
  }
}
