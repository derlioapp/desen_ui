import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `scrim: DsScrim.clear` leaves the page undimmed behind a modal (a live
/// preview) while the barrier still blocks and dismisses.
void main() {
  Widget app(
    void Function(BuildContext context) open, {
    VoidCallback? onPage,
  }) => MediaQuery(
    data: const MediaQueryData(size: Size(390, 800)),
    child: DsApp(
      home: Column(
        children: [
          Builder(
            builder: (context) => DsButton(
              onPressed: () => open(context),
              child: const Text('Open'),
            ),
          ),
          DsButton(onPressed: onPage, child: const Text('Page')),
        ],
      ),
    ),
  );

  /// The opacity the barrier paints at, 0 when it paints nothing.
  double barrierAlpha(WidgetTester tester) {
    final boxes = find.descendant(
      of: find.byType(ModalBarrier),
      matching: find.byType(ColoredBox),
    );
    if (boxes.evaluate().isEmpty) return 0;
    return tester.widget<ColoredBox>(boxes).color.a;
  }

  Future<void> openPanel(WidgetTester tester, DsScrim scrim) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        (context) => showDsPanel<void>(
          context: context,
          presentation: DsPanelPresentation.bottom,
          scrim: scrim,
          builder: (_) =>
              const DsPanel(title: Text('Preview'), child: Text('Body')),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the default scrim dims the page', (tester) async {
    await openPanel(tester, DsScrim.dim);
    expect(barrierAlpha(tester), greaterThan(0));
  });

  testWidgets('a clear scrim leaves the page undimmed', (tester) async {
    await openPanel(tester, DsScrim.clear);
    expect(find.text('Body'), findsOneWidget);
    expect(barrierAlpha(tester), 0);
  });

  testWidgets('a tap on the page still closes a clear-scrim panel and does '
      'not reach the page', (tester) async {
    var pagePressed = 0;
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        (context) => showDsPanel<void>(
          context: context,
          presentation: DsPanelPresentation.bottom,
          scrim: DsScrim.clear,
          builder: (_) =>
              const DsPanel(title: Text('Preview'), child: Text('Body')),
        ),
        onPage: () => pagePressed++,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Page'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(pagePressed, 0);
    expect(find.text('Body'), findsNothing);
  });

  testWidgets('a non-dismissible clear-scrim panel stays on a tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        (context) => showDsPanel<void>(
          context: context,
          presentation: DsPanelPresentation.bottom,
          scrim: DsScrim.clear,
          dismissible: false,
          builder: (_) =>
              const DsPanel(title: Text('Preview'), child: Text('Body')),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('showDsModal takes the clear scrim too', (tester) async {
    await tester.pumpWidget(
      app(
        (context) => showDsModal<void>(
          context: context,
          scrim: DsScrim.clear,
          builder: (_) => const DsDialog(title: Text('Hello')),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    expect(barrierAlpha(tester), 0);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsNothing);
  });

  group('showDsDialog', () {
    Future<void> openDialog(WidgetTester tester, {DsScrim? scrim}) async {
      await tester.pumpWidget(
        app(
          (context) => scrim == null
              ? showDsDialog<void>(
                  context: context,
                  builder: (_) => const DsDialog(title: Text('Hello')),
                )
              : showDsDialog<void>(
                  context: context,
                  scrim: scrim,
                  builder: (_) => const DsDialog(title: Text('Hello')),
                ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
    }

    testWidgets('dims the page by default', (tester) async {
      await openDialog(tester);
      expect(barrierAlpha(tester), greaterThan(0));
    });

    testWidgets('a clear scrim leaves the page undimmed and a tap on it '
        'still closes the dialog without reaching the page', (tester) async {
      await openDialog(tester, scrim: DsScrim.clear);
      expect(barrierAlpha(tester), 0);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsNothing);
    });

    testWidgets('a non-dismissible clear-scrim dialog stays on a tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          (context) => showDsDialog<void>(
            context: context,
            scrim: DsScrim.clear,
            dismissible: false,
            builder: (_) => const DsDialog(title: Text('Hello')),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
