import 'dart:ui' show BoxHeightStyle, SemanticsAction;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A link inside a paragraph (`DsLinkSpan` in a `DsParagraph`) flows with
/// the text, like an `<a>` in a `<p>`, and keeps everything a `DsLink`
/// offers: pointer states, keyboard focus and Enter, link semantics,
/// theming, direction and text scale.
void main() {
  const label = 'migration guide for the second version';
  const before = 'Read the ';
  const after = ' before you upgrade.';
  final theme = DsThemeData(platform: TargetPlatform.macOS);

  Widget app(
    Widget child, {
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    DsThemeData? data,
  }) => DsApp(
    theme: data ?? theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: Directionality(textDirection: direction, child: child!),
    ),
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

  /// The label's glyph boxes, one or more per line.
  List<TextBox> labelBoxes(WidgetTester tester, String all, String part) {
    final start = all.indexOf(part);
    return text(tester).getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + part.length),
    );
  }

  /// Each line of the paragraph, top to bottom: the full line boxes.
  List<Rect> lines(WidgetTester tester) {
    final p = text(tester);
    final out = <Rect>[];
    for (final b in p.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: p.text.toPlainText().length),
      boxHeightStyle: BoxHeightStyle.max,
    )) {
      final r = b.toRect();
      if (out.isNotEmpty && (out.last.top - r.top).abs() < .01) {
        out.last = out.last.expandToInclude(r);
      } else {
        out.add(r);
      }
    }
    return out;
  }

  /// The style the paragraph gave [part] (a link's label).
  TextStyle spanStyle(WidgetTester tester, String part) {
    TextStyle? found;
    text(tester).text.visitChildren((span) {
      if (span is TextSpan && span.text == part) found = span.style;
      return true;
    });
    return found!;
  }

  Widget paragraph({
    VoidCallback? onPressed,
    FocusNode? node,
    DsLinkStyle? style,
    Uri? url,
  }) => DsParagraph(
    children: [
      const TextSpan(text: before),
      DsLinkSpan(
        label: label,
        onPressed: onPressed,
        focusNode: node,
        linkStyle: style,
        url: url,
      ),
      const TextSpan(text: after),
    ],
  );

  group('wrapping', () {
    testWidgets('the label flows on with the paragraph', (tester) async {
      await tester.pumpWidget(app(paragraph(onPressed: () {})));
      final p = text(tester);
      expect(p.text.toPlainText(), '$before$label$after');
      final boxes = labelBoxes(tester, p.text.toPlainText(), label);
      final tops = boxes.map((b) => b.top).toSet();
      expect(tops.length, greaterThanOrEqualTo(2), reason: 'spans lines');
      // The first part goes on after "Read the " on its line ...
      expect(boxes.first.left, greaterThan(0));
      expect(boxes.first.top, lessThan(lines(tester).first.bottom));
      // ... and the rest starts the next line at its start edge.
      final next = boxes.firstWhere((b) => b.top > boxes.first.top);
      expect(next.left, 0);
    });

    testWidgets('right to left, the rest starts at the right edge', (
      tester,
    ) async {
      const rtlBefore = 'اقرأ ';
      const rtlLabel = 'دليل الترحيل إلى الإصدار الثاني من التطبيق';
      await tester.pumpWidget(
        app(
          DsParagraph(
            children: [
              const TextSpan(text: rtlBefore),
              DsLinkSpan(label: rtlLabel, onPressed: () {}),
              const TextSpan(text: ' قبل الترقية.'),
            ],
          ),
          direction: TextDirection.rtl,
        ),
      );
      final p = text(tester);
      final boxes = labelBoxes(tester, p.text.toPlainText(), rtlLabel);
      // The label begins after the first word, to its left ...
      expect(boxes.first.right, lessThan(p.size.width - 1));
      expect(boxes.first.direction, TextDirection.rtl);
      // ... and goes on at the right edge of the next line.
      final next = boxes.firstWhere((b) => b.top > boxes.first.top);
      expect(next.right, closeTo(p.size.width, .01));
    });

    testWidgets('scales with the text and keeps the paragraph line height', (
      tester,
    ) async {
      Future<(double, int)> measure(double scale) async {
        await tester.pumpWidget(
          app(paragraph(onPressed: () {}), textScale: scale),
        );
        final metrics = lines(tester);
        // Every line, with a link or not, is as tall as the others.
        expect(metrics.map((m) => m.height.toStringAsFixed(3)).toSet(), [
          metrics.first.height.toStringAsFixed(3),
        ]);
        return (metrics.first.height, metrics.length);
      }

      final (h1, n1) = await measure(1);
      final (h2, n2) = await measure(2);
      expect(h2, closeTo(h1 * 2, .5));
      expect(n2, greaterThan(n1));
    });
  });

  group('pointer', () {
    testWidgets('click cursor, hover and pressed styles, tap activates', (
      tester,
    ) async {
      var taps = 0;
      const hover = Color(0xFF00AA00);
      const press = Color(0xFFAA0000);
      await tester.pumpWidget(
        app(
          paragraph(
            onPressed: () => taps++,
            style: const DsLinkStyle(
              hovered: DsLinkStyle(foreground: hover),
              pressed: DsLinkStyle(foreground: press),
            ),
          ),
        ),
      );
      expect(spanStyle(tester, label).color, theme.colors.link);
      final p = text(tester);
      final box = labelBoxes(tester, p.text.toPlainText(), label).first;
      final at = p.localToGlobal(box.toRect().center);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(at);
      await tester.pump();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );
      expect(spanStyle(tester, label).color, hover);
      // Stays hovered across rebuilds: the span does not flicker out.
      await tester.pump();
      await tester.pump();
      expect(spanStyle(tester, label).color, hover);

      await mouse.down(at);
      await tester.pump();
      expect(spanStyle(tester, label).color, press);
      await mouse.up();
      await tester.pump();
      expect(taps, 1);
      expect(spanStyle(tester, label).color, hover);
      // A click does not take focus.
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('DsLinkSpan'),
      );

      await mouse.moveTo(const Offset(239, 400));
      await tester.pump();
      expect(spanStyle(tester, label).color, theme.colors.link);
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.basic,
      );
    });

    testWidgets('hover thickens the underline, as on a DsLink', (tester) async {
      await tester.pumpWidget(app(paragraph(onPressed: () {})));
      final p = text(tester);
      final box = labelBoxes(tester, p.text.toPlainText(), label).first;
      double? thickest() {
        double? h;
        final paragraphBox = tester.renderObject<RenderBox>(
          find.byType(DsParagraph),
        );
        expect(
          paragraphBox,
          paints..everything((method, args) {
            if (method == #drawRect) {
              final r = args.first as Rect;
              h = h == null || r.height > h! ? r.height : h;
            }
            return true;
          }),
        );
        return h;
      }

      expect(thickest(), 1);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: p.localToGlobal(box.toRect().center));
      await tester.pump();
      expect(thickest(), 2);
    });

    testWidgets('disabled: no hover, no tap, the disabled color', (
      tester,
    ) async {
      await tester.pumpWidget(app(paragraph()));
      expect(spanStyle(tester, label).color, theme.colors.onDisabled);
      final p = text(tester);
      final box = labelBoxes(tester, p.text.toPlainText(), label).first;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: p.localToGlobal(box.toRect().center));
      await tester.pump();
      expect(spanStyle(tester, label).color, theme.colors.onDisabled);
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.forbidden,
      );
    });
  });

  group('keyboard', () {
    testWidgets('Tab reaches each link in text order; Enter activates; '
        'Space does not', (tester) async {
      final a = FocusNode(), b = FocusNode(), c = FocusNode();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      addTearDown(c.dispose);
      final taps = <String>[];
      var outerSpace = 0;
      await tester.pumpWidget(
        app(
          Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (_, e) {
              if (e.logicalKey == LogicalKeyboardKey.space) outerSpace++;
              return KeyEventResult.ignored;
            },
            child: DsParagraph(
              children: [
                const TextSpan(text: 'See '),
                DsLinkSpan(
                  label: 'the first link that wraps across lines',
                  focusNode: a,
                  onPressed: () => taps.add('a'),
                ),
                const TextSpan(text: ', '),
                DsLinkSpan(
                  label: 'a disabled one',
                  focusNode: b,
                  onPressed: null,
                ),
                const TextSpan(text: ' and '),
                DsLinkSpan(
                  label: 'the last',
                  focusNode: c,
                  onPressed: () => taps.add('c'),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, isEmpty);
      expect(outerSpace, 0, reason: 'Space stops at the link');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, ['a']);
      // Held Enter does not fire again.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      expect(taps, ['a', 'a']);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(b.hasFocus, isFalse, reason: 'a disabled link is skipped');
      expect(c.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      expect(taps, ['a', 'a', 'c']);

      // Shift+Tab goes back, past the disabled link again.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);
    });

    testWidgets('focus shows for the keyboard only', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      const ring = Color(0xFF0000AA);
      await tester.pumpWidget(
        app(
          paragraph(
            onPressed: () {},
            node: node,
            style: const DsLinkStyle(focused: DsLinkStyle(foreground: ring)),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
      expect(spanStyle(tester, label).color, ring);

      // A pointer down elsewhere hides it, focus stays.
      await tester.tapAt(const Offset(230, 500));
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
      expect(spanStyle(tester, label).color, theme.colors.link);
    });

    testWidgets('the focus target sits on the first line of the label', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(app(paragraph(onPressed: () {}, node: node)));
      final p = text(tester);
      final box = labelBoxes(tester, p.text.toPlainText(), label).first;
      final rect = node.rect;
      final origin = p.localToGlobal(Offset.zero);
      expect(rect.left, closeTo(origin.dx + box.left, .01));
      // It ends at the last word: the space where the label breaks is
      // left out.
      final all = p.text.toPlainText();
      final start = all.indexOf(label);
      var lastWordEnd = 0.0;
      for (var i = start; i < start + label.length; i++) {
        final glyph = p
            .getBoxesForSelection(
              TextSelection(baseOffset: i, extentOffset: i + 1),
            )
            .single;
        if (glyph.top == box.top && all[i] != ' ') lastWordEnd = glyph.right;
      }
      expect(box.right, greaterThan(lastWordEnd), reason: 'a space follows');
      expect(rect.right, closeTo(origin.dx + lastWordEnd, .01));
    });
  });

  group('semantics', () {
    testWidgets('a link with its label, address, focus and tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final node = FocusNode();
      addTearDown(node.dispose);
      var taps = 0;
      final url = Uri.parse('https://example.com/guide');
      await tester.pumpWidget(
        app(paragraph(onPressed: () => taps++, node: node, url: url)),
      );
      expect(
        find.semantics.byLabel(label),
        matchesSemantics(
          label: label,
          isLink: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          textDirection: TextDirection.ltr,
        ),
      );
      expect(
        find.semantics
            .byLabel(label)
            .evaluate()
            .single
            .getSemanticsData()
            .linkUrl,
        url,
      );
      // The text around it reads as text.
      expect(
        find.semantics.byLabel(before),
        matchesSemantics(label: before, textDirection: TextDirection.ltr),
      );
      expect(find.semantics.byLabel(after), findsOne);

      tester.semantics.tap(find.semantics.byLabel(label));
      expect(taps, 1);
      tester.semantics.performAction(
        find.semantics.byLabel(label),
        SemanticsAction.focus,
      );
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
      expect(
        find.semantics.byLabel(label),
        isSemantics(isLink: true, isFocused: true),
      );
      handle.dispose();
    });

    testWidgets('an external link says it opens outside the app', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsParagraph(
            children: [
              const TextSpan(text: before),
              DsLinkSpan(label: label, external: true, onPressed: () {}),
              const TextSpan(text: after),
              DsLinkSpan(label: 'notes', onPressed: () {}),
            ],
          ),
        ),
      );
      SemanticsData data(String text) =>
          find.semantics.byLabel(text).evaluate().single.getSemanticsData();
      expect(data(label).hint, 'Opens outside the app');
      expect(data('notes').hint, isEmpty);
      expect(data(before).hint, isEmpty);
      handle.dispose();
    });

    testWidgets('disabled, a semantic label, right to left', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const DsParagraph(
            children: [
              TextSpan(text: 'نزّل '),
              DsLinkSpan(
                label: 'الفاتورة',
                semanticLabel: 'فاتورة مارس',
                onPressed: null,
              ),
            ],
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(
        find.semantics.byLabel('فاتورة مارس'),
        matchesSemantics(
          label: 'فاتورة مارس',
          isLink: true,
          hasEnabledState: true,
          textDirection: TextDirection.rtl,
        ),
      );
      handle.dispose();
    });
  });

  test('outside a DsParagraph, a link span is reported', () {
    final painter = TextPainter(
      text: DsLinkSpan(label: 'guide', onPressed: () {}),
      textDirection: TextDirection.ltr,
    );
    addTearDown(painter.dispose);
    expect(
      painter.layout,
      throwsA(
        isA<FlutterError>().having(
          (e) => e.message,
          'message',
          contains('outside a DsParagraph'),
        ),
      ),
    );
  });

  testWidgets('links that come and go keep their nodes by position', (
    tester,
  ) async {
    Widget build(int n) => app(
      DsParagraph(
        children: [
          for (var i = 0; i < n; i++) ...[
            TextSpan(text: 'Item $i: '),
            DsLinkSpan(label: 'open $i', onPressed: () {}),
          ],
        ],
      ),
    );
    await tester.pumpWidget(build(3));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final first = FocusManager.instance.primaryFocus;
    await tester.pumpWidget(build(1));
    expect(FocusManager.instance.primaryFocus, same(first));
    await tester.pumpWidget(build(4));
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    }
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'DsLinkSpan');
    await tester.pumpWidget(build(0));
    expect(find.byType(DsParagraph), findsOne);
  });
}
