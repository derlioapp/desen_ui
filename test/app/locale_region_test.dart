import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dates follow the region of the app's locale (en_GB writes and reads
/// dd/MM/y), also when the app lists language-only locales and follows
/// the device.
void main() {
  testWidgets('DsApp(locale: en_GB) uses British date conventions', (
    tester,
  ) async {
    late DsDateLocale conventions;
    await tester.pumpWidget(
      DsApp(
        locale: const Locale('en', 'GB'),
        home: Builder(
          builder: (context) {
            conventions = DsDateLocale.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(conventions.datePattern, 'dd/MM/y');
    expect(conventions.firstDayOfWeek, DateTime.monday);
    expect(conventions.uses24HourClock, isTrue);
  });

  testWidgets('a British user typing 05/10/2026 gets 5 October', (
    tester,
  ) async {
    DateTime? value;
    await tester.pumpWidget(
      DsApp(
        locale: const Locale('en', 'GB'),
        home: Align(
          alignment: Alignment.topLeft,
          child: StatefulBuilder(
            builder: (context, setState) => DsDatePicker(
              value: value,
              semanticLabel: 'Date',
              onChanged: (d) => setState(() => value = d),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '05/10/2026');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(value, DateTime(2026, 10, 5));
  });

  testWidgets('DsApp(locale: pl) keeps Polish conventions', (tester) async {
    late DsDateLocale conventions;
    await tester.pumpWidget(
      DsApp(
        locale: const Locale('pl'),
        home: Builder(
          builder: (context) {
            conventions = DsDateLocale.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    // As documented on DsDateLocale.resolve / dsConventionsLocale.
    expect(conventions.datePattern, 'd.MM.y');
    expect(conventions.firstDayOfWeek, DateTime.monday);
  });

  testWidgets('following the device, a British device keeps its region', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    late DsDateLocale conventions;
    late Locale resolved;
    await tester.pumpWidget(
      DsApp(
        supportedLocales: DsLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            conventions = DsDateLocale.of(context);
            resolved = Localizations.localeOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved, const Locale('en', 'GB'));
    expect(conventions.datePattern, 'dd/MM/y');
  });
}
