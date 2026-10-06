import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A long breadcrumb: when it wraps, a separator stays with the level
/// before it; it can keep to one line by collapsing its middle levels into
/// a "…" menu, as it does in a pane header title.
void main() {
  final pressed = <String>[];
  List<DsBreadcrumbItem> path() => [
    for (final label in [
      'Acme',
      'Website redesign',
      'Settings',
      'Integrations',
    ])
      DsBreadcrumbItem(label: label, onPressed: () => pressed.add(label)),
    const DsBreadcrumbItem(label: 'Webhooks'),
  ];
  setUp(pressed.clear);

  Widget app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      DsApp(
        builder: (context, child) =>
            Directionality(textDirection: direction, child: child!),
        home: Align(alignment: Alignment.topLeft, child: child),
      );

  Finder separators() => find.byWidgetPredicate(
    (w) => w is DsIcon && w.icon == DsIcons.chevronRight,
  );

  for (final direction in TextDirection.values) {
    testWidgets('a wrapped path never starts a line with a separator '
        '(${direction.name})', (tester) async {
      await tester.pumpWidget(
        app(
          SizedBox(width: 260, child: DsBreadcrumb(items: path())),
          direction: direction,
        ),
      );
      final labels = ['Acme', 'Website redesign', 'Settings', 'Integrations'];
      expect(separators(), findsNWidgets(labels.length));
      // It does wrap.
      expect(
        tester.getRect(find.text('Webhooks')).top,
        greaterThan(tester.getRect(find.text('Acme')).bottom),
      );
      for (final (i, label) in labels.indexed) {
        final text = tester.getRect(find.text(label));
        final sep = tester.getRect(separators().at(i));
        expect(
          sep.center.dy,
          moreOrLessEquals(text.center.dy, epsilon: 1),
          reason: 'the separator after "$label" is on its line',
        );
        if (direction == TextDirection.ltr) {
          expect(sep.left, greaterThan(text.right));
        } else {
          expect(sep.right, lessThan(text.left));
        }
      }
    });
  }

  group('collapse', () {
    testWidgets('keeps one line with first, "…" and the last levels', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 260,
            child: DsBreadcrumb(
              items: path(),
              overflow: DsBreadcrumbOverflow.collapse,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.text('Acme'));
      final last = tester.getRect(find.text('Webhooks'));
      expect(last.center.dy, moreOrLessEquals(first.center.dy, epsilon: 1));
      expect(find.text('Website redesign'), findsNothing);
      final more = find.bySemanticsLabel('More levels');
      expect(more, findsOneWidget);
      expect(tester.getSemantics(more).flagsCollection.isButton, isTrue);
      // The menu lists the hidden levels and goes to them.
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(find.text('Website redesign'), findsOneWidget);
      await tester.tap(find.text('Website redesign'));
      await tester.pumpAndSettle();
      expect(pressed, ['Website redesign']);
      handle.dispose();
    });

    testWidgets('shows every level when they fit', (tester) async {
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 800,
            child: DsBreadcrumb(
              items: path(),
              overflow: DsBreadcrumbOverflow.collapse,
            ),
          ),
        ),
      );
      for (final label in ['Acme', 'Website redesign', 'Webhooks']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.bySemanticsLabel('More levels'), findsNothing);
    });

    testWidgets('very narrow: "…" and the current page, ellipsized', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 90,
            child: DsBreadcrumb(
              items: path(),
              overflow: DsBreadcrumbOverflow.collapse,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Acme'), findsNothing);
      expect(find.text('Webhooks'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Webhooks')).overflow,
        TextOverflow.ellipsis,
      );
    });

    testWidgets('grows with 2x text and stays one line', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: app(
            SizedBox(
              width: 360,
              child: DsBreadcrumb(
                items: path(),
                overflow: DsBreadcrumbOverflow.collapse,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.text('Webhooks'));
      expect(
        tester.getSize(find.byType(DsBreadcrumb)).height,
        lessThan(first.height * 2),
      );
    });
  });

  testWidgets('a pane header keeps a breadcrumb title on one line at 390', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        SizedBox(
          width: 390,
          child: DsPaneHeader(
            title: DsBreadcrumb(
              items: [
                DsBreadcrumbItem(label: 'Website redesign', onPressed: () {}),
                const DsBreadcrumbItem(label: 'Launch plan'),
              ],
            ),
            actions: [
              DsButton.icon(
                icon: const DsIcon(DsIcons.ellipsis),
                semanticLabel: 'More',
                onPressed: () {},
              ),
              DsButton(
                variant: .primary,
                size: .sm,
                onPressed: () {},
                child: const Text('Publish changes'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final first = tester.getRect(find.text('Website redesign'));
    final last = tester.getRect(find.text('Launch plan'));
    expect(last.center.dy, moreOrLessEquals(first.center.dy, epsilon: 1));
    expect(tester.getSize(find.byType(DsPaneHeader)).height, 52);
  });

  testWidgets('levels are links: Enter activates, Space does not', (
    tester,
  ) async {
    await tester.pumpWidget(app(DsBreadcrumb(items: path())));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(pressed, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pressed, ['Acme']);
  });

  testWidgets('the "…" button is a button: Space opens it too', (tester) async {
    await tester.pumpWidget(
      app(
        SizedBox(
          width: 260,
          child: DsBreadcrumb(
            items: path(),
            overflow: DsBreadcrumbOverflow.collapse,
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('Website redesign'), findsOneWidget);
  });

  testWidgets('on touch, "…" sits like a level and still takes 44px of taps', (
    tester,
  ) async {
    // The test platform is Android: a 44px tap target.
    await tester.pumpWidget(
      app(
        SizedBox(
          width: 260,
          child: DsBreadcrumb(
            items: path(),
            overflow: DsBreadcrumbOverflow.collapse,
          ),
        ),
      ),
    );
    final more = find.byWidgetPredicate(
      (w) => w is DsIcon && w.icon == DsIcons.ellipsis,
    );
    final dots = tester.getRect(more);
    final before = tester.getRect(separators().at(0));
    final after = tester.getRect(separators().at(1));
    final acme = tester.getRect(find.text('Acme'));
    // The gaps around "…" match the gap after a text level.
    final textGap = before.left - acme.right;
    expect(dots.left - before.right, moreOrLessEquals(textGap, epsilon: 1));
    expect(after.left - dots.right, moreOrLessEquals(textGap, epsilon: 1));
    // A tap 20px off its center, over the separator, opens the menu.
    await tester.tapAt(dots.center - const Offset(20, 0));
    await tester.pumpAndSettle();
    expect(find.text('Website redesign'), findsOneWidget);
  });
}
