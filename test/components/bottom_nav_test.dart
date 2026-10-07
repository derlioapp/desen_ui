import 'dart:ui' show SemanticsRole, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsBottomNav: disabled destinations, one Tab stop with arrow keys (as
/// tabs), and tabs that screen readers hear with their position.
void main() {
  const labels = ['Ana', 'Gelen', 'Takvim', 'Profil'];

  List<DsBottomNavItem<int>> items({Set<int> disabled = const {}}) => [
    for (var i = 0; i < labels.length; i++)
      DsBottomNavItem(
        value: i,
        icon: const DsIcon(DsIcons.house),
        label: Text(labels[i]),
        enabled: !disabled.contains(i),
      ),
  ];

  /// A bar that keeps its own value; [changes] records every choice.
  Widget nav({
    int initial = 0,
    Set<int> disabled = const {},
    List<int>? changes,
    bool enabled = true,
    FocusNode? focusNode,
    DsBottomNavVariant variant = DsBottomNavVariant.floating,
  }) {
    var value = initial;
    return StatefulBuilder(
      builder: (context, set) => DsBottomNav<int>(
        value: value,
        variant: variant,
        focusNode: focusNode,
        semanticLabel: 'Ana menü',
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
  Widget app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      DsApp(
        builder: (context, child) =>
            Directionality(textDirection: direction, child: child!),
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

  group('the selected icon', () {
    /// The icon theme's fill around each destination's icon.
    List<double?> fills(WidgetTester tester) => [
      for (final e in find.byType(DsIcon).evaluate()) IconTheme.of(e).fill,
    ];

    testWidgets('is filled, the others outlined', (tester) async {
      await tester.pumpWidget(host(nav(initial: 1)));
      expect(fills(tester), [0, 1, 0, 0]);
      await tester.tap(find.text('Takvim'));
      await tester.pumpAndSettle();
      expect(fills(tester), [0, 0, 1, 0]);
    });

    testWidgets('stays outlined with fillIcon false', (tester) async {
      await tester.pumpWidget(
        host(
          DsBottomNav<int>(
            value: 1,
            onChanged: (_) {},
            itemStyle: const DsBottomNavItemStyle(fillIcon: false),
            items: items(),
          ),
        ),
      );
      expect(fills(tester), [0, 0, 0, 0]);
    });
  });

  group('a disabled destination', () {
    testWidgets('ignores taps and looks disabled', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(
        host(
          nav(disabled: {2}, changes: changes),
          theme: DsThemeData(),
        ),
      );
      await tester.tap(find.text('Takvim'));
      await tester.pump();
      expect(changes, isEmpty);
      await tester.tap(find.text('Profil'));
      await tester.pump();
      expect(changes, [3]);

      final theme = DsThemeData();
      final text = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Takvim'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(text.style.color, theme.colors.onDisabled);
    });

    testWidgets('cannot take focus and is announced as disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(nav(disabled: {2})));
      expect(
        Focus.of(tester.element(find.text('Takvim'))).canRequestFocus,
        isFalse,
      );
      final data = semanticsOf(tester, 'Takvim');
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(
        semanticsOf(tester, 'Profil').flagsCollection.isEnabled,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets('a null onChanged disables every destination', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(host(nav(enabled: false, focusNode: node)));
      for (final label in labels) {
        expect(
          Focus.of(tester.element(find.text(label))).canRequestFocus,
          isFalse,
          reason: label,
        );
      }
      node.requestFocus();
      await tester.pump();
      for (final label in labels) {
        expect(focused(tester, label), isFalse, reason: label);
      }
    });

    testWidgets('the current destination of a disabled bar keeps its shape '
        'in the disabled fill', (tester) async {
      final theme = DsThemeData();
      await tester.pumpWidget(host(nav(enabled: false), theme: theme));
      final fills = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => (c.decoration as DsBoxDecoration?)?.color);
      expect(fills, contains(theme.colors.disabled));
      expect(fills, isNot(contains(theme.selectedFill)));
    });
  });

  group('keyboard', () {
    testWidgets('the bar is one Tab stop, the current destination', (
      tester,
    ) async {
      await tester.pumpWidget(app(nav(initial: 1)));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focused(tester, 'Önce'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focused(tester, 'Gelen'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focused(tester, 'Sonra'), isTrue, reason: 'out of the bar');
    });

    testWidgets('Shift+Tab comes back to the current destination', (
      tester,
    ) async {
      await tester.pumpWidget(app(nav(initial: 2)));
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(focused(tester, 'Sonra'), isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      expect(focused(tester, 'Takvim'), isTrue);
    });

    testWidgets('when the current destination is disabled, the first '
        'enabled one is the Tab stop', (tester) async {
      await tester.pumpWidget(app(nav(initial: 0, disabled: {0})));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focused(tester, 'Gelen'), isTrue);
    });

    testWidgets('arrows move focus only, skip disabled ones and wrap', (
      tester,
    ) async {
      final changes = <int>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(nav(disabled: {1}, changes: changes, focusNode: node)),
      );
      node.requestFocus();
      await tester.pump();
      expect(focused(tester, 'Ana'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(tester, 'Takvim'), isTrue, reason: 'Gelen is disabled');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(tester, 'Ana'), isTrue, reason: 'wraps around');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focused(tester, 'Profil'), isTrue);
      expect(changes, isEmpty, reason: 'moving focus does not choose');
    });

    testWidgets('Home and End move focus to the first and last enabled ones', (
      tester,
    ) async {
      final changes = <int>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(nav(initial: 1, disabled: {3}, changes: changes, focusNode: node)),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(focused(tester, 'Takvim'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(focused(tester, 'Ana'), isTrue);
      expect(changes, isEmpty);
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
      expect(focused(tester, 'Gelen'), isTrue, reason: 'left is forward');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(tester, 'Ana'), isTrue);
    });

    testWidgets('Enter and Space choose the focused destination', (
      tester,
    ) async {
      final changes = <int>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(host(nav(changes: changes, focusNode: node)));
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(changes, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(changes, [1]);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(changes, [1, 2]);
      expect(focused(tester, 'Takvim'), isTrue);
    });

    testWidgets('after the arrows, Tab leaves the bar and Shift+Tab comes '
        'back to the current destination', (tester) async {
      await tester.pumpWidget(app(nav()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focused(tester, 'Ana'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(tester, 'Gelen'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focused(tester, 'Sonra'), isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      expect(focused(tester, 'Ana'), isTrue);
    });
  });

  group('screen readers', () {
    testWidgets('buttons in the navigation landmark, the current one '
        'selected, each with its position', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(nav(initial: 1)));
      for (var i = 0; i < labels.length; i++) {
        final data = semanticsOf(tester, labels[i]);
        // Not a tab: tabs switch panels within a page; a destination swaps
        // the screen, as a link in a web navigation does.
        expect(data.role, isNot(SemanticsRole.tab), reason: labels[i]);
        expect(data.flagsCollection.isButton, isTrue, reason: labels[i]);
        expect(data.label, '${labels[i]}\n${i + 1} of 4');
        expect(
          data.flagsCollection.isSelected,
          i == 1 ? Tristate.isTrue : Tristate.isFalse,
          reason: labels[i],
        );
      }
      // No tab bar anywhere above them; the landmark holds the buttons.
      SemanticsNode? node = tester.getSemantics(find.text('Ana'));
      SemanticsNode? landmark;
      while (node != null) {
        final role = node.getSemanticsData().role;
        expect(role, isNot(SemanticsRole.tabBar));
        if (role == SemanticsRole.navigation) landmark = node;
        node = node.parent;
      }
      expect(landmark, isNotNull);
      expect(landmark!.childrenCount, labels.length);
      handle.dispose();
    });

    testWidgets('the bar is a navigation landmark with a default name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(DsBottomNav<int>(value: 0, onChanged: (_) {}, items: items())),
      );
      SemanticsNode? landmark() {
        SemanticsNode? n = tester.getSemantics(find.text('Ana'));
        while (n != null &&
            n.getSemanticsData().role != SemanticsRole.navigation) {
          n = n.parent;
        }
        return n;
      }

      expect(landmark(), isNotNull);
      expect(landmark()!.getSemanticsData().label, 'Navigation');

      await tester.pumpWidget(host(nav()));
      expect(landmark()!.getSemanticsData().label, 'Ana menü');
      handle.dispose();
    });

    testWidgets('the default name speaks the app language', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('tr'),
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: host(
            DsBottomNav<int>(value: 0, onChanged: (_) {}, items: items()),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Gezinme'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a semantic label on an item keeps the position', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsBottomNav<int>(
            value: 0,
            onChanged: (_) {},
            items: const [
              DsBottomNavItem(
                value: 0,
                icon: DsIcon(DsIcons.house),
                label: Text('Ana'),
                semanticLabel: 'Ana sayfa',
              ),
              DsBottomNavItem(
                value: 1,
                icon: DsIcon(DsIcons.user),
                label: Text('Profil'),
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Ana sayfa\n1 of 2'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the position speaks the app language', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('tr'),
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: host(nav()),
        ),
      );
      expect(semanticsOf(tester, 'Gelen').label, 'Gelen\n2, toplam 4');
      handle.dispose();
    });

    testWidgets('the full-width bar holds buttons too', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(SizedBox(width: 360, child: nav(variant: DsBottomNavVariant.bar))),
      );
      final data = semanticsOf(tester, 'Profil');
      expect(data.role, isNot(SemanticsRole.tab));
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, 'Profil\n4 of 4');
      handle.dispose();
    });
  });

  group('haptics', () {
    List<String?> record(WidgetTester tester) {
      final calls = <String?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String?);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      return calls;
    }

    final iOS = DsThemeData(platform: TargetPlatform.iOS);

    testWidgets('a tap on another destination ticks; a disabled one is '
        'silent', (tester) async {
      final calls = record(tester);
      await tester.pumpWidget(host(nav(disabled: {2}), theme: iOS));
      await tester.tap(find.text('Takvim'));
      await tester.pump();
      expect(calls, isEmpty);
      await tester.tap(find.text('Gelen'));
      await tester.pump();
      expect(calls, ['HapticFeedbackType.selectionClick']);
    });

    testWidgets('the keyboard is silent', (tester) async {
      final calls = record(tester);
      final changes = <int>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          nav(changes: changes, focusNode: node),
          theme: iOS,
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(changes, [1]);
      expect(calls, isEmpty);
    });
  });
}
