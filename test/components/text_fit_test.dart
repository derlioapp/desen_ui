import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Narrow widths and large text: components lay out without overflow
/// errors, and labels wrap or grow instead of losing their text (WCAG 1.4.4
/// and 1.4.10).

Widget _app(
  Widget child, {
  required double width,
  double textScale = 1,
  DsThemeData? theme,
}) => DsApp(
  theme: theme ?? DsThemeData(),
  themeMode: DsThemeMode.light,
  locale: const Locale('en', 'US'),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: c!,
  ),
  home: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: width, child: child),
  ),
);

/// Pumps [child] and returns every framework error it raised.
Future<List<Object>> _pump(
  WidgetTester tester,
  Widget child, {
  required double width,
  double textScale = 1,
  DsThemeData? theme,
}) async {
  await tester.pumpWidget(
    _app(child, width: width, textScale: textScale, theme: theme),
  );
  await tester.pump(const Duration(seconds: 1));
  final errors = <Object>[];
  Object? e;
  while ((e = tester.takeException()) != null) {
    errors.add(e!);
  }
  return errors;
}

DsThemeData compact() => DsThemeData(density: DsDensity.compact);

/// Whether the text [label] is shown in full: not ellipsized or cut.
bool _fullyShown(WidgetTester tester, String label) {
  final p = tester.renderObject<RenderParagraph>(find.text(label).first);
  return !p.didExceedMaxLines;
}

RenderParagraph _paragraph(WidgetTester tester, String label) =>
    tester.renderObject<RenderParagraph>(find.text(label).first);

/// How many lines [label] takes.
int _lines(WidgetTester tester, String label) {
  final p = _paragraph(tester, label);
  return p
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: p.text.toPlainText().length),
      )
      .map((b) => b.top.round())
      .toSet()
      .length;
}

/// Whether a line of [label] ends inside a word.
bool _breaksInsideWord(WidgetTester tester, String label) {
  final p = _paragraph(tester, label);
  final text = p.text.toPlainText();
  double? top(int i) => p
      .getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))
      .firstOrNull
      ?.top;
  for (var i = 0; i + 1 < text.length; i++) {
    final a = top(i), b = top(i + 1);
    if (a != null && b != null && b > a + 1) {
      if (text[i] != ' ' && text[i + 1] != ' ') return true;
    }
  }
  return false;
}

void main() {
  group('segmented control', () {
    Widget control(List<String> labels) => DsSegmentedControl<int>(
      value: 0,
      onChanged: (_) {},
      segments: [
        for (final (i, l) in labels.indexed)
          DsSegment(value: i, label: Text(l)),
      ],
    );
    final compact = DsThemeData(density: DsDensity.compact);

    testWidgets('labels that fit stay on one row, unchanged', (tester) async {
      await _pump(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: control(['Daily', 'Weekly', 'Monthly']),
        ),
        width: 400,
        theme: compact,
      );
      final daily = tester.getRect(find.text('Daily'));
      expect(tester.getRect(find.text('Monthly')).top, daily.top);
      for (final l in ['Daily', 'Weekly', 'Monthly']) {
        expect(_lines(tester, l), 1, reason: l);
      }
    });

    testWidgets('labels wrap between words before they are cut', (
      tester,
    ) async {
      const labels = ['Last seven days', 'This month', 'All time'];
      final errors = await _pump(tester, control(labels), width: 240);
      expect(errors, isEmpty);
      for (final l in labels) {
        expect(_fullyShown(tester, l), isTrue, reason: l);
        expect(_breaksInsideWord(tester, l), isFalse, reason: l);
      }
    });

    for (final width in [288.0, 200.0]) {
      testWidgets('at 2x text in ${width}px the segments stack, no label cut', (
        tester,
      ) async {
        const labels = ['Daily', 'Weekly', 'Monthly'];
        final errors = await _pump(
          tester,
          control(labels),
          width: width,
          textScale: 2,
        );
        expect(errors, isEmpty);
        for (final l in labels) {
          expect(_lines(tester, l), 1, reason: l);
        }
        // One under the other.
        expect(
          tester.getRect(find.text('Weekly')).top,
          greaterThan(tester.getRect(find.text('Daily')).bottom),
        );
        expect(
          tester.getSize(find.byType(DsSegmentedControl<int>)).width,
          lessThanOrEqualTo(width),
        );
      });
    }

    testWidgets('stacked, the thumb and the keys follow the selection', (
      tester,
    ) async {
      var value = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => DsSegmentedControl<int>(
            value: value,
            focusNode: node,
            onChanged: (v) => setState(() => value = v),
            segments: const [
              DsSegment(value: 0, label: Text('Daily')),
              DsSegment(value: 1, label: Text('Weekly')),
              DsSegment(value: 2, label: Text('Monthly')),
            ],
          ),
        ),
        width: 200,
        textScale: 2,
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(value, 1);
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(value, 2);
      // The thumb (the first box in the channel) sits under "Monthly".
      final thumb = tester.getRect(
        find
            .descendant(
              of: find.byType(DsSegmentedControl<int>),
              matching: find.byType(DecoratedBox),
            )
            .at(1),
      );
      final monthly = tester.getRect(find.text('Monthly'));
      expect(thumb.top, lessThanOrEqualTo(monthly.top));
      expect(thumb.bottom, greaterThanOrEqualTo(monthly.bottom));
    });
  });

  group('bottom nav', () {
    final compact = DsThemeData(density: DsDensity.compact);
    List<DsBottomNavItem<int>> items(List<String> labels) => [
      for (final (i, l) in labels.indexed)
        DsBottomNavItem(
          value: i,
          icon: const DsIcon(DsIcons.inbox),
          label: Text(l),
        ),
    ];
    double itemHeight(WidgetTester tester, String label) => tester
        .getSize(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        )
        .height;

    testWidgets('labels that fit keep one line and the default height', (
      tester,
    ) async {
      await _pump(
        tester,
        Center(
          child: DsBottomNav<int>(
            value: 0,
            onChanged: (_) {},
            items: items(['Home', 'Search', 'Profile']),
          ),
        ),
        width: 390,
        theme: compact,
      );
      expect(_lines(tester, 'Search'), 1);
      expect(
        itemHeight(tester, 'Search'),
        DsBottomNav.defaultItemStyle(
          compact,
          variant: DsBottomNavVariant.floating,
        ).height,
      );
      expect(find.byType(DsTooltip), findsNothing);
    });

    testWidgets('a label wraps between words at 2x, and the items stay even', (
      tester,
    ) async {
      final errors = await _pump(
        tester,
        Center(
          child: DsBottomNav<int>(
            value: 0,
            onChanged: (_) {},
            items: items(['My files', 'Map', 'Me']),
          ),
        ),
        width: 390,
        textScale: 2,
        theme: compact,
      );
      expect(errors, isEmpty);
      expect(_lines(tester, 'My files'), 2);
      expect(_fullyShown(tester, 'My files'), isTrue);
      expect(_breaksInsideWord(tester, 'My files'), isFalse);
      expect(itemHeight(tester, 'Map'), itemHeight(tester, 'My files'));
    });

    testWidgets('a label that cannot fit shows whole in a tooltip', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final errors = await _pump(
        tester,
        Center(
          child: DsBottomNav<int>(
            value: 0,
            onChanged: (_) {},
            items: items(['Inbox', 'Notifications', 'Calendar', 'Settings']),
          ),
        ),
        width: 320,
        textScale: 2,
        theme: compact,
      );
      expect(errors, isEmpty);
      expect(_fullyShown(tester, 'Notifications'), isFalse);
      // No word is broken in two; the label ellipsizes on one line.
      expect(_lines(tester, 'Notifications'), 1);
      expect(
        find.ancestor(
          of: find.text('Notifications'),
          matching: find.byWidgetPredicate(
            (w) => w is DsTooltip && w.message == 'Notifications',
          ),
        ),
        findsOneWidget,
      );
      // Screen readers read the whole label, once.
      expect(
        tester.getSemantics(find.text('Notifications')).label,
        contains('Notifications'),
      );
      // A long press shows it.
      await tester.longPress(find.text('Notifications'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Notifications'), findsNWidgets(2));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      handle.dispose();
    });
  });

  group('table at large text', () {
    Widget table() => SizedBox(
      height: 300,
      child: DsTable<int>(
        rows: const [1, 2],
        rowKey: (r) => r,
        semanticLabel: 'Customers',
        columns: [
          DsTableColumn<int>(
            id: 'name',
            label: 'Customer',
            value: (r) => r == 1 ? 'Acme Corporation' : 'Beta',
          ),
          DsTableColumn<int>(
            id: 'amount',
            label: 'Amount',
            value: (r) => r * 1000,
            numeric: true,
          ),
        ],
      ),
    );

    testWidgets('a cell that shows whole at 1x stays whole at 2x', (
      tester,
    ) async {
      await _pump(tester, table(), width: 360, theme: compact());
      expect(_fullyShown(tester, 'Acme Corporation'), isTrue);
      final errors = await _pump(
        tester,
        table(),
        width: 360,
        textScale: 2,
        theme: compact(),
      );
      expect(errors, isEmpty);
      expect(_fullyShown(tester, 'Acme Corporation'), isTrue);
    });
  });

  group('multi-select tags', () {
    final options = [
      for (var i = 0; i < 30; i++)
        DsSelectOption(
          value: i,
          label: i.isEven ? 'Option $i' : 'A much longer option label $i',
        ),
    ];

    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('30 tags in a 120px field at ${scale}x lay out', (
        tester,
      ) async {
        final errors = await _pump(
          tester,
          DsMultiSelect<int>(
            value: [for (var i = 0; i < 30; i++) i],
            onChanged: (_) {},
            options: options,
          ),
          width: 120,
          textScale: scale,
        );
        expect(errors, isEmpty);
      });
    }

    testWidgets('a long tag label wraps at 2x text instead of being cut', (
      tester,
    ) async {
      const label = 'Design system foundations';
      final errors = await _pump(
        tester,
        DsMultiSelect<int>(
          value: const [1, 2],
          onChanged: (_) {},
          options: const [
            DsSelectOption(value: 1, label: 'Frontend'),
            DsSelectOption(value: 2, label: label),
          ],
        ),
        width: 288,
        textScale: 2,
      );
      expect(errors, isEmpty);
      expect(_fullyShown(tester, label), isTrue);
      expect(_fullyShown(tester, 'Frontend'), isTrue);
    });

    testWidgets('collapsed tags keep to one line', (tester) async {
      await _pump(
        tester,
        DsMultiSelect<int>(
          value: const [1],
          collapseTags: true,
          onChanged: (_) {},
          options: const [
            DsSelectOption(
              value: 1,
              label: 'A label far too long for the one line it gets here',
            ),
          ],
        ),
        width: 200,
      );
      final text = tester.widget<Text>(
        find.text('A label far too long for the one line it gets here'),
      );
      expect(text.maxLines, 1);
    });
  });

  group('calendar with two months', () {
    Widget calendar() => DsCalendar(
      value: DateTime(2026, 10, 6),
      currentDate: DateTime(2026, 10, 6),
      months: 2,
      onChanged: (_) {},
    );

    for (final (width, scale) in [
      (200.0, 1.0),
      (200.0, 2.0),
      (200.0, 3.0),
      (280.0, 1.0),
      (320.0, 2.0),
      (320.0, 3.0),
    ]) {
      testWidgets('stacks at ${width}px and ${scale}x text', (tester) async {
        // Two months stacked are taller than the 600px test window: the
        // page scrolls down to them (reflow, WCAG 1.4.10, scrolls in one
        // direction), as an app's would.
        final errors = await _pump(
          tester,
          SingleChildScrollView(child: calendar()),
          width: width,
          textScale: scale,
        );
        expect(errors, isEmpty);
        final october = tester.getRect(find.text('October 2026'));
        final november = tester.getRect(find.text('November 2026'));
        // One under the other, the later month below the first's days.
        expect(november.top, greaterThan(october.bottom));
        expect(
          november.top,
          greaterThan(tester.getRect(find.text('31').first).top),
        );
        // Still one pair of month buttons.
        expect(find.bySemanticsLabel('Next month'), findsOneWidget);
        expect(
          tester.getSize(find.byType(DsCalendar)).width,
          lessThanOrEqualTo(width),
        );
      });
    }

    // Narrowed side by side, the months' titles were cut at phone widths
    // where the days still fit; they stack instead.
    for (final width in [375.0, 414.0]) {
      testWidgets('stacks with whole titles at ${width}px', (tester) async {
        final errors = await _pump(
          tester,
          SingleChildScrollView(child: calendar()),
          width: width,
        );
        expect(errors, isEmpty);
        expect(
          tester.getRect(find.text('November 2026')).top,
          greaterThan(tester.getRect(find.text('October 2026')).bottom),
        );
        expect(_fullyShown(tester, 'October 2026'), isTrue);
        expect(_fullyShown(tester, 'November 2026'), isTrue);
      });
    }

    testWidgets('stays side by side where the days fit', (tester) async {
      final errors = await _pump(tester, calendar(), width: 700);
      expect(errors, isEmpty);
      expect(
        tester.getRect(find.text('November 2026')).top,
        tester.getRect(find.text('October 2026')).top,
      );
    });

    testWidgets('stacked months keep the keyboard moving across them', (
      tester,
    ) async {
      DateTime? chosen;
      await _pump(
        tester,
        DsCalendar(
          value: DateTime(2026, 10, 30),
          currentDate: DateTime(2026, 10, 6),
          months: 2,
          autofocus: true,
          onChanged: (d) => chosen = d,
        ),
        width: 200,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chosen, DateTime(2026, 11, 6));
      // November is still shown, below October: no page turn.
      expect(find.text('October 2026'), findsOneWidget);
    });
  });

  group('toolbar', () {
    Widget toolbar() => DsToolbar(
      children: [
        DsToolbarToggle(
          icon: const DsIcon(DsIcons.bold),
          semanticLabel: 'Bold',
          selected: true,
          onChanged: (_) {},
        ),
        const DsToolbarDivider(),
        DsToolbarToggle(
          icon: const DsIcon(DsIcons.italic),
          semanticLabel: 'Italic',
          selected: false,
          onChanged: (_) {},
        ),
        DsButton(onPressed: () {}, child: const Text('Publish changes')),
      ],
    );

    for (final (width, scale) in [(200.0, 1.0), (200.0, 3.0), (360.0, 3.0)]) {
      testWidgets(
        'scrolls instead of overflowing at ${width}px and ${scale}x text',
        (tester) async {
          final errors = await _pump(
            tester,
            Align(alignment: Alignment.topLeft, child: toolbar()),
            width: width,
            textScale: scale,
          );
          expect(errors, isEmpty);
          expect(
            tester.getSize(find.byType(DsToolbar)).width,
            lessThanOrEqualTo(width),
          );
          // The end that hides items fades, so the bar reads as scrollable.
          expect(
            find.descendant(
              of: find.byType(DsToolbar),
              matching: find.byType(ShaderMask),
            ),
            findsOneWidget,
          );
        },
        variant: const TargetPlatformVariant({
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }),
      );
    }

    testWidgets('fits without a fade where there is room', (tester) async {
      final errors = await _pump(
        tester,
        Align(alignment: Alignment.topLeft, child: toolbar()),
        width: 600,
      );
      expect(errors, isEmpty);
      expect(
        find.descendant(
          of: find.byType(DsToolbar),
          matching: find.byType(ShaderMask),
        ),
        findsNothing,
      );
    });

    testWidgets('lays out in a Row', (tester) async {
      final errors = await _pump(
        tester,
        Row(children: [toolbar()]),
        width: 600,
      );
      expect(errors, isEmpty);
    });

    testWidgets('End brings the last item into view', (tester) async {
      await _pump(
        tester,
        Align(alignment: Alignment.topLeft, child: toolbar()),
        width: 160,
      );
      final bar = tester.getRect(find.byType(DsToolbar));
      final button = find.widgetWithText(DsButton, 'Publish changes');
      expect(tester.getRect(button).right, greaterThan(bar.right));
      // Focus the first item from the keyboard, then jump to the last.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(tester.getRect(button).right, lessThanOrEqualTo(bar.right + 0.5));
    });
  });

  group('narrow text field', () {
    Finder mask() => find.descendant(
      of: find.byType(DsTextField),
      matching: find.byType(ShaderMask),
    );

    testWidgets('a value too long fades at the edge that hides it', (
      tester,
    ) async {
      final errors = await _pump(
        tester,
        const DsTextField(initialValue: 'A value far too long for the field'),
        width: 120,
      );
      expect(errors, isEmpty);
      expect(mask(), findsOneWidget);
      // While editing, the plain edge the caret moves along.
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(mask(), findsNothing);
      // Leaving the field brings the fade back.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump();
      expect(mask(), findsOneWidget);
    });

    testWidgets('a value that fits, or several lines, do not fade', (
      tester,
    ) async {
      await _pump(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsTextField(initialValue: 'Short'),
            DsTextField.multiline(
              initialValue: 'A value far too long for one line of the field',
            ),
          ],
        ),
        width: 160,
      );
      expect(mask(), findsNothing);
    });
  });

  group('text selection toolbar', () {
    const labels = ['Cut', 'Copy', 'Paste', 'Select all', 'Look up', 'Share'];

    Future<void> pumpToolbar(WidgetTester tester, double width) async {
      tester.view
        ..physicalSize = Size(width, 600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        DsApp(
          locale: const Locale('en', 'US'),
          home: DsTextSelectionToolbar(
            anchors: TextSelectionToolbarAnchors(
              primaryAnchor: Offset(width / 2, 300),
            ),
            buttonItems: [
              ContextMenuButtonItem(
                type: ContextMenuButtonType.cut,
                onPressed: () {},
              ),
              ContextMenuButtonItem(
                type: ContextMenuButtonType.copy,
                onPressed: () {},
              ),
              ContextMenuButtonItem(
                type: ContextMenuButtonType.paste,
                onPressed: () {},
              ),
              ContextMenuButtonItem(
                type: ContextMenuButtonType.selectAll,
                onPressed: () {},
              ),
              ContextMenuButtonItem(
                type: ContextMenuButtonType.lookUp,
                onPressed: () {},
              ),
              ContextMenuButtonItem(
                type: ContextMenuButtonType.share,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// The labels on the page shown, each checked to show whole inside the
    /// toolbar.
    List<String> shown(WidgetTester tester) {
      final bar = tester.getRect(
        find.descendant(
          of: find.byType(DsTextSelectionToolbar),
          matching: find.byType(DsSurface),
        ),
      );
      final out = <String>[];
      for (final label in labels) {
        final f = find.text(label);
        if (f.evaluate().isEmpty) continue;
        final rect = tester.getRect(f);
        expect(rect.left, greaterThanOrEqualTo(bar.left), reason: label);
        expect(rect.right, lessThanOrEqualTo(bar.right), reason: label);
        expect(_fullyShown(tester, label), isTrue, reason: label);
        out.add(label);
      }
      return out;
    }

    testWidgets('every action fits a wide window on one page', (tester) async {
      await pumpToolbar(tester, 800);
      expect(shown(tester), labels);
      expect(find.bySemanticsLabel('Next page'), findsNothing);
    });

    testWidgets('a narrow window splits the actions into pages', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpToolbar(tester, 320);
      expect(tester.takeException(), isNull);
      final seen = <String>[...shown(tester)];
      expect(seen, isNotEmpty);
      expect(seen.length, lessThan(labels.length));
      expect(find.bySemanticsLabel('Previous page'), findsNothing);
      // Page through to the end: every action shows whole on some page.
      for (var i = 0; i < labels.length; i++) {
        final next = find.bySemanticsLabel('Next page');
        if (next.evaluate().isEmpty) break;
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Previous page'), findsOneWidget);
        seen.addAll(shown(tester));
      }
      expect(seen, labels);
      // And back to the first page.
      await tester.tap(find.bySemanticsLabel('Previous page'));
      await tester.pumpAndSettle();
      expect(shown(tester).first, 'Cut');
      handle.dispose();
    });
  });
}
