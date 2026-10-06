import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A field too narrow for its buttons never overflows. Extras give
/// way in order (clear, error icon, unit, picker and step buttons, show
/// password) while the text keeps about three characters; the keys and
/// semantics actions stay.

Widget _app(
  Widget child, {
  required double width,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
}) => DsApp(
  theme: DsThemeData(),
  themeMode: DsThemeMode.light,
  locale: const Locale('en', 'US'),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: Directionality(textDirection: direction, child: c!),
  ),
  home: Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(width: width, child: child),
    ),
  ),
);

final Map<String, Widget Function()> _fields = {
  'password': () => const DsTextField(
    initialValue: 'hunter2',
    obscureText: true,
    revealable: true,
    clearable: true,
    error: true,
    leading: DsIcon(DsIcons.search),
  ),
  'text with unit': () => const DsTextField(
    initialValue: '12',
    clearable: true,
    error: true,
    leading: DsIcon(DsIcons.search),
    trailing: Text('unit'),
  ),
  'search with hint': () =>
      const DsSearchField(placeholder: 'Search', shortcut: '⌘K'),
  'number': () => DsNumberField(
    value: 12,
    onChanged: (_) {},
    unit: 'kg',
    prefix: r'$',
    error: true,
  ),
  'date': () => DsDatePicker(
    value: DateTime(2024, 2, 29),
    error: true,
    onChanged: (_) {},
  ),
  'date range': () => DsDateRangePicker(
    value: DsDateRange(start: DateTime(2024, 2, 1), end: DateTime(2024, 3, 1)),
    onChanged: (_) {},
  ),
  'time': () =>
      DsTimePicker(value: const DsTime(23, 59), error: true, onChanged: (_) {}),
};

/// Whether the button named [label] is on screen (painted, hit, read).
bool _shows(WidgetTester tester, String label) =>
    tester.getSemantics(find.byType(DsApp)).let((root) {
      var found = false;
      bool visit(SemanticsNode node) {
        if (node.label == label) found = true;
        node.visitChildren(visit);
        return !found;
      }

      visit(root);
      return found;
    });

Finder _icon(DsIconData icon) =>
    find.byWidgetPredicate((w) => w is DsIcon && w.icon == icon);

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

/// The text field's own render box size, to compare with its slot.
Size _fieldSize(WidgetTester tester) =>
    tester.getSize(find.byType(DsTextField).first);

void main() {
  for (final MapEntry(key: name, value: build) in _fields.entries) {
    for (final width in [64.0, 96.0, 120.0, 160.0]) {
      for (final scale in [1.0, 2.0]) {
        for (final direction in TextDirection.values) {
          testWidgets('$name at ${width.toInt()}px ×$scale ${direction.name} '
              'does not overflow', (tester) async {
            await tester.pumpWidget(
              _app(
                build(),
                width: width,
                textScale: scale,
                direction: direction,
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(_fieldSize(tester).width, lessThanOrEqualTo(width));
          });
        }
      }
    }
  }

  // The layout-stress probe's field entries: long text, large type, RTL
  // and high pixel ratios in phone-width columns.
  const long =
      'Supercalifragilisticexpialidocious-extraordinarily-long-label-without-'
      'any-breaking-opportunity-whatsoever مرحبا بالعالم';
  final stress = <String, Widget Function()>{
    'text field': () => const DsTextField(
      placeholder: long,
      leading: DsIcon(DsIcons.search),
      trailing: Text('unit'),
    ),
    'number field': () => DsNumberField(
      value: 123456789,
      onChanged: (_) {},
      unit: 'kg',
      prefix: r'$',
    ),
    'field': () => const DsField(
      label: Text(long),
      description: Text(long),
      errorText: long,
      required: true,
      child: DsTextField(clearable: true, initialValue: long),
    ),
    'autocomplete': () => DsAutocomplete<int>(
      value: 0,
      onChanged: (_) {},
      options: const [DsSelectOption(value: 0, label: long)],
    ),
    'date picker': () =>
        DsDatePicker(value: DateTime(2024, 2, 29), onChanged: (_) {}),
    'date range picker': _fields['date range']!,
    'time picker': () =>
        DsTimePicker(value: const DsTime(23, 59), onChanged: (_) {}),
  };
  for (final cfg in [
    (name: 'w320', width: 320.0, scale: 1.0, rtl: false, dpr: 1.0),
    (name: 'w375x2', width: 375.0, scale: 2.0, rtl: false, dpr: 3.0),
    (name: 'w320x3', width: 320.0, scale: 3.0, rtl: false, dpr: 1.0),
    (name: 'w360x2rtl', width: 360.0, scale: 2.0, rtl: true, dpr: 1.5),
  ]) {
    for (final MapEntry(key: name, value: build) in stress.entries) {
      testWidgets('${cfg.name}: $name lays out without errors', (tester) async {
        tester.view.physicalSize = Size(cfg.width * cfg.dpr, 800 * cfg.dpr);
        tester.view.devicePixelRatio = cfg.dpr;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            // A page column scrolls; the field must fit its width.
            SingleChildScrollView(child: build()),
            width: cfg.width - 16,
            textScale: cfg.scale,
            direction: cfg.rtl ? TextDirection.rtl : TextDirection.ltr,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('give-way order', () {
    testWidgets('a password field drops clear and the error icon before '
        'the show-password button', (tester) async {
      final handle = tester.ensureSemantics();
      Future<void> at(double width) async {
        await tester.pumpWidget(_app(_fields['password']!(), width: width));
        await tester.pump();
      }

      await at(320);
      expect(_shows(tester, 'Clear'), isTrue);
      expect(_shows(tester, 'Show password'), isTrue);
      expect(_icon(DsIcons.circleAlert).hitTestable(), findsOneWidget);

      await at(120);
      expect(_shows(tester, 'Clear'), isFalse);
      expect(_shows(tester, 'Show password'), isTrue);
      expect(_icon(DsIcons.circleAlert).hitTestable(), findsNothing);

      await at(64);
      expect(_shows(tester, 'Show password'), isFalse);
      handle.dispose();
    });

    testWidgets('a hidden clear button leaves its action on the field', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'hunter2');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          DsTextField(
            controller: controller,
            clearable: true,
            revealable: true,
            obscureText: true,
          ),
          width: 110,
        ),
      );
      await tester.pump();
      expect(_shows(tester, 'Clear'), isFalse);
      final node = tester.getSemantics(find.byType(EditableText));
      final clear = node.getSemanticsData().customSemanticsActionIds!.map(
        (id) => CustomSemanticsAction.getAction(id)!.label,
      );
      expect(clear, contains('Clear'));
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.customAction,
          viewId: tester.view.viewId,
          nodeId: node.id,
          arguments: CustomSemanticsAction.getIdentifier(
            const CustomSemanticsAction(label: 'Clear'),
          ),
        ),
      );
      await tester.pump();
      expect(controller.text, isEmpty);
      handle.dispose();
    });

    testWidgets('a hidden show-password button is not a Tab stop', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _app(
          DsTextField(
            focusNode: focus,
            initialValue: 'hunter2',
            revealable: true,
            obscureText: true,
          ),
          width: 64,
          textScale: 2,
        ),
      );
      await tester.pump();
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      // Focus left the field without landing on an invisible button.
      final primary = FocusManager.instance.primaryFocus;
      expect(
        primary?.context?.findAncestorWidgetOfExactType<DsButton>(),
        isNull,
      );
    });

    testWidgets('a number field drops the unit before the step buttons, '
        'and keeps the keys and actions without them', (tester) async {
      final handle = tester.ensureSemantics();
      num? value = 12;
      Future<void> at(double width) async {
        await tester.pumpWidget(
          _app(
            StatefulBuilder(
              builder: (context, setState) => DsNumberField(
                value: value,
                unit: 'kg',
                onChanged: (v) => setState(() => value = v),
              ),
            ),
            width: width,
          ),
        );
        await tester.pump();
      }

      Finder steps() => _icon(DsIcons.plus).hitTestable();
      Finder unit() => find.text('kg').hitTestable();

      await at(240);
      expect(steps(), findsOneWidget);
      expect(unit(), findsOneWidget);

      await at(150);
      expect(steps(), findsOneWidget);
      expect(unit(), findsNothing);

      await at(96);
      expect(steps(), findsNothing);
      // The arrow keys and the increase action still step.
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(value, 13);
      tester.semantics.performAction(
        find.semantics.byAction(SemanticsAction.increase),
        SemanticsAction.increase,
      );
      await tester.pump();
      expect(value, 14);
      handle.dispose();
    });

    testWidgets('a date field drops its button only after the error icon, '
        'and Alt+Down still opens it', (tester) async {
      Future<void> at(double width) async {
        await tester.pumpWidget(_app(_fields['date']!(), width: width));
        await tester.pump();
      }

      Finder button() => _icon(DsIcons.calendar).hitTestable();
      Finder alert() => _icon(DsIcons.circleAlert).hitTestable();

      await at(240);
      expect(button(), findsOneWidget);
      expect(alert(), findsOneWidget);

      await at(96);
      expect(button(), findsOneWidget);
      expect(alert(), findsNothing);

      await at(64);
      expect(button(), findsNothing);
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(find.byType(DsCalendar), findsOneWidget);
    });
  });
}
