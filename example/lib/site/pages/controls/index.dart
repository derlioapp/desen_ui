import '../../registry.dart';
import 'checkbox_page.dart';
import 'chip_page.dart';
import 'radio_page.dart';
import 'segmented_control_page.dart';
import 'slider_page.dart';
import 'stepper_page.dart';
import 'switch_page.dart';

/// The "Selection controls" pages, in sidebar order.
final controlPages = <SitePage>[
  SitePage(
    path: '/components/checkbox',
    title: 'Checkbox',
    builder: (_) => const CheckboxPage(),
    keywords: ['DsCheckbox', 'tristate', 'indeterminate', 'select all'],
    summary: 'Turns an option on or off; any number can be checked.',
  ),
  SitePage(
    path: '/components/radio',
    title: 'Radio',
    builder: (_) => const RadioPage(),
    keywords: [
      'DsRadio',
      'DsRadioGroup',
      'DsRadioCard',
      'radio button',
      'option',
      'plan',
      'card',
    ],
    summary: 'Picks exactly one option from a short list.',
  ),
  SitePage(
    path: '/components/switch',
    title: 'Switch',
    builder: (_) => const SwitchPage(),
    keywords: ['DsSwitch', 'toggle', 'settings'],
    summary: 'Turns a setting on or off right away.',
  ),
  SitePage(
    path: '/components/slider',
    title: 'Slider',
    builder: (_) => const SliderPage(),
    keywords: ['DsSlider', 'range', 'volume', 'track'],
    summary: 'Picks a value by dragging along a track.',
  ),
  SitePage(
    path: '/components/segmented-control',
    title: 'Segmented control',
    builder: (_) => const SegmentedControlPage(),
    keywords: ['DsSegmentedControl', 'DsSegment', 'toggle group'],
    summary: 'Picks one of a few options that change a view.',
  ),
  SitePage(
    path: '/components/chip',
    title: 'Chip',
    builder: (_) => const ChipPage(),
    keywords: ['DsChip', 'DsChoiceChips', 'filter', 'tag', 'pill', 'choice'],
    summary: 'A compact toggle for filters.',
  ),
  SitePage(
    path: '/components/stepper',
    title: 'Stepper',
    builder: (_) => const StepperPage(),
    keywords: ['DsStepper', 'counter', 'quantity', 'plus minus'],
    summary: 'Changes a small number one step at a time.',
  ),
];
