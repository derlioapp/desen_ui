import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// DsParagraph beyond plain links: a line limit with an ellipsis, widgets
/// inside the text, and links that leave the app.
void main() {
  final theme = DsThemeData(platform: TargetPlatform.macOS);

  Widget app(Widget child) => DsApp(
    theme: theme,
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 240, child: child),
    ),
  );

  RenderParagraph text(WidgetTester tester) => tester.renderObject(
    find.descendant(
      of: find.byType(DsParagraph),
      matching: find.byType(RichText),
    ),
  );

  group('maxLines', () {
    Widget cut({FocusNode? first, FocusNode? hidden}) => DsParagraph(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      children: [
        DsLinkSpan(label: 'Plans', focusNode: first, onPressed: () {}),
        const TextSpan(
          text:
              ' are billed monthly, and you can change or cancel yours at '
              'any time from the settings, as the ',
        ),
        DsLinkSpan(label: 'billing guide', focusNode: hidden, onPressed: () {}),
        const TextSpan(text: ' explains.'),
      ],
    );

    testWidgets('cuts the text at the limit with an ellipsis', (tester) async {
      await tester.pumpWidget(app(cut()));
      final p = text(tester);
      expect(p.maxLines, 1);
      expect(p.overflow, TextOverflow.ellipsis);
      expect(p.didExceedMaxLines, isTrue);
      final line = p.getFullHeightForCaret(const TextPosition(offset: 0));
      expect(
        tester.getSize(find.byType(DsParagraph)).height,
        lessThan(line * 1.5),
      );
    });

    testWidgets('a link cut off is out of the Tab order and the semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final first = FocusNode(), hidden = FocusNode();
      addTearDown(first.dispose);
      addTearDown(hidden.dispose);
      await tester.pumpWidget(app(cut(first: first, hidden: hidden)));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(first.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(hidden.hasFocus, isFalse);
      expect(find.semantics.byLabel('Plans'), findsOne);
      expect(find.semantics.byLabel('billing guide'), findsNothing);
      handle.dispose();
    });

    testWidgets('a link shown again when the limit goes is reachable', (
      tester,
    ) async {
      final hidden = FocusNode();
      addTearDown(hidden.dispose);
      await tester.pumpWidget(app(cut(hidden: hidden)));
      await tester.pump();
      await tester.pumpWidget(
        app(
          DsParagraph(
            children: [
              DsLinkSpan(label: 'Plans', onPressed: () {}),
              const TextSpan(text: ' are billed monthly, as the '),
              DsLinkSpan(
                label: 'billing guide',
                focusNode: hidden,
                onPressed: () {},
              ),
              const TextSpan(text: ' explains.'),
            ],
          ),
        ),
      );
      await tester.pump();
      hidden.requestFocus();
      await tester.pump();
      expect(hidden.hasPrimaryFocus, isTrue);
    });
  });

  group('widgets in the text', () {
    testWidgets('are laid out, hit and read in text order', (tester) async {
      final handle = tester.ensureSemantics();
      var badge = 0, link = 0;
      await tester.pumpWidget(
        app(
          DsParagraph(
            children: [
              const TextSpan(text: 'Press '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Semantics(
                  label: 'Command',
                  button: true,
                  child: GestureDetector(
                    onTap: () => badge++,
                    child: const DsIcon(DsIcons.command, size: 16),
                  ),
                ),
              ),
              const TextSpan(text: ' K to search, or read the '),
              DsLinkSpan(label: 'guide', onPressed: () => link++),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(DsIcon));
      expect(badge, 1);
      tester.semantics.tap(find.semantics.byLabel('guide'));
      expect(link, 1);
      tester.semantics.tap(find.semantics.byLabel('Command'));
      expect(badge, 2);

      final labels = [
        for (final node
            in tester
                .getSemantics(find.byType(DsParagraph))
                .debugListChildrenInOrder(
                  DebugSemanticsDumpOrder.traversalOrder,
                ))
          node.label,
      ];
      expect(labels, [
        'Press ',
        'Command',
        ' K to search, or read the ',
        'guide',
        '.',
      ]);
      handle.dispose();
    });
  });

  group('external links', () {
    testWidgets('show the up-right arrow after the label, which activates the '
        'link too', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        app(
          DsParagraph(
            children: [
              const TextSpan(text: 'Ask in the '),
              DsLinkSpan(
                label: 'community forum',
                external: true,
                onPressed: () => taps++,
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      );
      final arrow = find.byWidgetPredicate(
        (w) => w is DsIcon && identical(w.icon, DsIcons.arrowUpRight),
      );
      expect(arrow, findsOne);
      final label = text(tester).getBoxesForSelection(
        const TextSelection(baseOffset: 11, extentOffset: 26),
      );
      expect(
        tester.getTopLeft(arrow).dx,
        greaterThanOrEqualTo(label.last.right),
      );
      await tester.tap(arrow);
      expect(taps, 1);
    });
  });

  group('semantic labels', () {
    testWidgets('a link or a span read differently from its text lays out '
        'and is read by its label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsParagraph(
            children: [
              const TextSpan(
                text: 'Total: 1.250,00 TL ',
                semanticsLabel: '1250 lira',
              ),
              DsLinkSpan(
                label: 'privacy policy',
                semanticLabel: 'Privacy',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.semantics.byLabel('Privacy'), findsOne);
      expect(find.semantics.byLabel('1250 lira'), findsOne);
      handle.dispose();
    });
  });
}
