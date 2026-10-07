import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// An app-wide button theme styles the app's buttons, not the buttons that
/// are parts of other components (a text field's clear button, a
/// calendar's month arrows): those keep the look their component gives
/// them.
void main() {
  const loud = DsButtonThemeData(
    style: DsButtonStyle(
      padding: EdgeInsets.symmetric(horizontal: 24),
      height: 60,
      background: Color(0xFFFF0000),
    ),
  );

  final parts = <String, (Widget, Finder)>{
    'text field clear': (
      const DsTextField(initialValue: 'text', clearable: true),
      find.byType(DsButton),
    ),
    'calendar arrows': (
      DsCalendar(value: DateTime(2026, 10, 5), onChanged: (_) {}),
      find.byType(DsButton).first,
    ),
    'pagination arrows': (
      DsPagination(page: 2, pageCount: 5, onChanged: (_) {}),
      find.byType(DsButton).first,
    ),
    'date picker button': (
      DsDatePicker(value: DateTime(2026, 10, 5), onChanged: (_) {}),
      find.byType(DsButton),
    ),
    'time picker button': (
      DsTimePicker(value: const DsTime(9, 0), onChanged: (_) {}),
      find.byType(DsButton),
    ),
    'file item cancel': (
      DsFileItem(
        name: 'a.pdf',
        status: DsFileStatus.uploading,
        progress: .4,
        onCancel: () {},
      ),
      find.byType(DsButton),
    ),
  };

  Future<Size> sizeOf(
    WidgetTester tester,
    Widget part,
    Finder button, {
    required bool themed,
  }) async {
    Widget child = Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 360, child: part),
    );
    if (themed) child = DsButtonTheme(data: loud, child: child);
    await tester.pumpWidget(DsApp(home: child));
    await tester.pumpAndSettle();
    return tester.getSize(button);
  }

  for (final MapEntry(key: name, value: (part, button)) in parts.entries) {
    testWidgets('$name keeps its size under an app button theme', (
      tester,
    ) async {
      final plain = await sizeOf(tester, part, button, themed: false);
      final themed = await sizeOf(tester, part, button, themed: true);
      expect(themed, plain);
    });
  }

  testWidgets('the app\'s own buttons still take the theme', (tester) async {
    await tester.pumpWidget(
      DsApp(
        home: DsButtonTheme(
          data: loud,
          child: Center(
            child: DsButton(onPressed: () {}, child: const Text('Save')),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(DsButton)).height, 60);
  });
}
