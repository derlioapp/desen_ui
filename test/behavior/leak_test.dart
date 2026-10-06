import 'dart:async';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Components dispose what they create: mounted, used and unmounted (also
/// with a layer open) under Flutter's leak tracker, which reports objects
/// left undisposed.
///
/// The suite does not track leaks everywhere: the tests themselves create
/// controllers and nodes freely. This file tracks the components.
final _leaks = LeakTesting.settings
    .withTrackedAll()
    .withCreationStackTrace()
    .withIgnored(
      // Test framework internals.
      createdByTestHelpers: true,
      // The app-wide "prefers more contrast" notifier lives as long as
      // the app; it is never disposed by design.
      notDisposed: {'ValueNotifier<bool>': 1},
    );

Widget _app(Widget child) => DsApp(
  theme: DsThemeData(platform: TargetPlatform.macOS),
  home: Builder(builder: (_) => Center(child: child)),
);

class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String? sel = 'a';
  DateTime? date;
  DsTime? time;
  num? number = 1;
  double slider = .3;
  DsRangeValues range = const DsRangeValues(start: .2, end: .7);
  bool sw = false;
  bool? cb = false;
  String tab = 'a';
  String? city;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DsTextField(placeholder: 'tf', clearable: true),
        DsSelect<String>(
          value: sel,
          onChanged: (v) => setState(() => sel = v),
          semanticLabel: 'sel',
          options: const [
            DsSelectOption(value: 'a', label: 'A'),
            DsSelectOption(value: 'b', label: 'B'),
          ],
        ),
        DsDatePicker(
          value: date,
          semanticLabel: 'date',
          onChanged: (v) => setState(() => date = v),
        ),
        DsTimePicker(
          value: time,
          semanticLabel: 'time',
          onChanged: (v) => setState(() => time = v),
        ),
        DsNumberField(
          value: number,
          semanticLabel: 'num',
          onChanged: (v) => setState(() => number = v),
        ),
        DsSlider(
          value: slider,
          semanticLabel: 'slider',
          onChanged: (v) => setState(() => slider = v),
        ),
        DsRangeSlider(
          values: range,
          semanticLabel: 'range',
          onChanged: (v) => setState(() => range = v),
        ),
        DsSwitch(value: sw, onChanged: (v) => setState(() => sw = v)),
        DsCheckbox(value: cb, onChanged: (v) => setState(() => cb = v)),
        DsTooltip(
          message: 'tip',
          child: DsButton(onPressed: () {}, child: const Text('btn')),
        ),
        DsMenuAnchor(
          items: [DsMenuItem(label: const Text('One'), onPressed: () {})],
          builder: (context, c, _) =>
              DsButton(onPressed: c.toggle, child: const Text('menu')),
        ),
        DsPopover(
          contentBuilder: (_) => const Text('pop content'),
          builder: (context, c, _) =>
              DsButton(onPressed: c.toggle, child: const Text('pop')),
        ),
        DsAutocomplete<String>(
          value: city,
          semanticLabel: 'city',
          onChanged: (v) => setState(() => city = v),
          options: const [
            DsSelectOption(value: 'Ankara', label: 'Ankara'),
            DsSelectOption(value: 'Izmir', label: 'Izmir'),
          ],
        ),
      ],
    ),
  );
}

void main() {
  LeakTesting.enable();

  // Creates the app-wide notifiers before tracking starts: untracked, as
  // LeakTesting.enable() tracks every test that does not opt out.
  testWidgets(
    'warm up',
    experimentalLeakTesting: LeakTesting.settings.withIgnoredAll(),
    (tester) async {
      await tester.pumpWidget(_app(const SizedBox()));
    },
  );

  testWidgets('components do not leak', experimentalLeakTesting: _leaks, (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const _Harness()));
    await tester.pumpAndSettle();

    Future<void> openClose(String text) async {
      await tester.tap(find.text(text).first);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    }

    await openClose('menu');
    await openClose('pop');
    await tester.tap(find.bySemanticsLabel('sel').first);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'hello');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('city').first);
    await tester.enterText(find.byType(EditableText).last, 'An');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    // Unmount everything while a layer is open.
    await tester.tap(find.text('pop'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('toast and dialog do not leak', experimentalLeakTesting: _leaks, (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    showDsToast(context: ctx, title: 'Saved');
    await tester.pump(const Duration(milliseconds: 100));
    unawaited(
      showDsDialog<void>(
        context: ctx,
        builder: (_) =>
            const DsDialog(title: Text('T'), description: Text('B')),
      ),
    );
    await tester.pumpAndSettle();
    Navigator.of(ctx).pop();
    await tester.pumpAndSettle(const Duration(seconds: 10));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'a paragraph with links does not leak',
    experimentalLeakTesting: _leaks,
    (tester) async {
      // Each link owns a tap recognizer and a focus node; links that go
      // away, and the paragraph itself, dispose theirs.
      Widget paragraph(int links) => _app(
        SizedBox(
          width: 200,
          child: DsParagraph(
            children: [
              for (var i = 0; i < links; i++) ...[
                TextSpan(text: 'Item $i, '),
                DsLinkSpan(label: 'open item $i', onPressed: () {}),
              ],
            ],
          ),
        ),
      );
      await tester.pumpWidget(paragraph(3));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getTopLeft(find.byType(DsParagraph)),
      );
      await mouse.moveBy(const Offset(4, 4));
      await tester.pump();
      await tester.pumpWidget(paragraph(1));
      await tester.pumpWidget(paragraph(2));
      await tester.pumpWidget(const SizedBox());
      await mouse.removePointer();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'theme cross-fade does not leak',
    experimentalLeakTesting: _leaks,
    (tester) async {
      Widget app(DsThemeMode m) => DsApp(
        theme: DsThemeData(platform: TargetPlatform.macOS),
        themeMode: m,
        home: const Center(child: Text('x')),
      );
      await tester.pumpWidget(app(DsThemeMode.light));
      for (var i = 0; i < 4; i++) {
        await tester.pumpWidget(
          app(i.isEven ? DsThemeMode.dark : DsThemeMode.light),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
  );
}
