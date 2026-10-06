import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final theme = DsThemeData();

  // A one-pixel divider is a DsLine (a device-pixel hairline); a thicker
  // one a ColoredBox.
  Finder line() => find.byType(DsLine).evaluate().isNotEmpty
      ? find.byType(DsLine).last
      : find.byType(ColoredBox).last;

  Rect lineRect(WidgetTester tester) => tester.getRect(line());

  Color lineColor(WidgetTester tester) => switch (tester.widget(line())) {
    final DsLine l => l.color,
    final ColoredBox b => b.color,
    _ => throw StateError('no line'),
  };

  testWidgets('horizontal: the full width, one pixel, the border color', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(theme: theme, const SizedBox(width: 200, child: DsDivider())),
    );
    final r = lineRect(tester);
    expect(r.size, const Size(200, 1));
    expect(lineColor(tester), theme.colors.border);
    expect(tester.getSize(find.byType(DsDivider)), const Size(200, 1));
  });

  testWidgets('vertical: the full height it is given', (tester) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        const SizedBox(height: 40, child: DsDivider.vertical()),
      ),
    );
    expect(lineRect(tester).size, const Size(1, 40));
  });

  testWidgets('a vertical divider in an IntrinsicHeight row takes its height', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        const IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 20, height: 24),
              DsDivider.vertical(),
              SizedBox(width: 20, height: 24),
            ],
          ),
        ),
      ),
    );
    expect(lineRect(tester).size, const Size(1, 24));
  });

  testWidgets('without a bound along the line it takes no length', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [DsDivider(), SizedBox(width: 10, height: 10)],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(DsDivider)), const Size(0, 1));
  });

  testWidgets('a horizontal divider keeps its thickness in a column', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        const SizedBox(
          width: 100,
          child: SingleChildScrollView(child: Column(children: [DsDivider()])),
        ),
      ),
    );
    expect(lineRect(tester).size, const Size(100, 1));
  });

  testWidgets('indents follow the text direction', (tester) async {
    Future<Rect> rect(TextDirection direction) async {
      await tester.pumpWidget(
        host(
          theme: theme,
          direction: direction,
          const SizedBox(
            width: 200,
            child: DsDivider(indent: 16, endIndent: 4),
          ),
        ),
      );
      final box = tester.getRect(find.byType(DsDivider));
      return lineRect(tester).shift(-box.topLeft);
    }

    expect(await rect(TextDirection.ltr), const Rect.fromLTWH(16, 0, 180, 1));
    expect(await rect(TextDirection.rtl), const Rect.fromLTWH(4, 0, 180, 1));
  });

  testWidgets('vertical indents are at the top and bottom', (tester) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        const SizedBox(
          height: 40,
          child: DsDivider.vertical(indent: 8, endIndent: 6),
        ),
      ),
    );
    final box = tester.getRect(find.byType(DsDivider));
    expect(
      lineRect(tester).shift(-box.topLeft),
      const Rect.fromLTWH(0, 8, 1, 26),
    );
  });

  testWidgets('style and theme layers: widget indent > style > theme', (
    tester,
  ) async {
    const red = Color(0xFFFF0000);
    const blue = Color(0xFF0000FF);
    await tester.pumpWidget(
      host(
        theme: theme,
        const DsDividerTheme(
          data: DsDividerThemeData(
            style: DsDividerStyle(thickness: 2, color: red, indent: 10),
          ),
          child: SizedBox(
            width: 200,
            child: Column(
              children: [
                DsDivider(),
                DsDivider(style: DsDividerStyle(color: blue, indent: 20)),
                DsDivider(indent: 30, style: DsDividerStyle(indent: 20)),
              ],
            ),
          ),
        ),
      ),
    );
    final lines = find.byType(ColoredBox);
    final boxes = find.byType(DsDivider);
    Rect at(int i) =>
        tester.getRect(lines.at(i)).shift(-tester.getRect(boxes.at(i)).topLeft);
    expect(at(0), const Rect.fromLTWH(10, 0, 190, 2));
    expect(tester.widget<ColoredBox>(lines.at(0)).color, red);
    expect(at(1), const Rect.fromLTWH(20, 0, 180, 2));
    expect(tester.widget<ColoredBox>(lines.at(1)).color, blue);
    expect(at(2).left, 30);
  });

  testWidgets('decorative: no semantics node', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(theme: theme, const SizedBox(width: 200, child: DsDivider())),
    );
    // The nearest node is the view's root, with nothing in it.
    final node = tester.getSemantics(find.byType(DsDivider));
    expect(node.isMergedIntoParent, isFalse);
    expect(node.childrenCount, 0);
    expect(node.label, isEmpty);
    expect(node.rect.size, isNot(tester.getSize(find.byType(DsDivider))));
    handle.dispose();
  });

  test('styles compare by value', () {
    expect(
      const DsDividerStyle(thickness: 1, color: Color(0xFF000000)),
      const DsDividerStyle(thickness: 1, color: Color(0xFF000000)),
    );
    expect(
      const DsDividerStyle(indent: 1).merge(const DsDividerStyle(endIndent: 2)),
      const DsDividerStyle(indent: 1, endIndent: 2),
    );
  });
}
