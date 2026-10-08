import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsSectionIndex: a letter column beside a sorted list; tap or drag to
/// jump, keys and screen readers step through the sections.
void main() {
  const letters = ['A', 'B', 'C', 'Ç', 'D', 'E', 'İ', 'I', 'K', 'Ş', 'Z'];

  /// A column [height] tall in an app with an [Overlay], keeping its own
  /// value and reporting each jump to [seen].
  Widget index({
    List<String>? seen,
    String? initial,
    double? height = 400,
    bool enabled = true,
    FocusNode? node,
    DsThemeData? theme,
    DsSectionIndexStyle? style,
    List<String> sections = letters,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
  }) {
    var value = initial;
    Widget column = StatefulBuilder(
      builder: (context, set) => DsSectionIndex(
        sections: sections,
        value: value,
        focusNode: node,
        style: style,
        onChanged: enabled
            ? (v) => set(() {
                value = v;
                seen?.add(v);
              })
            : null,
      ),
    );
    if (height != null) column = SizedBox(height: height, child: column);
    return host(
      Overlay(
        initialEntries: [
          OverlayEntry(builder: (context) => Center(child: column)),
        ],
      ),
      theme: theme,
      direction: direction,
      textScale: textScale,
    );
  }

  Finder column() => find.byType(DsSectionIndex);

  /// The middle of the visible letter [l].
  Offset letter(WidgetTester tester, String l) => tester.getCenter(
    // The first: the bubble, when it shows, is built under the column too.
    find.descendant(of: column(), matching: find.text(l)).first,
  );

  /// The bubble's text, if it shows.
  Finder bubble(String l) =>
      find.descendant(of: find.byType(Overlay), matching: find.text(l));

  SemanticsNode node(WidgetTester tester) =>
      tester.getSemantics(find.byType(DsSectionIndex));

  testWidgets('a tap jumps to the letter, also to the current one', (
    tester,
  ) async {
    final seen = <String>[];
    await tester.pumpWidget(index(seen: seen));
    await tester.tapAt(letter(tester, 'Ç'));
    await tester.pump();
    expect(seen, ['Ç']);
    await tester.tapAt(letter(tester, 'Ç'));
    await tester.pump();
    expect(seen, ['Ç', 'Ç']);
  });

  testWidgets('a drag reports each section it crosses once, in order', (
    tester,
  ) async {
    final seen = <String>[];
    await tester.pumpWidget(index(seen: seen));
    final top = letter(tester, 'A'), bottom = letter(tester, 'Z');
    final g = await tester.startGesture(top);
    for (var y = top.dy; y <= bottom.dy; y += 4) {
      await g.moveTo(Offset(top.dx, y));
      await tester.pump();
    }
    await g.up();
    expect(seen, letters);
  });

  testWidgets('the bubble shows the section under the finger while it is '
      'down, on the side facing the list', (tester) async {
    await tester.pumpWidget(index());
    expect(bubble('K'), findsOneWidget); // The letter only.
    final g = await tester.startGesture(letter(tester, 'K'));
    await tester.pump();
    // The letter in the column, and the bubble.
    expect(bubble('K'), findsNWidgets(2));
    final bar = tester.getRect(column());
    final shown = tester.getRect(bubble('K').last);
    expect(shown.right, lessThan(bar.left));

    await g.moveTo(letter(tester, 'Ş'));
    await tester.pump();
    expect(bubble('Ş'), findsNWidgets(2));
    expect(bubble('K'), findsOneWidget);

    await g.up();
    await tester.pump();
    expect(bubble('Ş'), findsOneWidget);
  });

  testWidgets('in right-to-left layouts the bubble is on the right', (
    tester,
  ) async {
    await tester.pumpWidget(index(direction: TextDirection.rtl));
    final g = await tester.startGesture(letter(tester, 'K'));
    await tester.pump();
    final bar = tester.getRect(column());
    expect(tester.getRect(bubble('K').last).left, greaterThan(bar.right));
    await g.up();
  });

  testWidgets('works without an Overlay: no bubble, still jumps', (
    tester,
  ) async {
    final seen = <String>[];
    await tester.pumpWidget(
      host(
        SizedBox(
          height: 400,
          child: DsSectionIndex(
            sections: letters,
            value: null,
            onChanged: seen.add,
          ),
        ),
      ),
    );
    await tester.tapAt(letter(tester, 'D'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(seen, ['D']);
  });

  testWidgets('a touch ticks once per section; keys are silent', (
    tester,
  ) async {
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
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      index(
        node: node,
        theme: DsThemeData(platform: TargetPlatform.iOS),
      ),
    );
    final g = await tester.startGesture(letter(tester, 'A'));
    await tester.pump();
    await g.moveTo(letter(tester, 'A') + const Offset(0, 2));
    await tester.pump();
    await g.moveTo(letter(tester, 'C'));
    await tester.pump();
    await g.up();
    // A on touch, then C when the finger reaches it; not again within A.
    expect(calls, List.filled(2, 'HapticFeedbackType.selectionClick'));

    calls.clear();
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(calls, isEmpty);
  });

  group('keyboard', () {
    testWidgets('Up, Down, Home and End move through the sections', (
      tester,
    ) async {
      final seen = <String>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(index(seen: seen, node: node));
      node.requestFocus();
      await tester.pump();
      // From none, Down starts at the first.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      // Held at the end.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(seen, ['A', 'B', 'A', 'Z', 'A']);
    });

    testWidgets('typing a letter jumps to it, Turkish dotted and dotless i '
        'apart', (tester) async {
      final seen = <String>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(index(seen: seen, node: node));
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK, character: 'k');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyI, character: 'i');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyI, character: 'ı');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS, character: 'ş');
      await tester.pump();
      expect(seen, ['K', 'İ', 'I', 'Ş']);
    });
  });

  group('semantics', () {
    testWidgets('one adjustable control named in the app language', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(index(initial: 'C'));
      expect(
        node(tester),
        isSemantics(
          isSlider: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          label: 'Section index',
          value: 'C',
          increasedValue: 'Ç',
          decreasedValue: 'B',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('increase and decrease jump to the next and previous', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <String>[];
      await tester.pumpWidget(index(seen: seen, initial: 'C'));
      final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
      owner.performAction(node(tester).id, SemanticsAction.increase);
      await tester.pump();
      owner.performAction(node(tester).id, SemanticsAction.increase);
      await tester.pump();
      owner.performAction(node(tester).id, SemanticsAction.decrease);
      await tester.pump();
      expect(seen, ['Ç', 'D', 'Ç']);
      expect(node(tester).value, 'Ç');
      handle.dispose();
    });

    testWidgets('with no current section it still starts at an end', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <String>[];
      await tester.pumpWidget(index(seen: seen));
      expect(tester.takeException(), isNull);
      tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
        node(tester).id,
        SemanticsAction.increase,
      );
      await tester.pump();
      expect(seen, ['A']);
      handle.dispose();
    });

    testWidgets('the letters are not read one by one', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(index(initial: 'C'));
      expect(find.semantics.byLabel('K'), findsNothing);
      handle.dispose();
    });
  });

  testWidgets('a null onChanged disables it: no jumps, no focus, no actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(index(enabled: false, node: node));
    await tester.tapAt(letter(tester, 'C'));
    await tester.pump();
    expect(bubble('C'), findsOneWidget);
    node.requestFocus();
    await tester.pump();
    expect(node.hasPrimaryFocus, isFalse);
    expect(
      node.context == null ? null : tester.getSemantics(column()),
      isSemantics(
        isSlider: true,
        hasEnabledState: true,
        isEnabled: false,
        label: 'Section index',
      ),
    );
    handle.dispose();
  });

  testWidgets('a column too short for its letters shows dots, and a drag '
      'still reaches every section', (tester) async {
    final seen = <String>[];
    const many = [
      'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H', 'I', 'İ', 'J', 'K', //
      'L', 'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', //
      'Z',
    ];
    await tester.pumpWidget(index(seen: seen, height: 160, sections: many));
    expect(tester.takeException(), isNull);
    // The ends stay, some letters give way.
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Z'), findsOneWidget);
    expect(find.text('Ğ'), findsNothing);
    final bar = tester.getRect(column());
    final g = await tester.startGesture(bar.topCenter + const Offset(0, 1));
    for (var y = bar.top + 1; y < bar.bottom; y += 1) {
      await g.moveTo(Offset(bar.center.dx, y));
      await tester.pump();
    }
    await g.up();
    expect(seen, many);
  });

  testWidgets('marks the current section with the selection style', (
    tester,
  ) async {
    final theme = DsThemeData();
    await tester.pumpWidget(index(initial: 'K', theme: theme));
    Color? fill(String l) => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.ancestor(of: find.text(l), matching: find.byType(Stack)),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((b) => (b.decoration as BoxDecoration).color)
        .first;
    expect(fill('K'), theme.colors.selection);
    expect(fill('C'), const Color(0x00000000));
  });

  testWidgets('style, the theme and a subtree theme apply', (tester) async {
    Color? colorOf(String l) => tester.widget<Text>(find.text(l)).style?.color;
    const red = Color(0xFFFF0000), green = Color(0xFF00FF00);
    await tester.pumpWidget(
      index(style: const DsSectionIndexStyle(color: red)),
    );
    expect(colorOf('C'), red);
    await tester.pumpWidget(
      DsSectionIndexTheme(
        data: const DsSectionIndexThemeData(
          style: DsSectionIndexStyle(color: green),
        ),
        child: index(),
      ),
    );
    expect(colorOf('C'), green);
  });

  testWidgets('sizes to its letters under an unbounded height, grows with '
      'the text and keeps a touch-sized width', (tester) async {
    await tester.pumpWidget(
      index(
        height: null,
        textScale: 2,
        theme: DsThemeData(platform: TargetPlatform.iOS),
      ),
    );
    expect(tester.takeException(), isNull);
    final bar = tester.getRect(column());
    expect(bar.width, greaterThanOrEqualTo(44));
    // Every letter shows, each row twice the 16px of text scale 1.
    for (final l in letters) {
      expect(find.text(l), findsOneWidget);
    }
    expect(bar.height, greaterThanOrEqualTo(letters.length * 32));
  });

  testWidgets('works without a DsScope and with no sections', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 200,
            child: DsSectionIndex(sections: [], value: null, onChanged: null),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
