import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A checkbox, radio or switch beside a label of several lines sits on the
/// label's first line, as on the web (the control centered on the first
/// line box), not between the lines.
void main() {
  const title = 'Standard · Free';
  const detail = '3 to 5 business days';
  Widget twoLines() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [Text(title), Text(detail)],
  );

  /// The control's visible box: the first sized box under [type].
  Rect control(WidgetTester tester, Type type, double size) {
    final boxes = find.descendant(
      of: find.byType(type),
      matching: find.byWidgetPredicate(
        (w) => w is AnimatedContainer && w.constraints?.maxHeight == size,
      ),
    );
    return tester.getRect(boxes.first);
  }

  for (final textScale in [1.0, 2.0]) {
    testWidgets('checkbox and radio (text scale $textScale)', (tester) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        host(
          textScale: textScale,
          theme: theme,
          DsRadioGroup<String>(
            value: 'a',
            onChanged: (_) {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsCheckbox(value: true, onChanged: (_) {}, label: twoLines()),
                DsRadio<String>(value: 'a', label: twoLines()),
              ],
            ),
          ),
        ),
      );
      final first = find.text(title);
      for (final (i, type, size) in [
        (0, DsCheckbox, DsCheckbox.defaultStyle(theme).size!),
        (1, DsRadio<String>, DsRadio.defaultStyle(theme).size!),
      ]) {
        final line = tester.getRect(first.at(i));
        final box = control(tester, type, size);
        expect(
          box.center.dy,
          moreOrLessEquals(line.center.dy, epsilon: .5),
          reason: '$type sits on the first line',
        );
      }
    });
  }

  testWidgets('a single line stays centered', (tester) async {
    final theme = DsThemeData();
    await tester.pumpWidget(
      host(
        theme: theme,
        DsCheckbox(value: true, onChanged: (_) {}, label: const Text(title)),
      ),
    );
    final box = control(
      tester,
      DsCheckbox,
      DsCheckbox.defaultStyle(theme).size!,
    );
    expect(
      box.center.dy,
      moreOrLessEquals(tester.getRect(find.text(title)).center.dy, epsilon: .5),
    );
  });

  testWidgets('switch with a description sits on the label line', (
    tester,
  ) async {
    final theme = DsThemeData();
    await tester.pumpWidget(
      host(
        theme: theme,
        SizedBox(
          width: 320,
          child: DsSwitch(
            value: true,
            onChanged: (_) {},
            label: const Text(title),
            description: const Text(detail),
          ),
        ),
      ),
    );
    final height = DsSwitch.defaultStyle(theme).height!;
    final track = control(tester, DsSwitch, height);
    final line = tester.getRect(find.text(title));
    expect(track.center.dy, moreOrLessEquals(line.center.dy, epsilon: .5));
  });
}
