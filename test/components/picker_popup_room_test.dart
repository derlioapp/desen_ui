// The pickers' popups fit small windows (800×600, a landscape
// phone, a 320px touch phone), and the time columns fade only where more
// items lie beyond, never over the chosen one.
import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(
  WidgetTester tester,
  Size window,
  Widget picker, {
  double textScale = 1,
  Alignment alignment = Alignment.center,
}) async {
  tester.view
    ..physicalSize = window
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    DsApp(
      theme: DsThemeData(),
      themeMode: DsThemeMode.light,
      locale: const Locale('en', 'US'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Align(
        alignment: alignment,
        child: Padding(padding: const EdgeInsets.all(8), child: picker),
      ),
    ),
  );
  await tester.tap(find.byType(DsButton).first);
  await tester.pumpAndSettle();
}

/// Whether [finder] lies inside the window.
void _inWindow(WidgetTester tester, Finder finder, Size window) {
  final rect = tester.getRect(finder);
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(window.height));
  expect(rect.right, lessThanOrEqualTo(window.width));
}

void main() {
  const windows = [Size(800, 600), Size(844, 390), Size(320, 640)];

  for (final window in windows) {
    testWidgets('date picker popup in $window: no overflow, last week '
        'reachable by keys', (tester) async {
      await _open(
        tester,
        window,
        DsDatePicker(
          value: DateTime(2026, 1, 2),
          currentDate: DateTime(2026, 1, 2),
          onChanged: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(DsCalendar), findsOneWidget);
      // Down four weeks to the 30th: it scrolls into view.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      final day30 = find.descendant(
        of: find.byType(DsCalendar),
        matching: find.text('30'),
      );
      _inWindow(tester, day30.last, window);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('range picker popup in $window: no overflow', (tester) async {
      await _open(
        tester,
        window,
        DsDateRangePicker(value: null, onChanged: (_) {}),
      );
      expect(tester.takeException(), isNull);
      final calendar = tester.widget<DsRangeCalendar>(
        find.byType(DsRangeCalendar),
      );
      // Two months only where they fit beside each other.
      expect(calendar.months, window.width >= 640 ? 2 : 1);
    });

    testWidgets('time picker popup in $window: no overflow', (tester) async {
      await _open(
        tester,
        window,
        DsTimePicker(value: const DsTime(9, 30), onChanged: (_) {}),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a 320px touch phone: the calendar narrows its columns but '
      'keeps tall rows', (tester) async {
    await _open(
      tester,
      const Size(320, 640),
      DsDatePicker(value: DateTime(2024, 2, 29), onChanged: (_) {}),
      alignment: Alignment.topLeft,
    );
    expect(tester.takeException(), isNull);
    final calendar = tester.getRect(find.byType(DsCalendar));
    expect(calendar.width, lessThanOrEqualTo(320 - 2 * 8 - 2 * 16));
    // A day's tap area: the row height is the touch target.
    final day = tester.getSize(
      find.ancestor(of: find.text('15'), matching: find.byType(SizedBox)).first,
    );
    expect(day.height, greaterThanOrEqualTo(44));
    expect(day.width, greaterThanOrEqualTo(36));
  });

  testWidgets('a bare calendar at 304px and text scale 3 fits', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3)),
          child: Center(
            child: SizedBox(
              width: 304,
              child: DsCalendar(
                value: DateTime(2026, 10, 5),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  // Two months that do not fit side by side at full size stack (since
  // 7e2fd89): narrowed side by side, their titles were cut. Stacked, they
  // are taller than the window, so the page scrolls (WCAG 1.4.10).
  testWidgets('two months at 320px stack instead of overflowing', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          child: Center(
            child: DsCalendar(
              value: DateTime(2026, 10, 5),
              months: 2,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(DsCalendar)).width,
      lessThanOrEqualTo(320),
    );
    final october = find.text('October 2026');
    final november = find.text('November 2026');
    expect(
      tester.getRect(november).top,
      greaterThan(tester.getRect(october).bottom),
    );
    for (final title in [october, november]) {
      expect(
        tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
        isFalse,
      );
    }
  });

  testWidgets('time picker at text scale 3 on a 320px phone', (tester) async {
    await _open(
      tester,
      const Size(320, 640),
      DsTimePicker(value: const DsTime(9, 30), onChanged: (_) {}),
      textScale: 3,
      alignment: Alignment.topLeft,
    );
    expect(tester.takeException(), isNull);
  });

  group('time column fade', () {
    ShaderMask? maskOf(WidgetTester tester, String item) {
      final masks = find.ancestor(
        of: find.text(item),
        matching: find.byType(ShaderMask),
      );
      return masks.evaluate().isEmpty
          ? null
          : tester.widget<ShaderMask>(masks.first);
    }

    testWidgets('a column that fits (AM/PM, 15-minute steps) has no fade', (
      tester,
    ) async {
      await _open(
        tester,
        const Size(800, 600),
        DsTimePicker(
          value: const DsTime(14, 30),
          minuteStep: 15,
          use24HourClock: false,
          onChanged: (_) {},
        ),
      );
      expect(maskOf(tester, 'PM'), isNull);
      expect(maskOf(tester, '45'), isNull);
      expect(maskOf(tester, '2'), isNotNull);
    });

    testWidgets('rows rest whole; the chosen hour is clear of the faded '
        'edge rows', (tester) async {
      await _open(
        tester,
        const Size(800, 600),
        DsTimePicker(
          value: const DsTime(14, 30),
          use24HourClock: true,
          onChanged: (_) {},
        ),
      );
      final scroll = tester.state<ScrollableState>(
        find
            .ancestor(of: find.text('14'), matching: find.byType(Scrollable))
            .first,
      );
      final viewport = scroll.context.findRenderObject()! as RenderBox;
      final top = viewport.localToGlobal(Offset.zero).dy;
      final bottom = top + viewport.size.height;
      final extent = tester.getSize(find.text('14')).height;
      bool clear(String item) {
        final r = tester.getRect(find.text(item));
        // Off the outer half row at each end.
        return r.top >= top + extent / 2 && r.bottom <= bottom - extent / 2;
      }

      expect(scroll.position.pixels % 1, 0);
      expect(clear('14'), isTrue);
      // Down three hours: the chosen hour stays clear of the bottom fade.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      expect(clear('18'), isTrue);
      // To the first hour: the top no longer fades.
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, 0);
    });
  });
}
