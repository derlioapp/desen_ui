import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Layers and their trigger, the page, the keyboard and the app
/// root (regression tests).
void main() {
  const fruit = [
    DsSelectOption(value: 'a', label: 'Apple'),
    DsSelectOption(value: 'b', label: 'Banana'),
  ];

  group('anchor leaves the window', () {
    testWidgets('an open select closes; keys no longer choose from it', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      String? value = 'a';
      final trigger = FocusNode();
      addTearDown(trigger.dispose);
      await tester.pumpWidget(
        DsApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              height: 400,
              child: SingleChildScrollView(
                controller: scroll,
                child: Column(
                  children: [
                    StatefulBuilder(
                      builder: (context, setState) => DsSelect<String>(
                        value: value,
                        focusNode: trigger,
                        onChanged: (v) => setState(() => value = v),
                        options: fruit,
                      ),
                    ),
                    const SizedBox(height: 2000),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsOneWidget);
      // Wheel-scroll the page so the select leaves the screen.
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(const Offset(150, 300)));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 1000)));
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(100));
      expect(find.text('Banana'), findsNothing, reason: 'the menu closed');
      expect(trigger.hasPrimaryFocus, isTrue, reason: 'focus on the select');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(value, 'a', reason: 'no choice through an unseen menu');
    });
  });

  group('trigger kept alive off screen in a lazy list', () {
    // A kept-alive child that is not visible gets a zeroed paint transform,
    // so its rect is NaN; NaN "overlaps" every rect.
    Widget list(ScrollController scroll, Widget trigger) => DsApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          height: 400,
          child: ListView(
            controller: scroll,
            children: [
              trigger,
              for (var i = 0; i < 40; i++)
                SizedBox(height: 60, child: Text('Filler $i')),
            ],
          ),
        ),
      ),
    );

    testWidgets('an autocomplete popup closes without a NaN paint', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        list(
          scroll,
          DsAutocomplete<String>(
            value: null,
            onChanged: (_) {},
            options: fruit,
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsOneWidget);
      // Focus keeps the field's item alive while it scrolls away.
      scroll.jumpTo(2000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsNothing, reason: 'the popup closed');
    });

    testWidgets('a date picker popup closes without a NaN height', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        list(
          scroll,
          DsDatePicker(value: DateTime(2026, 10, 6), onChanged: (_) {}),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.tap(find.byType(DsButton).first);
      await tester.pumpAndSettle();
      expect(find.byType(DsCalendar), findsOneWidget);
      scroll.jumpTo(2000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.byType(DsCalendar), findsNothing, reason: 'the popup closed');
    });

    var deleted = 0;
    setUp(() => deleted = 0);

    Widget table(ScrollController scroll, {DsTableSort? sort}) => DsApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          height: 300,
          child: DsTable<int>(
            scrollController: scroll,
            columns: [
              DsTableColumn<int>(
                id: 'n',
                label: 'Num',
                value: (r) => r,
                sortable: true,
                numeric: true,
              ),
              DsTableColumn<int>(
                id: 't',
                label: 'Text',
                value: (r) => 'Row $r',
              ),
            ],
            rows: List.generate(60, (r) => r),
            rowKey: (r) => r,
            sort: sort,
            onSortChanged: (_) {},
            onRowPressed: (_) {},
            rowMenuBuilder: (context, r) => [
              DsMenuItem(label: Text('Delete $r'), onPressed: () => deleted++),
            ],
          ),
        ),
      ),
    );

    testWidgets('a table row menu closes when its active row scrolls away; '
        'focus leaves the hidden menu', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(table(scroll));
      // The active row is kept alive off screen.
      await tester.tap(find.text('Row 1'));
      await tester.pump();
      await tester.longPress(find.text('Row 1'));
      await tester.pumpAndSettle();
      expect(find.text('Delete 1'), findsOneWidget);
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Delete 1'), findsNothing, reason: 'the menu closed');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(deleted, 0, reason: 'no key acts on a menu nobody sees');
    });

    testWidgets('a closing row menu whose row a sort moves away', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(table(scroll));
      await tester.tap(find.text('Row 1'));
      await tester.pump();
      await tester.longPress(find.text('Row 1'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpWidget(
        table(
          scroll,
          sort: const DsTableSort('n', DsTableSortDirection.descending),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  });

  group('trigger removed while open', () {
    testWidgets('the controller closes and the layer does not come back', (
      tester,
    ) async {
      final c = DsOverlayController();
      addTearDown(c.dispose);
      var notified = 0;
      c.addListener(() => notified++);
      var show = true;
      late StateSetter set;
      await tester.pumpWidget(
        DsApp(
          home: StatefulBuilder(
            builder: (context, s) {
              set = s;
              return Center(
                child: show
                    ? DsMenuAnchor(
                        controller: c,
                        items: [
                          DsMenuItem(
                            label: const Text('One'),
                            onPressed: () {},
                          ),
                        ],
                        child: DsButton(
                          onPressed: c.toggle,
                          child: const Text('Menu'),
                        ),
                      )
                    : const SizedBox(),
              );
            },
          ),
        ),
      );
      c.open();
      await tester.pumpAndSettle();
      expect(find.text('One'), findsOneWidget);
      notified = 0;
      set(() => show = false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(c.isOpen, isFalse);
      expect(notified, 1, reason: 'listeners hear it after the frame');
      set(() => show = true);
      await tester.pumpAndSettle();
      expect(find.text('One'), findsNothing);
    });

    testWidgets('a select removed while open leaves no errors', (tester) async {
      var show = true;
      late StateSetter set;
      await tester.pumpWidget(
        DsApp(
          home: StatefulBuilder(
            builder: (context, s) {
              set = s;
              return Center(
                child: show
                    ? DsSelect<String>(
                        value: null,
                        onChanged: (_) {},
                        options: fruit,
                      )
                    : const SizedBox(),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byType(DsSelect<String>));
      await tester.pumpAndSettle();
      set(() => show = false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('system back', () {
    Future<GlobalKey<NavigatorState>> pushPage(
      WidgetTester tester,
      Widget page,
    ) async {
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        DsApp(navigatorKey: nav, home: const Text('Home')),
      );
      nav.currentState!.push(
        DsPageRoute<void>(builder: (_) => Center(child: page)),
      );
      await tester.pumpAndSettle();
      return nav;
    }

    testWidgets('closes an open select before the page', (tester) async {
      await pushPage(
        tester,
        DsSelect<String>(value: null, onChanged: (_) {}, options: fruit),
      );
      await tester.tap(find.byType(DsSelect<String>));
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsNothing);
      expect(find.byType(DsSelect<String>), findsOneWidget, reason: 'page');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DsSelect<String>), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('closes a popover, then the page', (tester) async {
      final c = DsOverlayController();
      addTearDown(c.dispose);
      await pushPage(
        tester,
        DsPopover(
          controller: c,
          contentBuilder: (_) => const Text('Panel'),
          child: DsButton(onPressed: c.toggle, child: const Text('Open')),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(c.isOpen, isFalse);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('closes the innermost layer only: a submenu, then the menu', (
      tester,
    ) async {
      final c = DsOverlayController();
      addTearDown(c.dispose);
      await pushPage(
        tester,
        DsMenuAnchor(
          controller: c,
          items: [
            DsMenuItem.submenu(
              label: const Text('Move'),
              submenu: [
                DsMenuItem(label: const Text('Archive'), onPressed: () {}),
              ],
            ),
          ],
          child: DsButton(onPressed: c.toggle, child: const Text('Menu')),
        ),
      );
      c.open();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsNothing);
      expect(find.text('Move'), findsOneWidget, reason: 'the menu stays');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Move'), findsNothing);
      expect(find.text('Menu'), findsOneWidget, reason: 'the page stays');
    });

    testWidgets('a tooltip showing takes back first', (tester) async {
      await pushPage(
        tester,
        DsTooltip(
          message: 'Tip',
          child: DsButton(onPressed: () {}, child: const Text('Btn')),
        ),
      );
      final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: Offset.zero);
      addTearDown(g.removePointer);
      await g.moveTo(tester.getCenter(find.text('Btn')));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Tip'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Tip'), findsNothing);
      expect(find.text('Btn'), findsOneWidget);
    });

    testWidgets('a dialog is a route: back closes it and keeps the page', (
      tester,
    ) async {
      late BuildContext page;
      await pushPage(
        tester,
        Builder(
          builder: (context) {
            page = context;
            return const Text('Page');
          },
        ),
      );
      unawaited(
        showDsDialog<void>(
          context: page,
          builder: (_) => const DsDialog(title: Text('Dlg')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Dlg'), findsNothing);
      expect(find.text('Page'), findsOneWidget);
    });

    testWidgets('a closed layer does not hold back the page', (tester) async {
      await pushPage(
        tester,
        DsSelect<String>(value: null, onChanged: (_) {}, options: fruit),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('Escape and tooltips', () {
    Future<TestGesture> hover(WidgetTester tester, Finder target) async {
      final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: Offset.zero);
      addTearDown(g.removePointer);
      await g.moveTo(tester.getCenter(target));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      return g;
    }

    testWidgets('Escape hides a showing tooltip and stops there', (
      tester,
    ) async {
      var seen = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: Focus(
              focusNode: focus,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  seen++;
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: const DsTooltip(
                message: 'Tip',
                child: SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await hover(tester, find.byType(DsTooltip));
      expect(find.text('Tip'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Tip'), findsNothing);
      expect(seen, 0, reason: 'the focused widget did not get it too');
      // No tooltip showing: Escape goes on as usual.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(seen, 1);
    });

    testWidgets('in a dialog: the first Escape hides the tooltip, the second '
        'closes the dialog', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        DsApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      unawaited(
        showDsDialog<void>(
          context: ctx,
          builder: (c) => DsDialog(
            title: const Text('Dlg'),
            actions: [
              DsTooltip(
                message: 'Tip',
                child: DsButton(onPressed: () {}, child: const Text('OK')),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await hover(tester, find.text('OK'));
      expect(find.text('Tip'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Tip'), findsNothing);
      expect(find.text('Dlg'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Dlg'), findsNothing);
    });

    testWidgets('Escape hides the tooltip while the pointer rests on the '
        'tooltip itself', (tester) async {
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: DsTooltip(
              message: 'A fairly long tooltip message',
              child: DsButton(onPressed: () {}, child: const Text('Hover me')),
            ),
          ),
        ),
      );
      final g = await hover(tester, find.text('Hover me'));
      final tip = find.text('A fairly long tooltip message');
      expect(tip, findsOneWidget);
      // Onto the tooltip in small steps, inside the hover grace.
      final from = tester.getCenter(find.text('Hover me'));
      final to = tester.getCenter(tip);
      for (var i = 1; i <= 10; i++) {
        await g.moveTo(Offset.lerp(from, to, i / 10)!);
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
      expect(tip, findsOneWidget, reason: 'hoverable: it stays');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tip, findsNothing);
    });
  });

  group('tooltip on touch', () {
    testWidgets('a scroll that starts on the trigger shows no tooltip', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        DsApp(
          home: ListView(
            children: [
              for (var i = 0; i < 30; i++)
                Padding(
                  padding: const EdgeInsets.all(DsSpace.s8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DsTooltip(
                      message: 'Tip $i',
                      child: DsButton(
                        onPressed: () {},
                        child: Text('Button $i'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
      final g = await tester.startGesture(
        tester.getCenter(find.text('Button 3')),
        kind: PointerDeviceKind.touch,
      );
      // Longer than a long press, moving all the while.
      for (var k = 0; k < 12; k++) {
        await g.moveBy(const Offset(0, -15));
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(find.text('Tip 3'), findsNothing);
      await g.up();
      await tester.pumpAndSettle();
      expect(find.text('Tip 3'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a still long press still shows it', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: DsTooltip(
              message: 'Tip',
              child: DsButton(onPressed: () {}, child: const Text('Button')),
            ),
          ),
        ),
      );
      final g = await tester.startGesture(
        tester.getCenter(find.text('Button')),
        kind: PointerDeviceKind.touch,
      );
      // A tremor under the slop does not cancel it.
      await g.moveBy(const Offset(2, 2));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tip'), findsOneWidget);
      await g.up();
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a long press that shows it does not press the trigger', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      var presses = 0;
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: DsTooltip(
              message: 'Delete project',
              child: DsButton.icon(
                icon: const DsIcon(DsIcons.trash),
                semanticLabel: 'Delete',
                onPressed: () => presses++,
              ),
            ),
          ),
        ),
      );
      final g = await tester.startGesture(
        tester.getCenter(find.byType(DsButton)),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.text('Delete project'), findsOneWidget);
      await g.up();
      await tester.pumpAndSettle();
      expect(presses, 0);
      // A short tap still presses it.
      await tester.tap(find.byType(DsButton));
      await tester.pumpAndSettle();
      expect(presses, 1);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  testWidgets('a menu trigger with a tooltip: the keyboard round trip leaves '
      'no errors', (tester) async {
    final menu = DsOverlayController();
    addTearDown(menu.dispose);
    await tester.pumpWidget(
      DsApp(
        home: Center(
          child: DsMenuAnchor(
            controller: menu,
            items: [DsMenuItem(label: const Text('One'), onPressed: () {})],
            child: DsTooltip(
              message: 'More',
              child: DsButton(onPressed: menu.toggle, child: const Text('M')),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('More'), findsOneWidget, reason: 'shown on focus');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('More'), findsNothing);
    for (var i = 0; i < 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('One'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('One'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  group('no Overlay above', () {
    Widget bare(Widget child) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQueryData.fromView(View.of(context)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DsScope(child: Center(child: child)),
        ),
      ),
    );

    testWidgets('a tooltip shows its control alone and does not throw', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        bare(
          DsTooltip(
            message: 'Tip',
            child: DsButton.icon(
              onPressed: () {},
              icon: const DsIcon(DsIcons.x),
              semanticLabel: 'Close',
            ),
          ),
        ),
      );
      final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: Offset.zero);
      addTearDown(g.removePointer);
      await g.moveTo(tester.getCenter(find.byType(DsTooltip)));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      expect(find.text('Tip'), findsNothing);
      expect(
        tester.getSemantics(find.byType(DsButton)).tooltip,
        'Tip',
        reason: 'still described',
      );
      semantics.dispose();
    });

    for (final (name, widget) in [
      (
        'select',
        DsSelect<String>(value: null, onChanged: (_) {}, options: fruit),
      ),
      (
        'autocomplete',
        SizedBox(
          width: 300,
          child: DsAutocomplete<String>(
            value: null,
            onChanged: (_) {},
            options: fruit,
          ),
        ),
      ),
    ]) {
      testWidgets('a $name says what is missing', (tester) async {
        await tester.pumpWidget(bare(widget));
        expect(tester.takeException(), isNull, reason: 'builds closed');
        await tester.tap(find.byWidget(widget));
        await tester.pump();
        final error = tester.takeException();
        expect(error, isA<FlutterError>());
        final text = error.toString();
        expect(text, contains('no Overlay above it'));
        expect(text, contains('DsApp'));
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('toast', () {
    testWidgets('its overlay entry is disposed once it is gone', (
      tester,
    ) async {
      var created = 0, disposed = 0;
      void count(ObjectEvent e) {
        if (e.object is! OverlayEntry) return;
        if (e is ObjectCreated) created++;
        if (e is ObjectDisposed) disposed++;
      }

      late BuildContext ctx;
      await tester.pumpWidget(
        DsApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      FlutterMemoryAllocations.instance.addListener(count);
      addTearDown(
        () => FlutterMemoryAllocations.instance.removeListener(count),
      );
      final c = showDsToast(context: ctx, title: 'One');
      await tester.pumpAndSettle();
      c.dismiss();
      await tester.pumpAndSettle();
      expect(find.text('One'), findsNothing);
      expect(created, 1);
      expect(disposed, 1);
    }, skip: !kFlutterMemoryAllocationsEnabled);

    testWidgets('a long action at 2x text fits a 375px phone', (tester) async {
      tester.view.physicalSize = const Size(375, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        DsApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Center(
            child: DsToast(
              title: 'Saved',
              status: DsStatus.danger,
              actionLabel: 'Undo it now please',
              onAction: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byType(DsToast)).right,
        lessThanOrEqualTo(375),
      );
    });

    testWidgets('a finger resting on it keeps it', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        DsApp(
          theme: DsThemeData(platform: TargetPlatform.iOS),
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      showDsToast(
        context: ctx,
        title: 'Saved',
        description: 'Your file was saved',
      );
      await tester.pump(const Duration(milliseconds: 500));
      final g = await tester.startGesture(
        tester.getCenter(find.byType(DsToast)),
      );
      await tester.pump(const Duration(seconds: 10));
      expect(find.byType(DsToast), findsOneWidget);
      await g.up();
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.byType(DsToast), findsNothing, reason: 'then it goes');
    });

    testWidgets('at 2x text on a small phone it stays on screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const long =
          'Internationalisation configuration settings for the organisation';
      late BuildContext ctx;
      await tester.pumpWidget(
        DsApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      showDsToast(
        context: ctx,
        title: long,
        description: long + long,
        status: DsStatus.danger,
        actionLabel: 'Undo',
        onAction: () {},
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final rect = tester.getRect(find.byType(DsToast));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(640));
      // The text scrolls to its end.
      await tester.drag(find.text(long), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.text(long + long).hitTestable(), findsOneWidget);
    });
  });

  group('DsScope below the navigator: open layers follow it', () {
    PageRoute<T> route<T>(RouteSettings s, WidgetBuilder b) =>
        PageRouteBuilder<T>(settings: s, pageBuilder: (c, _, _) => b(c));

    late StateSetter setMode;
    late BuildContext page;
    var mode = DsThemeMode.light;

    Future<void> pumpApp(WidgetTester tester, {bool animate = false}) async {
      mode = DsThemeMode.light;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          pageRouteBuilder: route,
          home: StatefulBuilder(
            builder: (c, s) {
              setMode = s;
              return DsScope(
                themeMode: mode,
                animateChanges: animate,
                child: Builder(
                  builder: (c) {
                    page = c;
                    return const SizedBox.expand();
                  },
                ),
              );
            },
          ),
        ),
      );
    }

    testWidgets('a dialog switches to dark with the page', (tester) async {
      await pumpApp(tester);
      unawaited(
        showDsDialog<void>(
          context: page,
          builder: (_) => const DsDialog(title: Text('Hi')),
        ),
      );
      await tester.pumpAndSettle();
      Brightness inDialog() =>
          DsTheme.of(tester.element(find.text('Hi'))).brightness;
      expect(inDialog(), Brightness.light);
      setMode(() => mode = DsThemeMode.dark);
      await tester.pumpAndSettle();
      expect(inDialog(), Brightness.dark);
    });

    testWidgets('a dialog opened mid-fade ends on the final colors', (
      tester,
    ) async {
      await pumpApp(tester, animate: true);
      setMode(() => mode = DsThemeMode.dark);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      unawaited(
        showDsDialog<void>(
          context: page,
          builder: (_) => const DsDialog(title: Text('Hi')),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        DsTheme.colorsOf(tester.element(find.text('Hi'))).canvas,
        DsTheme.colorsOf(page).canvas,
      );
    });

    testWidgets('a toast switches to dark with the page', (tester) async {
      await pumpApp(tester);
      showDsToast(
        context: page,
        title: 'Saved',
        duration: const Duration(seconds: 30),
      );
      await tester.pumpAndSettle();
      setMode(() => mode = DsThemeMode.dark);
      await tester.pumpAndSettle();
      expect(
        DsTheme.of(tester.element(find.text('Saved'))).brightness,
        Brightness.dark,
      );
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
    });

    testWidgets('the page gone, the dialog keeps the last theme', (
      tester,
    ) async {
      await pumpApp(tester);
      final nav = Navigator.of(page);
      unawaited(
        showDsDialog<void>(
          context: page,
          builder: (_) => const DsDialog(title: Text('Hi')),
        ),
      );
      await tester.pumpAndSettle();
      setMode(() => mode = DsThemeMode.dark);
      await tester.pumpAndSettle();
      // Replace the page under the dialog.
      nav.replace(
        oldRoute: ModalRoute.of(page)!,
        newRoute: PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => const SizedBox(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        DsTheme.of(tester.element(find.text('Hi'))).brightness,
        Brightness.dark,
      );
    });
  });

  group('behavior that already held, kept as guards', () {
    testWidgets('a menu item that opens a dialog leaves focus in the dialog', (
      tester,
    ) async {
      final c = DsOverlayController();
      addTearDown(c.dispose);
      final trigger = FocusNode();
      addTearDown(trigger.dispose);
      await tester.pumpWidget(
        DsApp(
          home: Builder(
            builder: (ctx) => Center(
              child: DsMenuAnchor(
                controller: c,
                items: [
                  DsMenuItem(
                    label: const Text('Delete'),
                    onPressed: () =>
                        showDsConfirm(context: ctx, title: 'Sure?'),
                  ),
                ],
                child: DsButton(
                  focusNode: trigger,
                  onPressed: c.toggle,
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      trigger.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final primary = FocusManager.instance.primaryFocus!.context!;
      expect(
        primary.findAncestorWidgetOfExactType<DsDialog>(),
        isNotNull,
        reason: 'focus is inside the dialog',
      );
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('a page pushed over an open select and popped: Escape still '
        'closes it and focus is back on the select', (tester) async {
      final nav = GlobalKey<NavigatorState>();
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        DsApp(
          navigatorKey: nav,
          home: Center(
            child: DsSelect<String>(
              value: null,
              focusNode: node,
              onChanged: (_) {},
              options: fruit,
            ),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsOneWidget);
      unawaited(
        nav.currentState!.push(
          DsPageRoute<void>(builder: (_) => const Text('P2')),
        ),
      );
      await tester.pumpAndSettle();
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsNothing);
      expect(node.hasPrimaryFocus, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a select disabled or emptied while open', (tester) async {
      var options = fruit;
      ValueChanged<String?>? onChanged = (_) {};
      late StateSetter set;
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: StatefulBuilder(
              builder: (context, s) {
                set = s;
                return DsSelect<String>(
                  value: null,
                  onChanged: onChanged,
                  options: options,
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DsSelect<String>));
      await tester.pumpAndSettle();
      set(() => options = const []);
      await tester.pumpAndSettle();
      expect(find.text('No results'), findsOneWidget);
      set(() => onChanged = null);
      await tester.pumpAndSettle();
      expect(find.byType(DsMenu), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a localization scope below the navigator reaches an open '
        'dialog live', (tester) async {
      PageRoute<T> route<T>(RouteSettings s, WidgetBuilder b) =>
          PageRouteBuilder<T>(settings: s, pageBuilder: (c, _, _) => b(c));
      var forced = false;
      late StateSetter set;
      late BuildContext page;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          pageRouteBuilder: route,
          home: StatefulBuilder(
            builder: (c, s) {
              set = s;
              return DsLocalizationScope(
                localizations: forced
                    ? DsLocalizations.resolve(const Locale('tr'))
                    : null,
                child: DsScope(
                  child: Builder(
                    builder: (c) {
                      page = c;
                      return const SizedBox.expand();
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
      unawaited(
        showDsDialog<void>(
          context: page,
          builder: (_) => const DsDialog(title: Text('Hi')),
        ),
      );
      await tester.pumpAndSettle();
      String close() =>
          DsLocalizations.of(tester.element(find.text('Hi'))).close;
      expect(close(), 'Close');
      set(() => forced = true);
      await tester.pumpAndSettle();
      expect(close(), DsLocalizations.resolve(const Locale('tr')).close);
    });
  });

  group('triggers announce expanded', () {
    Tristate expandedOf(WidgetTester tester, String label) => tester
        .getSemantics(find.widgetWithText(DsButton, label))
        .getSemanticsData()
        .flagsCollection
        .isExpanded;

    testWidgets('DsButton.expanded is announced; null announces nothing', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        DsApp(
          home: Column(
            children: [
              DsButton(
                onPressed: () {},
                semanticExpanded: true,
                child: const Text('Open'),
              ),
              DsButton(onPressed: () {}, child: const Text('Plain')),
            ],
          ),
        ),
      );
      expect(expandedOf(tester, 'Open'), Tristate.isTrue);
      expect(expandedOf(tester, 'Plain'), Tristate.none);
      semantics.dispose();
    });

    testWidgets('a menu and a popover trigger follow their layer, also '
        'through a tooltip', (tester) async {
      final semantics = tester.ensureSemantics();
      final menu = DsOverlayController();
      final pop = DsOverlayController();
      addTearDown(menu.dispose);
      addTearDown(pop.dispose);
      await tester.pumpWidget(
        DsApp(
          home: Column(
            children: [
              DsMenuAnchor(
                controller: menu,
                items: [DsMenuItem(label: const Text('One'), onPressed: () {})],
                child: DsTooltip(
                  message: 'More',
                  child: DsButton(
                    onPressed: menu.toggle,
                    child: const Text('Menu'),
                  ),
                ),
              ),
              DsPopover(
                controller: pop,
                contentBuilder: (_) => const Text('Panel'),
                child: DsButton(
                  onPressed: pop.toggle,
                  child: const Text('Filters'),
                ),
              ),
            ],
          ),
        ),
      );
      expect(expandedOf(tester, 'Menu'), Tristate.isFalse);
      expect(expandedOf(tester, 'Filters'), Tristate.isFalse);
      menu.open();
      await tester.pumpAndSettle();
      expect(expandedOf(tester, 'Menu'), Tristate.isTrue);
      menu.close();
      pop.open();
      await tester.pumpAndSettle();
      expect(expandedOf(tester, 'Menu'), Tristate.isFalse);
      expect(expandedOf(tester, 'Filters'), Tristate.isTrue);
      semantics.dispose();
    });

    testWidgets('a tooltip alone does not make its button expandable', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        DsApp(
          home: DsTooltip(
            message: 'Tip',
            child: DsButton(onPressed: () {}, child: const Text('Btn')),
          ),
        ),
      );
      expect(expandedOf(tester, 'Btn'), Tristate.none);
      semantics.dispose();
    });
  });
}
