import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// The date picker page: a date field with a calendar, and its range
/// sibling.
class DatePickerPage extends StatefulWidget {
  const DatePickerPage({super.key});

  @override
  State<DatePickerPage> createState() => _DatePickerPageState();
}

class _DatePickerPageState extends State<DatePickerPage> {
  static DateTime _day(int fromToday) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + fromToday);
  }

  DateTime? _due = _day(9);
  DateTime? _invoiceDate;
  DateTime? _delivery;
  DsDateRange? _period = DsDateRange(start: _day(7), end: _day(13));
  DateTime? _launch = _day(30);

  @override
  Widget build(BuildContext context) {
    final today = _day(0);
    return DocPage(
      eyebrow: 'Inputs',
      title: 'Date picker',
      lead:
          'A date field with a calendar popup. People can type the date or '
          'pick it. `DsDatePicker` takes one day; `DsDateRangePicker` takes '
          'a start and an end. For a time of day, use the '
          '[Time picker](/components/time-picker).',
      sections: [
        DocSection(
          title: 'Overview',
          children: [
            Example(
              snippet: 'date-picker-overview',
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                // #region date-picker-overview
                child: DsField(
                  label: const Text('Due date'),
                  description: const Text('Type it or pick it.'),
                  child: DsDatePicker(
                    value: _due,
                    firstDate: today,
                    onChanged: (d) => setState(() => _due = d),
                  ),
                ),
                // #endregion
              ),
            ),
          ],
        ),
        DocSection(
          title: 'Typing a date',
          children: [
            const DocText(
              'The field shows the date in the numeric order of the '
              'language: `10/5/2026` in US English, `05.10.2026` in Turkish, '
              '`5.10.2026` in German, `2026/10/5` in Japanese. The placeholder shows '
              'that order (`MM/DD/YYYY`). The examples on this site follow '
              'the **Example language** in the settings; change it to see '
              'the formats, month names and first weekday change.',
            ),
            const DocList([
              'Any separator works: `10/5/2026`, `10-5-2026` and `10 5 2026` '
                  'read the same.',
              'Days and months may have one or two digits, and a month may '
                  'be typed as its name or short name (`Oct 5 2026`).',
              'A two-digit year is read in this century (`26` is 2026). '
                  'Without a year, the current year is used.',
              '`onChanged` follows the typing once the text holds a whole '
                  'date with a four-digit year. On Enter or when focus '
                  'leaves, the text is shown in the language\'s order again.',
              'Text that is not a date keeps the error look and reports a '
                  'null value. Inside a `DsField` the field shows why, such '
                  'as "Enter a date as MM/DD/YYYY." `onInputIssueChanged` '
                  'gives the same message to your code.',
            ]),
            Example(
              snippet: 'date-picker-typing',
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                // #region date-picker-typing
                child: DsField(
                  label: const Text('Invoice date'),
                  child: DsDatePicker(
                    value: _invoiceDate,
                    onChanged: (d) => setState(() => _invoiceDate = d),
                  ),
                ),
                // #endregion
              ),
            ),
          ],
        ),
        DocSection(
          title: 'Limits and unavailable days',
          children: [
            const DocText(
              '`firstDate` and `lastDate` bound the days that can be chosen '
              'or typed; `selectableDayPredicate` turns off single days, '
              'such as weekends. In the calendar those days are struck '
              'through and cannot be chosen, but the arrow keys still move '
              'over them. Typed, they show a message such as "Enter a date '
              'on or after …" or "This date can\'t be chosen."',
            ),
            Example(
              snippet: 'date-picker-limits',
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                // #region date-picker-limits
                child: DsField(
                  label: const Text('Delivery date'),
                  description: const Text(
                    'Weekdays only, within the next 60 days.',
                  ),
                  child: DsDatePicker(
                    value: _delivery,
                    firstDate: today.add(const Duration(days: 1)),
                    lastDate: today.add(const Duration(days: 60)),
                    selectableDayPredicate: (day) =>
                        day.weekday != DateTime.saturday &&
                        day.weekday != DateTime.sunday,
                    onChanged: (d) => setState(() => _delivery = d),
                  ),
                ),
                // #endregion
              ),
            ),
          ],
        ),
        DocSection(
          title: 'Date range',
          children: [
            const DocText(
              '`DsDateRangePicker` shows `10/12/2026 – 10/18/2026`. In the '
              'calendar the first click sets the start and the second the '
              'end, with the range previewed under the pointer or the '
              'keyboard focus; the popup closes once the end is chosen. In a '
              'window at least 640px wide the popup shows two months side '
              'by side where they fit, otherwise one; set `months` to fix '
              'it. The two months line up row for row. `onChanged` reports '
              'only whole ranges, or null.',
            ),
            Example(
              snippet: 'date-picker-range',
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                // #region date-picker-range
                child: DsField(
                  label: const Text('Report period'),
                  child: DsDateRangePicker(
                    value: _period,
                    lastDate: today.add(const Duration(days: 365)),
                    onChanged: (r) => setState(() => _period = r),
                  ),
                ),
                // #endregion
              ),
            ),
            const DocText(
              'Typed, a range is two dates with a dash between them, with or '
              'without spaces, or with only a space.',
            ),
          ],
        ),
        DocSection(
          title: 'Read-only and disabled',
          children: [
            const DocText(
              '`readOnly` keeps the date focusable and selectable but fixed, '
              'and hides the calendar button. A null `onChanged` disables '
              'the field. Inside a `DsField` with an `errorText`, or with '
              '`error`, it takes the error look.',
            ),
            Example(
              snippet: 'date-picker-states',
              child: Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  // #region date-picker-states
                  SizedBox(
                    width: 240,
                    child: DsField(
                      label: const Text('Contract start'),
                      child: DsDatePicker(
                        value: DateTime(2026, 3, 1),
                        onChanged: (d) {},
                        readOnly: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: DsField(
                      label: const Text('Renewal date'),
                      child: DsDatePicker(
                        value: DateTime(2027, 3, 1),
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
              '`DsDatePickerTheme`, or the whole app through '
              '`DsComponentThemes`. Both pickers take `DsDatePickerStyle`: '
              '`fieldStyle` for the text field, `buttonStyle` for the '
              'calendar button, `panelStyle` for the popup, `calendarStyle` '
              'for the days, and `wideBreakpoint` for when the range shows '
              'two months.',
            ),
            Example(
              snippet: 'date-picker-custom',
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                // #region date-picker-custom
                child: DsDatePicker(
                  value: _launch,
                  onChanged: (d) => setState(() => _launch = d),
                  semanticLabel: 'Launch date',
                  style: DsDatePickerStyle(
                    buttonStyle: const DsButtonStyle(
                      foreground: Color(0xFF0B6E4F),
                    ),
                    calendarStyle: DsCalendarStyle(
                      dayRadius: BorderRadius.circular(6),
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
              ('Tab', 'Moves to the text, then to the calendar button.'),
              ('Alt+Down', 'Opens the calendar from the text.'),
              ('Enter / Space', 'On the calendar button: opens the calendar.'),
              ('Enter', 'Shows the typed date in the language\'s order.'),
            ]),
            DocHeading('Calendar'),
            DocText(
              'Focus moves to the chosen day, else today. The days are one '
              'Tab stop; left and right are mirrored in right-to-left text.',
            ),
            KeyboardTable([
              ('Left / Right', 'Previous or next day.'),
              ('Up / Down', 'Same day of the previous or next week.'),
              ('Home / End', 'First or last day of the week.'),
              (
                'Page Up / Page Down',
                'Same day of the previous or next month.',
              ),
              (
                'Shift+Page Up / Shift+Page Down',
                'Same day of the previous or next year.',
              ),
              ('Enter / Space', 'Chooses the focused day.'),
              (
                'Escape',
                'Closes the calendar without a change; focus returns.',
              ),
            ]),
          ],
        ),
        const DocSection(
          title: 'Accessibility',
          children: [
            DocList([
              'The field is named by the `DsField` label or `semanticLabel`; '
                  'the calendar button is its own node, "Choose date", and '
                  'reads as expanded while the calendar is open.',
              'Each day is a button named by its full date in the language, '
                  'with today, range ends and days in a range said after '
                  'it. The chosen day is selected.',
              'The month title is a live region, so turning the page is '
                  'announced.',
              'Today has a ring as well as its color, and unavailable days '
                  'are struck through, so neither is told by color alone.',
              'Invalid text is announced as an invalid state, and inside a '
                  '`DsField` the reason is shown as text.',
              'On a short or narrow window the calendar narrows its columns '
                  'and scrolls inside the popup, following the keyboard.',
            ]),
          ],
        ),
        const DocSection(
          title: 'API',
          children: [
            ApiTable([
              (
                'value',
                'DateTime? / DsDateRange?',
                'The chosen day, or range, or null.',
              ),
              (
                'onChanged',
                'ValueChanged<DateTime?>?',
                'Called with the new day, or null for an empty or invalid '
                    'field. Null disables the picker. The range picker takes '
                    '`ValueChanged<DsDateRange?>?`.',
              ),
              (
                'onInputIssueChanged',
                'ValueChanged<DsInputIssue?>?',
                'Why the text holds no date, with a localized message; null '
                    'once fixed.',
              ),
              (
                'firstDate / lastDate',
                'DateTime?',
                'The days that can be chosen.',
              ),
              (
                'selectableDayPredicate',
                'bool Function(DateTime)?',
                'Days for which it returns false cannot be chosen.',
              ),
              (
                'currentDate',
                'DateTime?',
                'Today, for the calendar; defaults to now.',
              ),
              (
                'months',
                'int?',
                'Range picker only: months in the popup; null picks one or '
                    'two by width.',
              ),
              (
                'placeholder',
                'String?',
                'Defaults to the pattern to type, such as `MM/DD/YYYY`.',
              ),
              ('readOnly', 'bool', 'Fixed value; no calendar button.'),
              (
                'error',
                'bool',
                'The error look; a `DsField` with an error sets it too.',
              ),
              (
                'style',
                'DsDatePickerStyle?',
                'Laid over the theme and defaults.',
              ),
            ]),
          ],
        ),
      ],
    );
  }
}
