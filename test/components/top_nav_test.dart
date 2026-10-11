import 'dart:ui' show SemanticsRole, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsTopNav: navigation that reports the current destination too, one Tab
/// stop with arrow keys, buttons in a landmark, and a row that scrolls.
void main() {
  const labels = ['Radyo', 'Podcast', 'TV', 'Ben'];

  List<DsTopNavItem<int>> items({Set<int> disabled = const {}}) => [
    for (var i = 0; i < labels.length; i++)
      DsTopNavItem(
        value: i,
        label: Text(labels[i]),
        enabled: !disabled.contains(i),
      ),
  ];

  /// A row that keeps its own value; [changes] records every choice.
  Widget nav({
    int initial = 0,
    Set<int> disabled = const {},
    List<int>? changes,
    bool enabled = true,
    FocusNode? focusNode,
  }) {
    var value = initial;
    return StatefulBuilder(
      builder: (context, set) => DsTopNav<int>(
        value: value,
        focusNode: focusNode,
        onChanged: enabled
            ? (v) {
                changes?.add(v);
                set(() => value = v);
              }
            : null,
        items: items(disabled: disabled),
      ),
    );
  }

  /// An app root, so Tab moves focus; a button on either side of [child].
  Widget app(Widget child) => DsApp(
    home: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DsButton(onPressed: () {}, child: const Text('Önce')),
          child,
          DsButton(onPressed: () {}, child: const Text('Sonra')),
        ],
      ),
    ),
  );

  bool focused(WidgetTester tester, String text) =>
      Focus.of(tester.element(find.text(text))).hasPrimaryFocus;

  SemanticsData semanticsOf(WidgetTester tester, String text) =>
      tester.getSemantics(find.text(text)).getSemanticsData();

  group('choosing', () {
    testWidgets('reports the chosen destination, and the current one too', (
      tester,
    ) async {
      final changes = <int>[];
      await tester.pumpWidget(host(nav(changes: changes)));
      await tester.tap(find.text('TV'));
      await tester.pump();
      await tester.tap(find.text('TV'));
      await tester.pump();
      expect(changes, [2, 2]);
    });

    testWidgets('a disabled destination and a null onChanged ignore taps', (
      tester,
    ) async {
      final changes = <int>[];
      await tester.pumpWidget(host(nav(disabled: {1}, changes: changes)));
      await tester.tap(find.text('Podcast'));
      expect(changes, isEmpty);
      await tester.pumpWidget(host(nav(enabled: false)));
      await tester.tap(find.text('TV'));
      expect(changes, isEmpty);
      expect(
        semanticsOf(tester, 'TV').flagsCollection.isEnabled,
        isNot(Tristate.isTrue),
      );
    });

    testWidgets('moving the selection moves no other destination', (
      tester,
    ) async {
      await tester.pumpWidget(host(nav()));
      Map<String, Rect> rects() => {
        for (final l in labels) l: tester.getRect(find.text(l)),
      };
      final before = rects();
      await tester.tap(find.text('Podcast'));
      await tester.pumpAndSettle();
      expect(rects(), before);
    });
  });

  group('keyboard', () {
    testWidgets('the row is one Tab stop, the current destination', (
      tester,
    ) async {
      await tester.pumpWidget(app(nav(initial: 2)));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focused(tester, 'TV'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focused(tester, 'Sonra'), isTrue, reason: 'out of the row');
    });

    testWidgets('arrows move focus only, skip disabled ones and wrap; '
        'Enter chooses', (tester) async {
      final changes = <int>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(nav(disabled: {1}, changes: changes, focusNode: node)),
      );
      node.requestFocus();
      await tester.pump();
      expect(focused(tester, 'Radyo'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(tester, 'TV'), isTrue, reason: 'Podcast is disabled');
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(tester, 'Radyo'), isTrue, reason: 'wraps around');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focused(tester, 'Ben'), isTrue);
      expect(changes, isEmpty, reason: 'moving focus does not choose');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(changes, [3]);
    });

    testWidgets('arrows are mirrored in RTL', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(nav(focusNode: node), direction: TextDirection.rtl),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focused(tester, 'Podcast'), isTrue);
    });
  });

  group('screen readers', () {
    testWidgets('buttons in a navigation landmark, the current one '
        'selected, each with its position', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(nav(initial: 1)));
      for (var i = 0; i < labels.length; i++) {
        final data = semanticsOf(tester, labels[i]);
        expect(data.role, isNot(SemanticsRole.tab), reason: labels[i]);
        expect(data.flagsCollection.isButton, isTrue, reason: labels[i]);
        expect(data.label, '${labels[i]}\n${i + 1} of 4');
        expect(
          data.flagsCollection.isSelected,
          i == 1 ? Tristate.isTrue : Tristate.isFalse,
          reason: labels[i],
        );
      }
      SemanticsNode? node = tester.getSemantics(find.text('Radyo'));
      while (node != null &&
          node.getSemanticsData().role != SemanticsRole.navigation) {
        node = node.parent;
      }
      expect(node, isNotNull);
      expect(node!.getSemanticsData().label, 'Navigation');
      // Every destination is inside it.
      var buttons = 0;
      void count(SemanticsNode n) {
        if (n.getSemanticsData().flagsCollection.isButton) buttons++;
        n.visitChildren((c) {
          count(c);
          return true;
        });
      }

      count(node);
      expect(buttons, labels.length);
      handle.dispose();
    });

    testWidgets('a semantic label on an item keeps the position', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsTopNav<int>(
            value: 0,
            onChanged: (_) {},
            items: const [
              DsTopNavItem(
                value: 0,
                label: Text('Ben'),
                semanticLabel: 'Profilim',
              ),
              DsTopNavItem(value: 1, label: Text('TV')),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Profilim\n1 of 2'), findsOneWidget);
      handle.dispose();
    });
  });

  group('look', () {
    testWidgets('the current destination takes the selection fill; an icon '
        'takes the ink', (tester) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        host(
          DsTopNav<int>(
            value: 1,
            onChanged: (_) {},
            items: const [
              DsTopNavItem(
                value: 0,
                icon: DsIcon(DsIcons.house),
                label: Text('Radyo'),
              ),
              DsTopNavItem(value: 1, label: Text('TV')),
            ],
          ),
          theme: theme,
        ),
      );
      DsBoxDecoration decorationOf(String text) =>
          tester
                  .widget<AnimatedContainer>(
                    find
                        .ancestor(
                          of: find.text(text),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration!
              as DsBoxDecoration;
      expect(decorationOf('TV').color, theme.selectedFill);
      expect(decorationOf('Radyo').color?.a, 0);
      expect(
        IconTheme.of(tester.element(find.byType(DsIcon))).color,
        theme.colors.textMuted,
      );
      expect(tester.getSize(find.byType(AnimatedContainer).first).height, 32);
    });

    testWidgets('a theme style reaches every destination', (tester) async {
      await tester.pumpWidget(
        host(
          DsTopNavTheme(
            data: const DsTopNavThemeData(style: DsTopNavStyle(height: 40)),
            child: nav(),
          ),
        ),
      );
      for (final l in labels) {
        expect(
          tester
              .getSize(
                find
                    .ancestor(
                      of: find.text(l),
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .height,
          40,
        );
      }
    });
  });

  group('a row that does not fit', () {
    Widget narrow(Widget child) => host(SizedBox(width: 160, child: child));

    double offset(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

    bool shown(WidgetTester tester, String text) {
      final view = tester.getRect(find.byType(Scrollable));
      final item = tester.getRect(
        find
            .ancestor(
              of: find.text(text),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return item.left >= view.left - .5 && item.right <= view.right + .5;
    }

    testWidgets('opens on the current destination, and follows it', (
      tester,
    ) async {
      final key = GlobalKey<State>();
      var value = 3;
      late StateSetter set;
      await tester.pumpWidget(
        narrow(
          StatefulBuilder(
            key: key,
            builder: (context, s) {
              set = s;
              return DsTopNav<int>(
                value: value,
                onChanged: (v) => s(() => value = v),
                items: items(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(offset(tester), greaterThan(0));
      expect(shown(tester, 'Ben'), isTrue);
      set(() => value = 0);
      await tester.pumpAndSettle();
      expect(shown(tester, 'Radyo'), isTrue);
    });

    testWidgets('the arrow keys bring the focused destination into view', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(narrow(nav(focusNode: node)));
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(focused(tester, 'Ben'), isTrue);
      expect(shown(tester, 'Ben'), isTrue);
    });

    testWidgets('built under a covering page, it shows the current one '
        'once uncovered', (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        host(
          Navigator(
            key: navigator,
            pages: [
              PlainPage(
                key: const ValueKey('root'),
                child: Center(
                  child: SizedBox(width: 160, child: nav(initial: 3)),
                ),
              ),
              const PlainPage(
                key: ValueKey('detail'),
                child: SizedBox.expand(),
              ),
            ],
            onDidRemovePage: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(shown(tester, 'Ben'), isTrue);
    });
  });
}
