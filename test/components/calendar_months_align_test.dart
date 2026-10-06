import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Months side by side line up exactly: titles, weekday rows and grids,
/// though only the last month carries the previous / next buttons.
void main() {
  final range = DsDateRange(
    start: DateTime(2026, 10, 12),
    end: DateTime(2026, 10, 18),
  );

  void expectAligned(WidgetTester tester) {
    double top(Finder f) => tester.getRect(f).top;
    final october = find.text('October 2026');
    final november = find.text('November 2026');
    expect(top(october), top(november), reason: 'titles');
    expect(
      tester.getRect(october).bottom,
      tester.getRect(november).bottom,
      reason: 'title baselines',
    );
    // The weekday rows, one per month.
    final sunday = find.text('Su');
    expect(sunday, findsNWidgets(2));
    expect(top(sunday.at(0)), top(sunday.at(1)), reason: 'weekday rows');
    // The grids: the 15th is in the third row of both months.
    final fifteenth = find.text('15');
    expect(top(fifteenth.at(0)), top(fifteenth.at(1)), reason: 'grids');
  }

  for (final platform in [TargetPlatform.macOS, TargetPlatform.android]) {
    testWidgets('DsCalendar months: 2 (${platform.name})', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      tester.view
        ..physicalSize = const Size(1280, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        DsApp(
          locale: const Locale('en', 'US'),
          home: Center(
            child: DsRangeCalendar(value: range, onChanged: (_) {}, months: 2),
          ),
        ),
      );
      expectAligned(tester);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('DsDateRangePicker popup', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DsApp(
        locale: const Locale('en', 'US'),
        home: Center(
          child: SizedBox(
            width: 320,
            child: DsDateRangePicker(value: range, onChanged: (_) {}),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel(RegExp('Choose date')));
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);
    expectAligned(tester);
  });
}
