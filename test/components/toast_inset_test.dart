import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// DsToastInset: toasts keep clear of bottom chrome (a tab bar, a mini
/// player) while it shows, and come back down when it goes.
void main() {
  const screen = Size(400, 800);

  /// An app whose page has [bottom] chrome under a button that shows a
  /// toast.
  Widget app({
    Widget? bottom,
    MediaQueryData media = const MediaQueryData(size: screen),
  }) => MediaQuery(
    data: media,
    child: DsApp(
      home: Column(
        children: [
          Expanded(
            child: Center(
              child: Builder(
                builder: (context) => DsButton(
                  onPressed: () =>
                      showDsToast(context: context, title: 'Saved'),
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
          ?bottom,
        ],
      ),
    ),
  );

  /// Pumps [widget] in a window the size of [screen].
  Future<void> pump(WidgetTester tester, Widget widget) {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = screen;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(widget);
  }

  /// Shows the toast and lets it settle.
  Future<Rect> toast(WidgetTester tester) async {
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    return tester.getRect(find.byType(DsToast));
  }

  Widget bar(double height, {Key? key}) =>
      SizedBox(key: key, height: height, width: double.infinity);

  testWidgets('without chrome, 16px above the bottom', (tester) async {
    await pump(tester, app());
    final rect = await toast(tester);
    expect(rect.bottom, moreOrLessEquals(screen.height - 16, epsilon: .5));
  });

  testWidgets('a marked bar keeps toasts above it', (tester) async {
    await pump(tester, app(bottom: DsToastInset(child: bar(80))));
    final rect = await toast(tester);
    expect(rect.bottom, moreOrLessEquals(screen.height - 80 - 16, epsilon: .5));
  });

  testWidgets('stacked bars: toasts clear the one that reaches highest', (
    tester,
  ) async {
    await pump(
      tester,
      app(
        bottom: Column(
          children: [
            DsToastInset(child: bar(56)),
            DsToastInset(child: bar(64)),
          ],
        ),
      ),
    );
    final rect = await toast(tester);
    expect(
      rect.bottom,
      moreOrLessEquals(screen.height - 120 - 16, epsilon: .5),
    );
  });

  testWidgets('a toast moves when the chrome comes and goes', (tester) async {
    late StateSetter set;
    var playing = false;
    await pump(
      tester,
      app(
        bottom: StatefulBuilder(
          builder: (context, s) {
            set = s;
            return playing
                ? DsToastInset(child: bar(72))
                : const SizedBox.shrink();
          },
        ),
      ),
    );
    var rect = await toast(tester);
    expect(rect.bottom, moreOrLessEquals(screen.height - 16, epsilon: .5));

    set(() => playing = true);
    await tester.pump();
    await tester.pump();
    rect = tester.getRect(find.byType(DsToast));
    expect(rect.bottom, moreOrLessEquals(screen.height - 72 - 16, epsilon: .5));

    set(() => playing = false);
    await tester.pump();
    await tester.pump();
    rect = tester.getRect(find.byType(DsToast));
    expect(rect.bottom, moreOrLessEquals(screen.height - 16, epsilon: .5));
  });

  testWidgets('chrome slid off the screen or of zero height reserves '
      'nothing', (tester) async {
    await pump(
      tester,
      app(
        bottom: Column(
          children: [
            DsToastInset(child: bar(0)),
            Transform.translate(
              offset: const Offset(0, 200),
              child: DsToastInset(child: bar(60)),
            ),
          ],
        ),
      ),
    );
    final rect = await toast(tester);
    // The bar is measured where it is painted: slid below the screen, it
    // covers nothing.
    expect(rect.bottom, moreOrLessEquals(screen.height - 16, epsilon: .5));
  });

  testWidgets('the on-screen keyboard wins when it reaches higher', (
    tester,
  ) async {
    await pump(
      tester,
      app(
        bottom: DsToastInset(child: bar(80)),
        media: const MediaQueryData(
          size: screen,
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
      ),
    );
    final rect = await toast(tester);
    expect(
      rect.bottom,
      moreOrLessEquals(screen.height - 300 - 16, epsilon: .5),
    );
  });

  testWidgets('DsBottomNav keeps toasts above itself', (tester) async {
    const nav = Key('nav');
    await pump(
      tester,
      app(
        bottom: DsBottomNav<int>(
          key: nav,
          value: 0,
          onChanged: (_) {},
          items: const [
            DsBottomNavItem(
              value: 0,
              icon: DsIcon(DsIcons.house),
              label: Text('Home'),
            ),
            DsBottomNavItem(
              value: 1,
              icon: DsIcon(DsIcons.search),
              label: Text('Search'),
            ),
          ],
        ),
      ),
    );
    final rect = await toast(tester);
    final bar = tester.getRect(find.byKey(nav));
    expect(rect.bottom, moreOrLessEquals(bar.top - 16, epsilon: .5));
  });

  testWidgets('a page covered by another route reserves nothing', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await pump(
      tester,
      MediaQuery(
        data: const MediaQueryData(size: screen),
        child: DsApp(
          navigatorKey: navigator,
          home: Column(
            children: [
              const Expanded(child: SizedBox()),
              DsToastInset(child: bar(80)),
            ],
          ),
        ),
      ),
    );
    navigator.currentState!.push(
      DsPageRoute<void>(
        builder: (context) => Center(
          child: DsButton(
            onPressed: () => showDsToast(context: context, title: 'Saved'),
            child: const Text('Go'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rect = await toast(tester);
    expect(rect.bottom, moreOrLessEquals(screen.height - 16, epsilon: .5));
  });
}
