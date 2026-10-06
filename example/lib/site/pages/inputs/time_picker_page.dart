import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// The time picker page: a time field with hour and minute columns.
class TimePickerPage extends StatefulWidget {
  const TimePickerPage({super.key});

  @override
  State<TimePickerPage> createState() => _TimePickerPageState();
}

class _TimePickerPageState extends State<TimePickerPage> {
  DsTime? _start = const DsTime(14, 30);
  DsTime? _end = const DsTime(15, 30);
  DsTime? _reminder = const DsTime(9, 0);
  DsTime? _departure = const DsTime(18, 45);
  DsTime? _slot = const DsTime(10, 0);
  DsTime? _alarm;
  DsTime? _standup = const DsTime(9, 15);

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Inputs',
    title: 'Time picker',
    lead:
        'A time field with a popup of hour and minute columns. People can '
        'type the time or pick it. Pair it with a '
        '[Date picker](/components/date-picker) for a date and time.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'time-picker-overview',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                // #region time-picker-overview
                SizedBox(
                  width: 160,
                  child: DsField(
                    label: const Text('Starts'),
                    child: DsTimePicker(
                      value: _start,
                      minuteStep: 15,
                      onChanged: (t) => setState(() => _start = t),
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DsField(
                    label: const Text('Ends'),
                    errorText:
                        _start != null &&
                            _end != null &&
                            _end!.compareTo(_start!) <= 0
                        ? 'Must be after the start.'
                        : null,
                    child: DsTimePicker(
                      value: _end,
                      minuteStep: 15,
                      onChanged: (t) => setState(() => _end = t),
                    ),
                  ),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: '12 or 24 hours',
        children: [
          const DocText(
            'The clock follows the region of the language: 12-hour '
            '(`2:30 PM`) in the US, Canada, Australia, India, Korea and '
            'Egypt; 24-hour (`14:30`) in Turkey, Europe, Japan, China and '
            'Brazil. A 12-hour clock adds an AM/PM column. The examples here '
            'follow the **Example language** in the settings: English reads '
            'as US English, so they start on a 12-hour clock; switch to '
            'Deutsch or Türkçe for 24 hours.',
          ),
          const DocText(
            'Set `use24HourClock` to force one clock, for example in a '
            'timetable where everyone reads 24 hours.',
          ),
          Example(
            snippet: 'time-picker-clock',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                // #region time-picker-clock
                SizedBox(
                  width: 160,
                  child: DsField(
                    label: const Text('Reminder'),
                    child: DsTimePicker(
                      value: _reminder,
                      onChanged: (t) => setState(() => _reminder = t),
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DsField(
                    label: const Text('Departure'),
                    child: DsTimePicker(
                      value: _departure,
                      use24HourClock: true,
                      onChanged: (t) => setState(() => _departure = t),
                    ),
                  ),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Minute step',
        children: [
          const DocText(
            '`minuteStep` sets the minutes the column lists: 5 by default, '
            'up to 30. A typed minute off the steps is still accepted and '
            'listed too. Choose the step the value needs: 15 or 30 for '
            'meetings, 5 for reminders.',
          ),
          Example(
            snippet: 'time-picker-step',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              // #region time-picker-step
              child: DsField(
                label: const Text('Booking slot'),
                child: DsTimePicker(
                  value: _slot,
                  minuteStep: 30,
                  onChanged: (t) => setState(() => _slot = t),
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Typing',
        children: [
          const DocText(
            'Typing is lenient: `14:30`, `14.30`, `1430`, `2:30 pm` and '
            '`2p` all work. `onChanged` follows the typing once the minutes '
            'are typed. On Enter or when focus leaves, the text is shown in '
            'the clock\'s pattern again. Text that is not a time keeps the '
            'error look and a null value; inside a `DsField` the field '
            'shows a message such as "Enter a time such as 2:30 PM." '
            '`onInputIssueChanged` gives the same message to your code.',
          ),
          Example(
            snippet: 'time-picker-typing',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              // #region time-picker-typing
              child: DsField(
                label: const Text('Alarm'),
                description: const Text('Try 7a or 1930.'),
                child: DsTimePicker(
                  value: _alarm,
                  onChanged: (t) => setState(() => _alarm = t),
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Read-only and disabled',
        children: [
          const DocText(
            '`readOnly` keeps the time focusable and selectable but fixed, '
            'in the text field\'s read-only look, without the clock button. '
            'A null `onChanged` disables the field.',
          ),
          Example(
            snippet: 'time-picker-states',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                // #region time-picker-states
                SizedBox(
                  width: 160,
                  child: DsField(
                    label: const Text('Check-in'),
                    child: DsTimePicker(
                      value: const DsTime(15, 0),
                      onChanged: (t) {},
                      readOnly: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DsField(
                    label: const Text('Check-out'),
                    child: DsTimePicker(
                      value: const DsTime(11, 0),
                      onChanged: null,
                    ),
                  ),
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
            'Change one picker with `style`, a part of the app with '
            '`DsTimePickerTheme`, or the whole app through '
            '`DsComponentThemes`. `fieldStyle` styles the text field; '
            '`columnWidth`, `visibleItems` and `itemHeight` size the '
            'columns; the item colors nest under `hovered`, `pressed` and '
            '`selected`.',
          ),
          Example(
            snippet: 'time-picker-custom',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              // #region time-picker-custom
              child: DsTimePicker(
                value: _standup,
                onChanged: (t) => setState(() => _standup = t),
                semanticLabel: 'Stand-up',
                style: DsTimePickerStyle(
                  fieldStyle: DsTextFieldStyle(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  visibleItems: 4,
                  itemRadius: BorderRadius.circular(999),
                  selected: const DsTimePickerStyle(
                    itemBackground: Color(0xFF0B6E4F),
                    itemForeground: Color(0xFFFFFFFF),
                  ),
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
          DocHeading('Field'),
          KeyboardTable([
            ('Tab', 'Moves to the text, then to the clock button.'),
            ('Alt+Down', 'Opens the columns from the text.'),
            ('Enter / Space', 'On the clock button: opens the columns.'),
            ('Enter', 'Shows the typed time in the clock\'s pattern.'),
          ]),
          DocHeading('Columns'),
          DocText(
            'The columns open with the hour column focused. Moving in a '
            'column changes the time at once.',
          ),
          KeyboardTable([
            ('Up / Down', 'Previous or next item in the column.'),
            ('Home / End', 'First or last item.'),
            (
              'Left / Right',
              'Previous or next column (mirrored right to left).',
            ),
            ('Enter', 'Closes the columns, keeping the time.'),
            (
              'Escape',
              'Closes the columns, restoring the time they opened with.',
            ),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The field is named by the `DsField` label or `semanticLabel`; '
                'the clock button is its own node, "Choose time".',
            'Each column is one adjustable node, such as "Hours, 14"; '
                'screen reader users swipe up or down to change it.',
            'The column digits are tabular, so they line up as they change.',
            'Invalid text is announced as an invalid state, and inside a '
                '`DsField` the reason is shown as text.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('value', 'DsTime?', 'The chosen time, or null.'),
            (
              'onChanged',
              'ValueChanged<DsTime?>?',
              'Called with the new time, or null for an empty or invalid '
                  'field. Null disables the picker.',
            ),
            (
              'onInputIssueChanged',
              'ValueChanged<DsInputIssue?>?',
              'Why the text holds no time, with a localized message.',
            ),
            (
              'minuteStep',
              'int',
              'Minutes between items of the minute column. 5 by default, '
                  '1 to 30.',
            ),
            (
              'use24HourClock',
              'bool?',
              'Forces a 24-hour (true) or 12-hour (false) clock; null '
                  'follows the region.',
            ),
            ('placeholder', 'String?', 'Shown while the field is empty.'),
            ('readOnly', 'bool', 'Fixed value; no clock button.'),
            (
              'error',
              'bool',
              'The error look; a `DsField` with an error sets it too.',
            ),
            (
              'style',
              'DsTimePickerStyle?',
              'Laid over the theme and defaults.',
            ),
          ]),
          DocHeading('DsTime'),
          DocText(
            'A time of day without a date: `DsTime(14, 30)`, with `hour` '
            '(0 to 23) and `minute`. It compares with `compareTo`.',
          ),
        ],
      ),
    ],
  );
}
