import 'dart:ui' show Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// The sidebar's value API and its collapsed icon rail: the width moves
/// with the theme's motion (at once under reduced motion), icons stay put,
/// labels become tooltips, counts become dots, sections become lines, and
/// screen readers still hear every label, count and the current page.
void main() {
  Widget sidebar({
    bool collapsed = false,
    String? value = 'inbox',
    ValueChanged<String>? onChanged,
    Widget? header,
  }) => SizedBox(
    height: 400,
    child: DsSidebar<String>(
      semanticLabel: 'Ana',
      collapsed: collapsed,
      value: value,
      onChanged: onChanged ?? (_) {},
      header: header,
      children: const [
        DsSidebarItem(
          value: 'inbox',
          leading: DsIcon(DsIcons.inbox),
          label: Text('Gelen'),
          count: 4,
        ),
        DsSidebarSection(label: Text('EKİPLER')),
        DsSidebarItem(
          value: 'design',
          leading: DsIcon(DsIcons.folder),
          label: Text('Tasarım'),
        ),
      ],
    ),
  );

  final rail = find.byType(DsSidebar<String>);
  double width(WidgetTester tester) => tester.getSize(rail).width;

  group('value', () {
    testWidgets('selects the matching item and reports presses', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var value = 'inbox';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) =>
                sidebar(value: value, onChanged: (v) => set(() => value = v)),
          ),
        ),
      );
      Tristate selected(String label) =>
          tester.getSemantics(find.text(label)).flagsCollection.isSelected;
      expect(selected('Gelen'), Tristate.isTrue);
      expect(selected('Tasarım'), Tristate.isFalse);
      await tester.tap(find.text('Tasarım'));
      await tester.pump();
      expect(value, 'design');
      expect(selected('Tasarım'), Tristate.isTrue);
      expect(selected('Gelen'), Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('items with a value are disabled without onChanged', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 220,
            height: 200,
            child: DsSidebar<String>(
              children: [DsSidebarItem(value: 'a', label: Text('A'))],
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('A')).flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      handle.dispose();
    });

    testWidgets('an item calls its own onPressed after reporting its value', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 200,
            child: DsSidebar<String>(
              onChanged: (v) => calls.add('changed $v'),
              children: [
                DsSidebarItem(
                  value: 'a',
                  label: const Text('A'),
                  onPressed: () => calls.add('pressed'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('A'));
      expect(calls, ['changed a', 'pressed']);
    });
  });

  group('collapsed', () {
    testWidgets('the width moves to the rail and back; icons stay put', (
      tester,
    ) async {
      final theme = DsThemeData();
      final s = DsSidebar.defaultStyle(theme);
      await tester.pumpWidget(host(sidebar(), theme: theme));
      expect(width(tester), s.width);
      Offset iconIn() =>
          tester.getTopLeft(find.byType(DsIcon).first) -
          tester.getTopLeft(rail);
      final iconAt = iconIn();

      await tester.pumpWidget(host(sidebar(collapsed: true), theme: theme));
      await tester.pump(theme.motion.moveDuration ~/ 4);
      expect(width(tester), lessThan(s.width!), reason: 'moving');
      expect(width(tester), greaterThan(s.collapsedWidth!), reason: 'moving');
      await tester.pumpAndSettle();
      expect(width(tester), s.collapsedWidth);
      expect(iconIn(), iconAt);

      await tester.pumpWidget(host(sidebar(), theme: theme));
      await tester.pumpAndSettle();
      expect(width(tester), s.width);
      expect(tester.takeException(), isNull, reason: 'no overflow');
    });

    testWidgets('reduced motion: the width changes at once', (tester) async {
      final theme = DsThemeData(motion: const DsMotion(reduced: true));
      await tester.pumpWidget(host(sidebar(), theme: theme));
      await tester.pumpWidget(host(sidebar(collapsed: true), theme: theme));
      await tester.pump();
      expect(width(tester), DsSidebar.defaultStyle(theme).collapsedWidth);
    });

    for (final direction in TextDirection.values) {
      testWidgets('the default rail centers the icons (${direction.name})', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(sidebar(collapsed: true), direction: direction),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(find.byType(DsIcon).first).dx,
          tester.getCenter(rail).dx,
        );
      });
    }

    testWidgets('labels leave the screen, not the semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(sidebar(collapsed: true)));
      await tester.pumpAndSettle();
      expect(find.text('Gelen'), findsNothing);
      expect(find.text('Tasarım'), findsNothing);
      final inbox = tester.getSemantics(find.byType(DsPressable).first);
      expect(inbox.label, contains('Gelen'));
      expect(inbox.label, contains('4'), reason: 'the count, as a dot');
      expect(inbox.flagsCollection.isSelected, Tristate.isTrue);
      expect(inbox.flagsCollection.isButton, isTrue);
      expect(inbox.tooltip, isEmpty, reason: 'the label is not read twice');
      final design = tester.getSemantics(find.byType(DsPressable).last);
      expect(design.label, 'Tasarım');
      expect(design.flagsCollection.isSelected, Tristate.isFalse);
      // The section turns into a line and stays a heading.
      expect(find.byType(DsLine), findsOneWidget);
      expect(
        tester.getSemantics(find.text('EKİPLER')).flagsCollection.isHeader,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('the count dot takes the count color', (tester) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        host(sidebar(collapsed: true, value: null), theme: theme),
      );
      await tester.pumpAndSettle();
      final item = DsSidebarItem.defaultStyle(theme);
      final dot = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as DsBoxDecoration?)?.color == item.countStyle!.color,
      );
      expect(dot, findsOneWidget);
      expect(tester.getSize(dot), Size.square(item.dotSize!));
    });

    testWidgets('a section keeps its height, so items do not move', (
      tester,
    ) async {
      await tester.pumpWidget(host(sidebar()));
      final below = tester.getTopLeft(find.byType(DsIcon).last).dy;
      await tester.pumpWidget(host(sidebar(collapsed: true)));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(DsIcon).last).dy, below);
    });

    testWidgets('hover shows the label as a tooltip on the end side', (
      tester,
    ) async {
      await tester.pumpWidget(
        DsApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: sidebar(collapsed: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(DsIcon).last));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Tasarım'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Tasarım')).dx,
        greaterThan(tester.getTopRight(rail).dx),
        reason: 'after the rail',
      );
    });

    testWidgets('keyboard focus shows the tooltip; collapsing keeps focus', (
      tester,
    ) async {
      var collapsed = false;
      late StateSetter setCollapsed;
      await tester.pumpWidget(
        DsApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: StatefulBuilder(
              builder: (context, set) {
                setCollapsed = set;
                return sidebar(collapsed: collapsed);
              },
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final focused = FocusManager.instance.primaryFocus;
      expect(focused, isNotNull);
      setCollapsed(() => collapsed = true);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(focused));
      expect(focused!.hasPrimaryFocus, isTrue);
      // Moving on shows the next item's label.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.text('Tasarım'), findsOneWidget);
    });

    testWidgets('collapsedOf tells custom children', (tester) async {
      final seen = <bool>[];
      Widget header() => Builder(
        builder: (context) {
          seen.add(DsSidebar.collapsedOf(context));
          return const SizedBox.shrink();
        },
      );
      await tester.pumpWidget(host(sidebar(header: header())));
      await tester.pumpWidget(host(sidebar(header: header(), collapsed: true)));
      expect(seen.first, isFalse);
      expect(seen.last, isTrue);
    });

    testWidgets('an item without an icon asserts', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            height: 200,
            child: DsSidebar<String>(
              collapsed: true,
              children: [DsSidebarItem(value: 'a', label: Text('A'))],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });
}
