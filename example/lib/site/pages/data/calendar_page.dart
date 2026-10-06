import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Today, without the time.
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Data display',
    title: 'Calendar',
    lead:
        'An inline month grid for choosing a day or a range of days. Use it '
        'where the calendar is the content, such as a booking page. In a '
        'form, a [Date picker](/components/date-picker) shows the same '
        'calendar in a popup under a typed field.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [Example(snippet: 'calendar-overview', child: _SingleDemo())],
      ),
      DocSection(
        title: 'Days',
        children: [
          DocText(
            'The chosen day is a solid accent fill. Today is bold in the '
            'accent text color inside a thin ring, so it is not told by '
            'color alone. Every month shows six weeks, so the calendar keeps '
            'its height as the page turns.',
          ),
          DocText(
            'Days before `firstDate`, after `lastDate` or refused by '
            '`selectableDayPredicate` are struck through and cannot be '
            'chosen. The page does not turn past `firstDate` or `lastDate`. '
            'Below, weekends are closed and booking opens today for 60 days.',
          ),
          Example(snippet: 'calendar-limits', child: _LimitsDemo()),
        ],
      ),
      DocSection(
        title: 'Range',
        children: [
          DocText(
            '`DsRangeCalendar` chooses a `DsDateRange`. The first click sets '
            'the start, the second the end; they swap if the end comes '
            'first, and the next click starts over. While only the start is '
            'set, the band previews the range up to the day under the '
            'pointer or the keyboard focus. `onChanged` reports the start '
            'alone, then the complete range.',
          ),
          DocText(
            '`months: 2` shows two months side by side. Their titles, '
            'weekday rows and grids line up exactly, with mouse or touch '
            'sizes; only the last month has the previous and next buttons. '
            'Where their days would get too narrow side by side, the months '
            'stack one under the other instead. This example shows two months '
            'when there is room for them.',
          ),
          Example(snippet: 'calendar-range', child: _RangeDemo()),
        ],
      ),
      DocSection(
        title: 'Week start and language',
        children: [
          DocText(
            'Month and weekday names come from the language. The first day '
            'of the week comes from the region: Sunday in the US and Japan, '
            'Monday in the UK, Turkey and most of Europe, Saturday in Egypt. '
            'Without a region, the language\'s usual one applies, so plain '
            'English starts on Sunday. Change the example language in the '
            'site settings to see others.',
          ),
          Example(snippet: 'calendar-locale', child: _LocaleDemo()),
        ],
      ),
      DocSection(
        title: 'Outside days',
        children: [
          DocText(
            'Days of the months before and after are hidden by default. '
            '`showOutsideDays` shows them muted; choosing one turns the '
            'page.',
          ),
          Example(snippet: 'calendar-outside', child: _OutsideDemo()),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Change one calendar with `style`, or every calendar and date '
            'picker below a point with `DsCalendarTheme`. Day states '
            'such as `selected` and `disabled` nest inside the style. Day '
            'size follows the theme density: 32px, or 38px for touch.',
          ),
          Example(snippet: 'calendar-custom', child: _CustomDemo()),
        ],
      ),
      DocSection(
        title: 'Keyboard',
        children: [
          DocText(
            'The days are one Tab stop, like a WAI-ARIA date grid. Focus '
            'lands on the chosen day, else today, else the first day that '
            'can be chosen. Moving past the shown months turns the page. '
            'Left and right swap in right-to-left text. The keyboard also '
            'moves over days that cannot be chosen.',
          ),
          KeyboardTable([
            ('← / →', 'Previous or next day.'),
            ('↑ / ↓', 'Same day of the previous or next week.'),
            ('Home / End', 'First or last day of the week.'),
            ('Page Up / Page Down', 'Same day of the previous or next month.'),
            (
              'Shift+Page Up / Shift+Page Down',
              'Same day of the previous or next year.',
            ),
            ('Enter / Space', 'Chooses the focused day.'),
          ]),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Each day is a button named by its full date in the language '
                '("Monday, October 5, 2026"); today, range ends and days in '
                'a range are said after it. The chosen day is announced as '
                'selected.',
            'The month title is a live region, so turning the page is '
                'announced. `semanticLabel` names the calendar before the '
                'month ("Check-in, October 2026").',
            'A day\'s tap area fills the space up to the next day and is '
                'never smaller than 24px, or 44px on touch screens.',
            'Days grow with large text. Under reduced motion, the new month '
                'fades in instead of sliding.',
            'The range band\'s filled ends mark where it starts and stops.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'value',
              'DateTime? / DsDateRange?',
              'The chosen day; the range in `DsRangeCalendar`.',
            ),
            (
              'onChanged',
              'ValueChanged<DateTime>? / ValueChanged<DsDateRange>?',
              'Called with the choice. Null disables the calendar.',
            ),
            (
              'firstDate / lastDate',
              'DateTime?',
              'The days that can be chosen.',
            ),
            (
              'selectableDayPredicate',
              'bool Function(DateTime)?',
              'Return false for days that cannot be chosen.',
            ),
            ('months', 'int', 'Months side by side. Default 1.'),
            ('showOutsideDays', 'bool', 'Shows neighbor months\' days, muted.'),
            (
              'initialMonth',
              'DateTime?',
              'The month shown first. Defaults to the value\'s, else today\'s.',
            ),
            (
              'onMonthChanged',
              'ValueChanged<DateTime>?',
              'Called when the page turns.',
            ),
            (
              'currentDate',
              'DateTime?',
              'Today. Set it for stable tests and screenshots.',
            ),
            ('semanticLabel', 'String?', 'Names the calendar.'),
            ('style', 'DsCalendarStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}

class _SingleDemo extends StatefulWidget {
  const _SingleDemo();

  @override
  State<_SingleDemo> createState() => _SingleDemoState();
}

class _SingleDemoState extends State<_SingleDemo> {
  DateTime? _due = _today().add(const Duration(days: 9));

  @override
  Widget build(BuildContext context) {
    // #region calendar-overview
    return DsCalendar(
      semanticLabel: 'Due date',
      value: _due,
      onChanged: (d) => setState(() => _due = d),
    );
    // #endregion
  }
}

class _LimitsDemo extends StatefulWidget {
  const _LimitsDemo();

  @override
  State<_LimitsDemo> createState() => _LimitsDemoState();
}

class _LimitsDemoState extends State<_LimitsDemo> {
  DateTime? _visit;

  @override
  Widget build(BuildContext context) {
    // #region calendar-limits
    // Weekdays, for 60 days:
    final today = DateTime.now();
    return DsCalendar(
      semanticLabel: 'Visit',
      value: _visit,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      selectableDayPredicate: (d) =>
          d.weekday != DateTime.saturday && d.weekday != DateTime.sunday,
      onChanged: (d) => setState(() => _visit = d),
    );
    // #endregion
  }
}

class _RangeDemo extends StatefulWidget {
  const _RangeDemo();

  @override
  State<_RangeDemo> createState() => _RangeDemoState();
}

class _RangeDemoState extends State<_RangeDemo> {
  late DsDateRange? _stay = () {
    final start = _today().add(const Duration(days: 7));
    return DsDateRange(start: start, end: start.add(const Duration(days: 4)));
  }();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      // #region calendar-range
      // Two months when they fit:
      final wide = c.maxWidth >= 560;
      return DsRangeCalendar(
        semanticLabel: 'Stay',
        months: wide ? 2 : 1,
        value: _stay,
        firstDate: DateTime.now(),
        onChanged: (r) => setState(() => _stay = r),
      );
      // #endregion
    },
  );
}

class _LocaleDemo extends StatefulWidget {
  const _LocaleDemo();

  @override
  State<_LocaleDemo> createState() => _LocaleDemoState();
}

class _LocaleDemoState extends State<_LocaleDemo> {
  DateTime? _day = _today();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final label = t.typography.labelStrong.copyWith(color: t.colors.textMuted);
    Widget titled(String title, Widget child) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(title, style: label),
        child,
      ],
    );
    return Wrap(
      spacing: 40,
      runSpacing: 32,
      alignment: WrapAlignment.center,
      children: [
        titled(
          'United States (en_US)',
          // #region calendar-locale
          Localizations.override(
            context: context,
            locale: const Locale('en', 'US'),
            child: DsCalendar(
              value: _day,
              onChanged: (d) => setState(() => _day = d),
            ),
          ),
          // #endregion
        ),
        titled(
          'United Kingdom (en_GB)',
          Localizations.override(
            context: context,
            locale: const Locale('en', 'GB'),
            child: DsCalendar(
              value: _day,
              onChanged: (d) => setState(() => _day = d),
            ),
          ),
        ),
      ],
    );
  }
}

class _OutsideDemo extends StatefulWidget {
  const _OutsideDemo();

  @override
  State<_OutsideDemo> createState() => _OutsideDemoState();
}

class _OutsideDemoState extends State<_OutsideDemo> {
  DateTime? _day;

  @override
  Widget build(BuildContext context) {
    // #region calendar-outside
    return DsCalendar(
      showOutsideDays: true,
      value: _day,
      onChanged: (d) => setState(() => _day = d),
    );
    // #endregion
  }
}

class _CustomDemo extends StatefulWidget {
  const _CustomDemo();

  @override
  State<_CustomDemo> createState() => _CustomDemoState();
}

class _CustomDemoState extends State<_CustomDemo> {
  DateTime? _day = _today().add(const Duration(days: 2));

  @override
  Widget build(BuildContext context) {
    // #region calendar-custom
    return DsCalendar(
      value: _day,
      onChanged: (d) => setState(() => _day = d),
      style: DsCalendarStyle(
        daySize: 36,
        dayRadius: BorderRadius.circular(999),
        columnGap: 2,
      ),
    );
    // #endregion
  }
}
