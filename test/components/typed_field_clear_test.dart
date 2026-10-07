// Clearing a typed field from outside while it holds invalid text: the
// field already reported null, so `value: null` again cannot tell a clear
// from a rebuild. A new key or `FormState.reset()` empties it, as the
// class docs say.
import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => DsApp(
  theme: DsThemeData(),
  themeMode: DsThemeMode.light,
  locale: const Locale('en', 'US'),
  home: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: 300, child: child),
  ),
);

/// A field and a "Clear" button that sets the value to null and, with
/// [newKey], gives the field a new key.
class _Clearable extends StatefulWidget {
  const _Clearable({super.key, required this.newKey, required this.field});

  final bool newKey;
  final Widget Function(Key key, ValueChanged<Object?> set) field;

  @override
  State<_Clearable> createState() => _ClearableState();
}

class _ClearableState extends State<_Clearable> {
  int clears = 0;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      widget.field(ValueKey(clears), (_) => setState(() {})),
      DsButton(
        onPressed: () => setState(() {
          if (widget.newKey) clears++;
        }),
        child: const Text('Clear'),
      ),
    ],
  );
}

String _text(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  final fields =
      <String, (String, Widget Function(Key, ValueChanged<Object?>))>{
        'number field': (
          '50',
          (key, set) =>
              DsNumberField(key: key, value: null, max: 10, onChanged: set),
        ),
        'date picker': (
          '13/45/2026',
          (key, set) => DsDatePicker(key: key, value: null, onChanged: set),
        ),
        'date range picker': (
          'soon',
          (key, set) =>
              DsDateRangePicker(key: key, value: null, onChanged: set),
        ),
        'time picker': (
          '25:99',
          (key, set) => DsTimePicker(key: key, value: null, onChanged: set),
        ),
      };

  for (final MapEntry(key: name, value: (typed, field)) in fields.entries) {
    testWidgets('$name: value null keeps invalid text, a new key clears it', (
      tester,
    ) async {
      for (final newKey in [false, true]) {
        await tester.pumpWidget(
          _app(_Clearable(key: ValueKey(newKey), newKey: newKey, field: field)),
        );
        await tester.enterText(find.byType(EditableText), typed);
        await tester.pump();
        expect(_text(tester), typed);
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
        expect(_text(tester), newKey ? isEmpty : typed);
      }
    });
  }

  testWidgets('FormState.reset() clears a number form field\'s invalid text', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      _app(
        Form(
          key: form,
          child: DsNumberFormField(label: const Text('Amount'), max: 10),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '50');
    await tester.pump();
    expect(_text(tester), '50');
    form.currentState!.reset();
    await tester.pumpAndSettle();
    expect(_text(tester), isEmpty);
  });
}
