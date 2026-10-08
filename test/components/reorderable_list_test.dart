import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsReorderableList: items moved by their handle, a long press on touch
/// screens, the keyboard and screen reader actions; the app owns the
/// order.
void main() {
  const initial = ['A', 'B', 'C', 'D', 'E'];

  /// A list that keeps its own order in [items], each move reported to
  /// [moves].
  Widget list({
    required List<String> items,
    List<(int, int)>? moves,
    bool enabled = true,
    DsThemeData? theme,
    DsReorderableListStyle? style,
    bool pressableRows = false,
    TextDirection direction = TextDirection.ltr,
  }) => host(
    Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => StatefulBuilder(
            builder: (context, set) => DsReorderableList(
              itemCount: items.length,
              style: style,
              itemBuilder: (context, i) => DsListRow(
                key: ValueKey(items[i]),
                title: Text(items[i]),
                onPressed: pressableRows ? () {} : null,
              ),
              onReorder: enabled
                  ? (from, to) => set(() {
                      moves?.add((from, to));
                      items.insert(to, items.removeAt(from));
                    })
                  : null,
            ),
          ),
        ),
      ],
    ),
    theme: theme,
    direction: direction,
  );

  Finder handles() => find.byWidgetPredicate(
    (w) => w is DsIcon && w.icon == DsIcons.gripVertical,
  );

  /// The handle beside item [label]: the one on its line.
  Finder handleOf(WidgetTester tester, String label) {
    final y = tester.getCenter(find.text(label)).dy;
    final all = handles().evaluate().toList();
    final i = all.indexWhere(
      (e) => (tester.getCenter(find.byWidget(e.widget)).dy - y).abs() < 1,
    );
    return handles().at(i);
  }

  /// Drags item [label]'s handle by [dy], in small steps as a hand does.
  Future<void> drag(WidgetTester tester, Finder from, double dy) async {
    final g = await tester.startGesture(tester.getCenter(from));
    await tester.pump(const Duration(milliseconds: 600));
    const steps = 10;
    for (var i = 0; i < steps; i++) {
      await g.moveBy(Offset(0, dy / steps));
      await tester.pump();
    }
    await g.up();
    await tester.pumpAndSettle();
  }

  /// The row height, to drag by whole rows.
  double rowHeight(WidgetTester tester) =>
      tester.getCenter(find.text('B')).dy - tester.getCenter(find.text('A')).dy;

  testWidgets('dragging a handle moves its item; the index counts after the '
      'move', (tester) async {
    final items = [...initial], moves = <(int, int)>[];
    await tester.pumpWidget(list(items: items, moves: moves));
    await drag(tester, handleOf(tester, 'B'), rowHeight(tester) * 2.2);
    expect(moves, [(1, 3)]);
    expect(items, ['A', 'C', 'D', 'B', 'E']);
  });

  testWidgets('a long press lifts an item on touch screens only', (
    tester,
  ) async {
    final items = [...initial], moves = <(int, int)>[];
    await tester.pumpWidget(
      list(
        items: items,
        moves: moves,
        theme: DsThemeData(platform: TargetPlatform.macOS),
      ),
    );
    await drag(tester, find.text('A'), rowHeight(tester) * 1.5);
    expect(moves, isEmpty);

    await tester.pumpWidget(
      list(
        items: items,
        moves: moves,
        theme: DsThemeData(platform: TargetPlatform.iOS),
      ),
    );
    await drag(tester, find.text('A'), rowHeight(tester));
    expect(moves, [(0, 1)]);
  });

  testWidgets('a lift and a drop each tick', (tester) async {
    final calls = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      list(
        items: [...initial],
        theme: DsThemeData(platform: TargetPlatform.iOS),
      ),
    );
    await drag(tester, handleOf(tester, 'B'), rowHeight(tester));
    expect(calls, List.filled(2, 'HapticFeedbackType.selectionClick'));
  });

  group('keyboard', () {
    /// Focuses item [label]'s handle from the keyboard.
    Future<void> focusHandle(WidgetTester tester, String label) async {
      final node = Focus.of(tester.element(handleOf(tester, label)));
      node.requestFocus();
      await tester.pump();
    }

    bool handleFocused(WidgetTester tester, String label) =>
        Focus.of(tester.element(handleOf(tester, label))).hasPrimaryFocus;

    testWidgets('arrows, Home and End on a handle move its item, and focus '
        'stays on it', (tester) async {
      final items = [...initial], moves = <(int, int)>[];
      await tester.pumpWidget(list(items: items, moves: moves));
      await focusHandle(tester, 'B');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(items, ['A', 'C', 'B', 'D', 'E']);
      expect(handleFocused(tester, 'B'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(items.last, 'B');
      expect(handleFocused(tester, 'B'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      // Held at the start.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(items, ['B', 'A', 'C', 'D', 'E']);
      expect(moves, [(1, 2), (2, 4), (4, 0)]);
    });

    testWidgets('Alt+arrows move the item from a focused row inside it', (
      tester,
    ) async {
      final items = [...initial];
      await tester.pumpWidget(list(items: items, pressableRows: true));
      final row = find.ancestor(
        of: find.text('C'),
        matching: find.byType(DsListRow),
      );
      Focus.of(
        tester.element(
          find.descendant(of: row, matching: find.byType(Text)).first,
        ),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(items, ['A', 'C', 'B', 'D', 'E']);
    });
  });

  group('screen readers', () {
    List<String> actionsOf(WidgetTester tester, String label) {
      final node = tester.getSemantics(
        find
            .ancestor(of: find.text(label), matching: find.byType(Semantics))
            .first,
      );
      var n = node;
      // The item container that holds the move actions.
      while (n.getSemanticsData().customSemanticsActionIds?.isEmpty ?? true) {
        n = n.parent!;
      }
      return [
        for (final id in n.getSemanticsData().customSemanticsActionIds!)
          CustomSemanticsAction.getAction(id)!.label!,
      ];
    }

    testWidgets('each item has the move actions, in the app language', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        DsApp(
          locale: const Locale('tr'),
          home: StatefulBuilder(
            builder: (context, set) {
              final items = [...initial];
              return DsReorderableList(
                itemCount: items.length,
                itemBuilder: (context, i) =>
                    DsListRow(key: ValueKey(items[i]), title: Text(items[i])),
                onReorder: (_, _) {},
              );
            },
          ),
        ),
      );
      expect(
        actionsOf(tester, 'C'),
        containsAll(['Başa taşı', 'Yukarı taşı', 'Aşağı taşı', 'Sona taşı']),
      );
      expect(actionsOf(tester, 'A'), isNot(contains('Yukarı taşı')));
      handle.dispose();
    });

    testWidgets('the handle is not announced', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(list(items: [...initial]));
      expect(
        find.descendant(
          of: find.ancestor(
            of: handles().first,
            matching: find.byType(ExcludeSemantics),
          ),
          matching: handles().first,
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  testWidgets('without onReorder: a plain list, no handles', (tester) async {
    await tester.pumpWidget(list(items: [...initial], enabled: false));
    expect(find.text('C'), findsOneWidget);
    expect(handles(), findsNothing);
    expect(find.byType(ReorderableList), findsNothing);
  });

  testWidgets('works without an app root, keeping the direction', (
    tester,
  ) async {
    await tester.pumpWidget(
      list(items: [...initial], direction: TextDirection.rtl),
    );
    expect(tester.takeException(), isNull);
    // The handle sits at the end: the left in right-to-left text.
    expect(
      tester.getCenter(handleOf(tester, 'A')).dx,
      lessThan(tester.getCenter(find.text('A')).dx),
    );
  });

  testWidgets('style and theme set the handle color', (tester) async {
    const red = Color(0xFFFF0000);
    await tester.pumpWidget(
      list(
        items: [...initial],
        style: const DsReorderableListStyle(handleColor: red),
      ),
    );
    expect(tester.widget<DsIcon>(handles().first).color, red);
  });

  testWidgets('every item needs a key', (tester) async {
    await tester.pumpWidget(
      host(
        Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => DsReorderableList(
                itemCount: 1,
                itemBuilder: (context, i) => const Text('no key'),
                onReorder: (_, _) {},
              ),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });
}
