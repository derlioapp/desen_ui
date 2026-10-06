import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// An inline link keeps the paragraph's line height (WCAG 2.5.8 exempts
/// targets in a sentence); a standalone one grows to the tap target.
void main() {
  Future<double> paragraphHeight(
    WidgetTester tester, {
    required bool inline,
  }) async {
    final theme = DsThemeData(platform: TargetPlatform.macOS);
    await tester.pumpWidget(
      DsApp(
        theme: theme,
        home: Center(
          child: SizedBox(
            width: 400,
            child: Text.rich(
              TextSpan(
                style: theme.typography.body,
                children: [
                  const TextSpan(text: 'Read the '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: DsLink(
                      label: 'guide',
                      inline: inline,
                      onPressed: () {},
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              key: const Key('p'),
            ),
          ),
        ),
      ),
    );
    return tester.getSize(find.byKey(const Key('p'))).height;
  }

  testWidgets('inline links keep the line height', (tester) async {
    final theme = DsThemeData(platform: TargetPlatform.macOS);
    final line = (TextPainter(
      text: TextSpan(text: 'Read', style: theme.typography.body),
      textDirection: TextDirection.ltr,
    )..layout()).height;
    expect(await paragraphHeight(tester, inline: true), line);
    expect(
      await paragraphHeight(tester, inline: false),
      greaterThan(line),
      reason: 'a standalone link grows to the 24px target',
    );
  });

  testWidgets('Enter activates a link; Space does not, as in browsers', (
    tester,
  ) async {
    for (final own in [false, true]) {
      final node = own ? FocusNode() : null;
      var taps = 0;
      var outer = 0;
      await tester.pumpWidget(
        DsApp(
          home: Focus(
            // Space must not leak to an ancestor that would act on it.
            onKeyEvent: (_, e) {
              if (e.logicalKey == LogicalKeyboardKey.space) outer++;
              return KeyEventResult.ignored;
            },
            child: Center(
              child: DsLink(
                label: 'guide',
                focusNode: node,
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      );
      Focus.of(tester.element(find.text('guide'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(taps, 0, reason: own ? 'own node' : 'default node');
      expect(outer, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
      await tester.pumpWidget(const SizedBox());
      node?.dispose();
    }
  });
}
