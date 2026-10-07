import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The dialog's keyboard scrolling and the modals' route settings.
void main() {
  /// An app in a [size] window with one button that runs [onPressed].
  Widget app(
    WidgetTester tester,
    void Function(BuildContext context) onPressed, {
    Size size = const Size(800, 600),
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return DsApp(
      home: Center(
        child: Builder(
          builder: (context) => DsButton(
            onPressed: () => onPressed(context),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a long dialog scrolls from the keyboard with focus on an '
      'action', (tester) async {
    await tester.pumpWidget(
      app(
        tester,
        (context) => showDsDialog<void>(
          context: context,
          builder: (context) => DsDialog(
            title: const Text('Terms'),
            description: Text(
              List.filled(80, 'Every clause of the terms.').join(' '),
            ),
            actions: [
              DsButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Decline'),
              ),
              DsButton(onPressed: () {}, child: const Text('Accept')),
            ],
          ),
        ),
        size: const Size(400, 320),
      ),
    );
    await open(tester);
    final focus = FocusManager.instance.primaryFocus;
    expect(
      (focus?.context?.findAncestorWidgetOfExactType<DsButton>()?.child
              as Text?)
          ?.data,
      'Decline',
    );
    ScrollPosition body() => tester
        .state<ScrollableState>(
          find
              .ancestor(
                of: find.text('Terms'),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    expect(body().maxScrollExtent, greaterThan(100));
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(body().pixels, greaterThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(body().pixels, body().maxScrollExtent);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(body().pixels, lessThan(body().maxScrollExtent));
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(body().pixels, 0);
    expect(FocusManager.instance.primaryFocus, focus, reason: 'focus stays');
    // Escape still closes it, and focus returns as before.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Terms'), findsNothing);
  });

  group('route settings', () {
    Future<RouteSettings?> settingsOf(
      WidgetTester tester,
      void Function(BuildContext context, WidgetBuilder builder) show,
    ) async {
      RouteSettings? settings;
      await tester.pumpWidget(
        app(
          tester,
          (context) => show(context, (context) {
            settings = ModalRoute.of(context)!.settings;
            return const DsDialog(title: Text('Rename'));
          }),
        ),
      );
      await open(tester);
      return settings;
    }

    const named = RouteSettings(name: 'rename', arguments: 'p1');

    testWidgets('showDsDialog passes them', (tester) async {
      final settings = await settingsOf(
        tester,
        (context, builder) => showDsDialog<void>(
          context: context,
          routeSettings: named,
          builder: builder,
        ),
      );
      expect(settings?.name, 'rename');
      expect(settings?.arguments, 'p1');
    });

    testWidgets('showDsModal passes them', (tester) async {
      final settings = await settingsOf(
        tester,
        (context, builder) => showDsModal<void>(
          context: context,
          routeSettings: named,
          builder: builder,
        ),
      );
      expect(settings?.name, 'rename');
      expect(settings?.arguments, 'p1');
    });

    testWidgets('navigator observers see the name', (tester) async {
      final pushed = <String?>[];
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        DsApp(
          navigatorObservers: [_Observer(pushed)],
          home: Center(
            child: Builder(
              builder: (context) => DsButton(
                onPressed: () => showDsDialog<void>(
                  context: context,
                  routeSettings: named,
                  builder: (_) => const DsDialog(title: Text('Rename')),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await open(tester);
      expect(pushed.last, 'rename');
    });
  });
}

class _Observer extends NavigatorObserver {
  _Observer(this.pushed);

  final List<String?> pushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushed.add(route.settings.name);
}
