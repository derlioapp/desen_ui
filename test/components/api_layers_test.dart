import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pre-1.0 API round for layers: show functions take `context` by name
/// and `useRootNavigator` (rule 9); DsMenuAnchor and DsPopover make their
/// own controller and hand it to a trigger builder (rule 10).
void main() {
  group('useRootNavigator', () {
    /// An app whose home holds a nested navigator with one button that
    /// runs [show] with its context.
    Widget nested(void Function(BuildContext context) show) => DsApp(
      home: Navigator(
        onGenerateRoute: (_) => DsPageRoute<void>(
          builder: (context) => Center(
            child: DsButton(
              onPressed: () => show(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    /// The navigators above [text], innermost first.
    List<NavigatorState> navigatorsOf(WidgetTester tester, String text) {
      final result = <NavigatorState>[];
      tester.element(find.text(text)).visitAncestorElements((e) {
        if (e is StatefulElement && e.state is NavigatorState) {
          result.add(e.state as NavigatorState);
        }
        return true;
      });
      return result;
    }

    for (final root in [true, false]) {
      testWidgets('dialog, confirm and panel open on the '
          '${root ? 'root' : 'nearest'} navigator', (tester) async {
        final shows = <void Function(BuildContext)>[
          (context) => showDsDialog<void>(
            context: context,
            useRootNavigator: root,
            builder: (_) => const DsDialog(title: Text('Layer')),
          ),
          (context) => showDsConfirm(
            context: context,
            title: 'Layer',
            useRootNavigator: root,
          ),
          (context) => showDsPanel<void>(
            context: context,
            useRootNavigator: root,
            builder: (_) =>
                const DsPanel(title: Text('Layer'), child: SizedBox()),
          ),
        ];
        for (final show in shows) {
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(nested(show));
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          // The layer sits in one navigator: the root, or the nested one.
          expect(navigatorsOf(tester, 'Layer').length, root ? 1 : 2);
        }
      });
    }
  });

  group('optional controllers', () {
    testWidgets('a menu anchor without a controller opens from its builder', (
      tester,
    ) async {
      var chosen = 0;
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: DsMenuAnchor(
              items: [
                DsMenuItem(
                  label: const Text('Edit'),
                  onPressed: () => chosen++,
                ),
              ],
              builder: (context, controller, child) =>
                  DsButton(onPressed: controller.toggle, child: child!),
              child: const Text('More'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(chosen, 1);
      expect(find.text('Edit'), findsNothing, reason: 'closed on choice');
    });

    testWidgets('a popover without a controller toggles from its builder', (
      tester,
    ) async {
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: DsPopover(
              contentBuilder: (_) => const Text('Inside'),
              builder: (context, controller, _) => DsButton(
                onPressed: controller.toggle,
                child: const Text('Share'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(find.text('Inside'), findsOneWidget);
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(find.text('Inside'), findsNothing);
    });

    testWidgets('a given controller still drives a plain child', (
      tester,
    ) async {
      final controller = DsOverlayController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: DsPopover(
              controller: controller,
              contentBuilder: (_) => const Text('Inside'),
              child: const Text('Anchor'),
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();
      expect(find.text('Inside'), findsOneWidget);
    });
  });
}
