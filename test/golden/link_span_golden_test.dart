@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Links inside a paragraph, in light and dark: at rest, hovered, focused
/// from the keyboard (a ring around each line of the label) and disabled.
/// Each label wraps onto a second line with the text around it.
void main() {
  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('link span mode $mode', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      const hoveredLabel = 'hover over this link to see it';

      DsParagraph p(String before, DsLinkSpan link, String after) =>
          DsParagraph(
            children: [
              TextSpan(text: before),
              link,
              TextSpan(text: after),
            ],
          );

      await pumpGolden(
        tester,
        SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              p(
                'Your trial ends in 3 days. ',
                DsLinkSpan(
                  label: 'Choose a plan that fits your team',
                  onPressed: () {},
                ),
                ' to keep your projects.',
              ),
              p(
                'A pointer: ',
                DsLinkSpan(label: hoveredLabel, onPressed: () {}),
                ' and the cursor.',
              ),
              p(
                'From the keyboard, ',
                DsLinkSpan(
                  label: 'the focused link shows a ring on every line',
                  focusNode: focus,
                  onPressed: () {},
                ),
                ' it covers.',
              ),
              p(
                'Not available yet: ',
                const DsLinkSpan(
                  label: 'download the March invoice',
                  onPressed: null,
                ),
                '.',
              ),
            ],
          ),
        ),
        theme: theme,
      );

      final text = tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byType(DsParagraph).at(1),
              matching: find.byType(RichText),
            )
            .first,
      );
      final start = text.text.toPlainText().indexOf(hoveredLabel);
      final box = text
          .getBoxesForSelection(
            TextSelection(baseOffset: start, extentOffset: start + 5),
          )
          .first;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: text.localToGlobal(box.toRect().center));
      focus.requestFocus();
      // Any key marks keyboard modality.
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.pump();

      await expectGolden(tester, 'goldens/link_span_$mode.png');
    });
  }
}
