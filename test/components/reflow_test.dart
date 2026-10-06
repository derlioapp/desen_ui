import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Reflow at 320px and 2.0x text: list rows wrap
/// before they cut, choice labels break only between words, and labels
/// that ellipsize keep their whole text for screen readers.
void main() {
  const long =
      'Internationalisation configuration settings for the organisation';
  // About two lines of a list row's title at 320px.
  const title = 'Bildirim tercihleri ve haftalık e-posta özetleri';

  Future<void> narrow(WidgetTester tester, Widget child, double scale) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        theme: DsThemeData(density: DsDensity.compact),
        textScale: scale,
        SizedBox(width: 304, child: child),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  RenderParagraph paragraphOf(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      );

  int lines(RenderParagraph p) => p
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: p.text.toPlainText().length),
      )
      .map((b) => b.top.round())
      .toSet()
      .length;

  /// Offsets where a line ends in the middle of a word.
  List<int> midWordBreaks(RenderParagraph p) {
    final text = p.text.toPlainText();
    // Characters cut by an ellipsis have no box.
    double? top(int i) => p
        .getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))
        .firstOrNull
        ?.top;
    bool breakable(String c) => c == ' ' || c == '-';
    return [
      for (var i = 0; i + 1 < text.length; i++)
        if (top(i) != null &&
            top(i + 1) != null &&
            top(i + 1)! > top(i)! + 1 &&
            !breakable(text[i]) &&
            !breakable(text[i + 1]))
          i,
    ];
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('list row title wraps to two lines before it cuts @$scale', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await narrow(
        tester,
        DsListSection(
          children: [
            DsListRow(
              title: const Text(title),
              detail: const Text('Enabled'),
              showChevron: true,
              onPressed: () {},
            ),
          ],
        ),
        scale,
      );
      final p = paragraphOf(tester, title);
      expect(lines(p), 2);
      if (scale == 1) expect(p.didExceedMaxLines, isFalse);
      expect(midWordBreaks(p), isEmpty);
      expect(
        tester.getSemantics(find.byType(DsListRow)).label,
        contains(title),
      );
      handle.dispose();
    });

    testWidgets('checkbox, radio and switch labels break between words '
        '@$scale', (tester) async {
      const label = 'Bahsedilince bildir, sonradan değiştirebilirsiniz';
      await narrow(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DsCheckbox(
              value: true,
              onChanged: (_) {},
              label: const Text('$label a'),
            ),
            DsRadioGroup<int>(
              value: 1,
              onChanged: (_) {},
              child: const DsRadio(value: 1, label: Text('$label b')),
            ),
            DsSwitch(
              value: true,
              onChanged: (_) {},
              label: const Text('$label c'),
              description: const Text('$label d'),
            ),
          ],
        ),
        scale,
      );
      for (final suffix in ['a', 'b', 'c', 'd']) {
        final p = paragraphOf(tester, '$label $suffix');
        expect(p.didExceedMaxLines, isFalse, reason: suffix);
        expect(midWordBreaks(p), isEmpty, reason: suffix);
        if (scale == 2) expect(lines(p), greaterThan(1), reason: suffix);
      }
    });

    testWidgets('ellipsized chip, segment and bottom nav labels keep their '
        'whole text for screen readers @$scale', (tester) async {
      final handle = tester.ensureSemantics();
      await narrow(
        tester,
        Column(
          children: [
            DsChip(label: const Text(long), selected: true, onChanged: (_) {}),
            DsSegmentedControl<int>(
              value: 0,
              onChanged: (_) {},
              segments: const [
                DsSegment(value: 0, label: Text('Notifications')),
                DsSegment(value: 1, label: Text('Messages')),
                DsSegment(value: 2, label: Text('Configuration')),
              ],
            ),
            DsBottomNav(
              value: 0,
              onChanged: (_) {},
              items: const [
                DsBottomNavItem(
                  value: 0,
                  icon: DsIcon(DsIcons.check),
                  label: Text('Home'),
                ),
                DsBottomNavItem(
                  value: 1,
                  icon: DsIcon(DsIcons.x),
                  label: Text('Notifications'),
                ),
                DsBottomNavItem(
                  value: 2,
                  icon: DsIcon(DsIcons.x),
                  label: Text('Messages'),
                ),
                DsBottomNavItem(
                  value: 3,
                  icon: DsIcon(DsIcons.x),
                  label: Text('Profile'),
                ),
              ],
            ),
          ],
        ),
        scale,
      );
      for (final text in [long, 'Notifications', 'Configuration', 'Messages']) {
        for (final element in find.text(text).evaluate()) {
          expect(
            tester.getSemantics(find.byWidget(element.widget).first).label,
            contains(text),
            reason: text,
          );
        }
      }
      handle.dispose();
    });
  }
}
