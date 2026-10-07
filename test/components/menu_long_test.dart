import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Long menus and selects build only the rows that show,
/// and still navigate, type ahead, open on their value and announce
/// "k of n".
void main() {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  String label(int i) => '${letters[i % 26]} option $i';

  List<DsSelectOption<int>> options(int n, {String? wide}) => [
    for (var i = 0; i < n; i++)
      DsSelectOption(
        value: i,
        label: wide != null && i == n ~/ 3 ? wide : label(i),
        enabled: i != 3,
      ),
  ];

  Future<void> desk(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1000, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget app(Widget child) => DsApp(
    theme: DsThemeData(platform: TargetPlatform.macOS),
    home: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    ),
  );

  int? chosen;
  Widget select(int n, {int? value, double? width, String? wide}) {
    final s = DsSelect<int>(
      value: value,
      onChanged: (v) => chosen = v,
      semanticLabel: 'Pick',
      options: options(n, wide: wide),
    );
    return width == null ? s : SizedBox(width: width, child: s);
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byType(DsSelect<int>));
    await tester.pumpAndSettle();
  }

  int built() => find.byType(DsMenuItem, skipOffstage: false).evaluate().length;

  /// The label of the item with focus.
  String? focused() {
    final context = FocusManager.instance.primaryFocus?.context;
    final item = context?.findAncestorWidgetOfExactType<DsMenuItem>();
    return switch (item?.label) {
      Text(:final data) => data,
      _ => null,
    };
  }

  /// The menu row labelled [text] (the trigger shows the chosen one too).
  Finder inMenu(String text) =>
      find.descendant(of: find.byType(DsMenu), matching: find.text(text));

  /// Whether the row labelled [text] is on screen and can be hit.
  bool shows(String text) => inMenu(text).hitTestable().evaluate().isNotEmpty;

  Future<void> key(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  setUp(() => chosen = null);

  testWidgets('a 5,000-option select builds about a screenful of rows, the '
      'same as a 500-option one', (tester) async {
    await desk(tester);
    await tester.pumpWidget(app(select(500, value: 250, width: 300)));
    await open(tester);
    final few = built();
    await key(tester, LogicalKeyboardKey.escape);
    await tester.pumpWidget(app(select(5000, value: 2500, width: 300)));
    await open(tester);
    final many = built();
    expect(few, lessThan(80));
    expect(many, few);
    // The window follows the keyboard and stays bounded.
    for (final k in [
      LogicalKeyboardKey.end,
      LogicalKeyboardKey.home,
      LogicalKeyboardKey.arrowUp,
    ]) {
      await key(tester, k);
      expect(built(), lessThanOrEqualTo(few + 2));
    }
  });

  testWidgets('opens on the chosen option, in view and focused', (
    tester,
  ) async {
    await desk(tester);
    await tester.pumpWidget(app(select(5000, value: 4321, width: 300)));
    await open(tester);
    expect(focused(), label(4321));
    expect(shows(label(4321)), isTrue);
    // Near the end the list stops at its end.
    await key(tester, LogicalKeyboardKey.escape);
    await tester.pumpWidget(app(select(5000, value: 4999, width: 300)));
    await open(tester);
    expect(focused(), label(4999));
    expect(shows(label(4999)), isTrue);
  });

  testWidgets('arrow keys, Home and End move through enabled options and '
      'wrap; Enter chooses', (tester) async {
    await desk(tester);
    await tester.pumpWidget(app(select(5000, value: 0, width: 300)));
    await open(tester);
    expect(focused(), label(0));
    await key(tester, LogicalKeyboardKey.arrowDown);
    await key(tester, LogicalKeyboardKey.arrowDown);
    // Option 3 is disabled: it is skipped.
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(), label(4));
    await key(tester, LogicalKeyboardKey.end);
    expect(focused(), label(4999));
    expect(shows(label(4999)), isTrue);
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(), label(0));
    expect(shows(label(0)), isTrue);
    await key(tester, LogicalKeyboardKey.arrowUp);
    expect(focused(), label(4999));
    await key(tester, LogicalKeyboardKey.home);
    expect(focused(), label(0));
    await key(tester, LogicalKeyboardKey.arrowUp);
    await key(tester, LogicalKeyboardKey.arrowUp);
    expect(focused(), label(4998));
    expect(shows(label(4998)), isTrue);
    // Keys faster than frames: each one moves on from the last.
    await key(tester, LogicalKeyboardKey.home);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(focused(), label(4998));
    await key(tester, LogicalKeyboardKey.enter);
    expect(chosen, 4998);
  });

  testWidgets('type-ahead jumps to the next option starting with a letter, '
      'also far below', (tester) async {
    await desk(tester);
    await tester.pumpWidget(app(select(5000, value: 0, width: 300)));
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.pumpAndSettle();
    expect(focused(), label(10));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.pumpAndSettle();
    expect(focused(), label(36));
    // Back past the start: from the end, the next 'a' wraps to the top.
    await key(tester, LogicalKeyboardKey.end);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pumpAndSettle();
    expect(focused(), label(0));
    expect(shows(label(0)), isTrue);
  });

  testWidgets('Tab chooses the focused option', (tester) async {
    await desk(tester);
    await tester.pumpWidget(app(select(5000, value: 10, width: 300)));
    await open(tester);
    await key(tester, LogicalKeyboardKey.arrowDown);
    await key(tester, LogicalKeyboardKey.tab);
    expect(chosen, 11);
    expect(find.byType(DsMenu), findsNothing);
  });

  testWidgets('the menu is as wide as its widest option, even unbuilt', (
    tester,
  ) async {
    await desk(tester);
    const wide =
        'W option with a label that is a good deal longer than the rest';
    await tester.pumpWidget(
      app(select(5000, value: 0, width: 200, wide: wide)),
    );
    await open(tester);
    expect(find.text(wide), findsNothing);
    final menu = tester.getSize(find.byType(DsMenu)).width;
    final painter = TextPainter(
      text: TextSpan(text: wide, style: DsThemeData().typography.body),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(menu, greaterThan(painter.width));
    painter.dispose();
    // Opened on, it shows on one line, whole.
    await key(tester, LogicalKeyboardKey.escape);
    await tester.pumpWidget(
      app(select(5000, value: 5000 ~/ 3, width: 200, wide: wide)),
    );
    await open(tester);
    final shown = tester.renderObject<RenderParagraph>(inMenu(wide));
    expect(shown.didExceedMaxLines, isFalse);
  });

  testWidgets('screen readers hear the count and each built row\'s place', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await desk(tester);
    await tester.pumpWidget(app(select(5000, value: 2500, width: 300)));
    await open(tester);
    final row = tester.getSemantics(inMenu(label(2500)));
    SemanticsNode? node = row;
    int? place;
    int? count;
    while (node != null) {
      place ??= node.indexInParent;
      count ??= node.scrollChildCount;
      node = node.parent;
    }
    expect(place, 2500);
    expect(count, 5000);
    handle.dispose();
  });

  testWidgets('a long DsMenu with dividers and disabled items: rows keep '
      'their heights and the keys skip what cannot be chosen', (tester) async {
    await desk(tester);
    final children = <Widget>[
      for (var i = 0; i < 300; i++) ...[
        if (i > 0 && i % 10 == 0) const DsMenuDivider(),
        DsMenuItem(
          label: Text(label(i)),
          destructive: i % 7 == 0,
          onPressed: i % 5 == 4 ? null : () {},
        ),
      ],
    ];
    final controller = DsOverlayController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(
        DsMenuAnchor(
          controller: controller,
          items: children,
          child: const SizedBox(width: 40, height: 20),
        ),
      ),
    );
    controller.open();
    await tester.pumpAndSettle();
    expect(focused(), label(0));
    expect(built(), lessThan(80));
    await key(tester, LogicalKeyboardKey.end);
    // 299 is enabled (299 % 5 == 4 is disabled: 299 is), so 298.
    expect(focused(), label(298));
    expect(shows(label(298)), isTrue);
    await key(tester, LogicalKeyboardKey.arrowUp);
    expect(focused(), label(297));
    // Rows sit where the model put them: no overlap after the jump.
    final a = tester.getRect(find.text(label(297)));
    final b = tester.getRect(find.text(label(298)));
    expect(b.top, greaterThan(a.bottom));
    await key(tester, LogicalKeyboardKey.home);
    expect(focused(), label(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('at text scale 2 the rows grow to fit one line', (tester) async {
    await desk(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(1000, 700),
          textScaler: TextScaler.linear(2),
        ),
        child: app(select(5000, value: 100, width: 300)),
      ),
    );
    await open(tester);
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(tester.takeException(), isNull);
    final a = tester.getRect(inMenu(label(100)));
    final b = tester.getRect(inMenu(label(101)));
    expect(b.top, greaterThanOrEqualTo(a.bottom));
    final row = tester.renderObject<RenderParagraph>(inMenu(label(101)));
    expect(row.didExceedMaxLines, isFalse);
    expect(row.size.height, greaterThan(30));
  });

  testWidgets('rows are as tall as a leading taller than the text', (
    tester,
  ) async {
    await desk(tester);
    await tester.pumpWidget(
      app(
        SizedBox(
          width: 300,
          child: DsSelect<int>(
            value: 0,
            onChanged: (v) => chosen = v,
            semanticLabel: 'Pick',
            options: [
              for (var i = 0; i < 300; i++)
                DsSelectOption(
                  value: i,
                  label: label(i),
                  leading: const DsAvatar(initials: 'AB', size: DsSize.lg),
                ),
            ],
          ),
        ),
      ),
    );
    await open(tester);
    Finder avatar(int i) => find.descendant(
      of: find.ancestor(
        of: inMenu(label(i)),
        matching: find.byType(DsMenuItem),
      ),
      matching: find.byType(DsAvatar),
    );
    final size = tester.getSize(avatar(3));
    expect(size.height, size.width, reason: 'not squashed');
    expect(
      tester.getRect(avatar(4)).top,
      greaterThan(tester.getRect(avatar(3)).bottom),
    );
    // The model's offsets match: End reaches the last row, in view.
    await key(tester, LogicalKeyboardKey.end);
    expect(focused(), label(299));
    expect(shows(label(299)), isTrue);
    expect(tester.getSize(avatar(299)), size);
  });

  testWidgets('a menu that grows past the long-menu size, or shrinks back, '
      'keeps the item with focus', (tester) async {
    await desk(tester);
    var n = 3;
    late StateSetter set;
    final pressed = <int>[];
    final controller = DsOverlayController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return DsMenuAnchor(
              controller: controller,
              items: [
                for (var i = 0; i < n; i++)
                  DsMenuItem(
                    label: Text(label(i)),
                    onPressed: () => pressed.add(i),
                  ),
              ],
              child: const SizedBox(width: 40, height: 20),
            );
          },
        ),
      ),
    );
    controller.open();
    await tester.pumpAndSettle();
    await key(tester, LogicalKeyboardKey.arrowDown);
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(), label(2));
    set(() => n = 150); // more items arrive: the menu turns long
    await tester.pumpAndSettle();
    expect(focused(), label(2));
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(), label(3));
    set(() => n = 50);
    await tester.pumpAndSettle();
    expect(focused(), label(3));
    await key(tester, LogicalKeyboardKey.arrowDown);
    await key(tester, LogicalKeyboardKey.enter);
    expect(pressed, [4]);
  });

  group('relative budgets: a 5,000-option select costs about what a short '
      'one does', () {
    Future<(int, int)> measure(WidgetTester tester, int n) async {
      await tester.pumpWidget(app(select(n, value: n ~/ 2, width: 300)));
      await tester.pumpAndSettle();
      final watch = Stopwatch()..start();
      await tester.tap(find.byType(DsSelect<int>));
      await tester.pump();
      await tester.pump();
      final opening = watch.elapsedMicroseconds;
      await tester.pumpAndSettle();
      watch.reset();
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
      }
      final arrows = watch.elapsedMicroseconds ~/ 5;
      await key(tester, LogicalKeyboardKey.escape);
      return (opening, arrows);
    }

    testWidgets('opening and arrow keys', (tester) async {
      await desk(tester);
      // Warm up, then take the best of three of each.
      await measure(tester, 40);
      final small = [for (var i = 0; i < 3; i++) await measure(tester, 40)];
      final large = [for (var i = 0; i < 3; i++) await measure(tester, 5000)];
      int best(List<(int, int)> runs, int Function((int, int)) pick) =>
          runs.map(pick).reduce((a, b) => a < b ? a : b);
      final open40 = best(small, (r) => r.$1);
      final open5k = best(large, (r) => r.$1);
      final arrow40 = best(small, (r) => r.$2);
      final arrow5k = best(large, (r) => r.$2);
      // Before: opening took 35x as long and an arrow key 14x.
      expect(
        open5k,
        lessThan(open40 * 4 + 40000),
        reason: '$open5k vs $open40',
      );
      expect(
        arrow5k,
        lessThan(arrow40 * 4 + 10000),
        reason: '$arrow5k vs $arrow40',
      );
    });

    testWidgets('hovering an unbounded select does not measure its labels '
        'again', (tester) async {
      await desk(tester);
      Future<int> hover(int n) async {
        await tester.pumpWidget(
          app(DsSelect<int>(value: 1, onChanged: (_) {}, options: options(n))),
        );
        await tester.pumpAndSettle();
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(900, 600));
        await tester.pump();
        final watch = Stopwatch()..start();
        for (var i = 0; i < 6; i++) {
          await mouse.moveTo(
            i.isEven
                ? tester.getCenter(find.byType(DsSelect<int>))
                : const Offset(900, 600),
          );
          await tester.pump();
        }
        await mouse.removePointer();
        return watch.elapsedMicroseconds ~/ 6;
      }

      await hover(10);
      final short = await hover(10);
      final long = await hover(5000);
      // Before: ~90 ms per hover at 5,000 options against ~1 ms.
      expect(long, lessThan(short * 4 + 10000), reason: '$long vs $short');
    });
  });
}
