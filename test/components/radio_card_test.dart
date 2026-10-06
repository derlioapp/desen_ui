import 'dart:ui' show CheckedState, SemanticsValidationResult;

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/components/selection/radio_circle.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsRadioCard: a radio drawn as a card inside a DsRadioGroup (plans,
/// themes), and the description line of DsRadio and DsCheckbox.
void main() {
  /// A group of three plan cards that keeps its own value.
  Widget plans({
    String? initial = 'free',
    List<String?>? seen,
    bool groupEnabled = true,
    bool error = false,
    Set<String> disabled = const {},
    DsRadioCardStyle? style,
    Widget? extra,
  }) {
    var value = initial;
    return StatefulBuilder(
      builder: (context, set) => DsRadioGroup<String>(
        value: value,
        error: error,
        onChanged: groupEnabled
            ? (v) => set(() {
                value = v;
                seen?.add(v);
              })
            : null,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              for (final (v, title, detail) in [
                ('free', 'Free', 'For personal projects'),
                ('pro', 'Pro', 'For teams up to 20'),
                ('team', 'Team', 'Unlimited members'),
              ])
                DsRadioCard<String>(
                  value: v,
                  label: Text(title),
                  description: Text(detail),
                  enabled: !disabled.contains(v),
                  style: style,
                  child: v == 'pro' ? extra : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The card box painted for the card titled [title].
  DsBoxDecoration card(WidgetTester tester, String title) =>
      tester
              .widget<AnimatedContainer>(
                find
                    .ancestor(
                      of: find.text(title),
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .decoration!
          as DsBoxDecoration;

  /// The radio circle's style inside the card titled [title].
  DsRadioStyle circle(WidgetTester tester, String title) => tester
      .widget<RadioCircle>(
        find.descendant(
          of: find.ancestor(
            of: find.text(title),
            matching: find.byType(DsRadioCard<String>),
          ),
          matching: find.byType(RadioCircle),
        ),
      )
      .style;

  testWidgets('the whole card selects: title, description and extra '
      'content', (tester) async {
    final seen = <String?>[];
    await tester.pumpWidget(
      host(plans(seen: seen, extra: const Text('₺120 / month'))),
    );
    await tester.tap(find.text('For teams up to 20'));
    await tester.pump();
    expect(seen, ['pro']);
    await tester.tap(find.text('Team'));
    await tester.pump();
    expect(seen, ['pro', 'team']);
    await tester.tap(find.text('₺120 / month'));
    await tester.pump();
    expect(seen.last, 'pro');
  });

  testWidgets('disabled cards and a disabled group do not select', (
    tester,
  ) async {
    final seen = <String?>[];
    await tester.pumpWidget(host(plans(seen: seen, disabled: {'team'})));
    await tester.tap(find.text('Team'));
    await tester.pump();
    expect(seen, isEmpty);
    await tester.pumpWidget(host(plans(seen: seen, groupEnabled: false)));
    await tester.tap(find.text('Pro'));
    await tester.pump();
    expect(seen, isEmpty);
  });

  testWidgets('roving focus: one Tab stop on the selected card; arrows '
      'move the selection', (tester) async {
    final seen = <String?>[];
    await tester.pumpWidget(
      DsApp(
        home: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              plans(initial: 'pro', seen: seen),
              DsButton(onPressed: () {}, child: const Text('After')),
            ],
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      focused.findAncestorWidgetOfExactType<DsRadioCard<String>>()!.value,
      'pro',
      reason: 'Tab lands on the selected card',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(seen.last, 'team');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(seen.last, 'free', reason: 'wraps to the first');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus!.context!
          .findAncestorWidgetOfExactType<DsButton>(),
      isNotNull,
      reason: 'the next Tab leaves the group',
    );
  });

  testWidgets('keyboard focus rings the card, not the circle', (tester) async {
    useTraditionalHighlights();
    final theme = DsThemeData();
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      host(
        theme: theme,
        DsRadioGroup<String>(
          value: 'a',
          onChanged: (_) {},
          child: DsRadioCard<String>(
            value: 'a',
            focusNode: node,
            label: const Text('A'),
          ),
        ),
      ),
    );
    node.requestFocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.f12);
    await tester.pumpAndSettle();
    expect(card(tester, 'A').shadows, containsAllInOrder(theme.focusShadows));
    final circleBox =
        tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: find.byType(RadioCircle),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as DsBoxDecoration;
    for (final ring in theme.focusShadows) {
      expect(circleBox.shadows, isNot(contains(ring)));
    }
  });

  testWidgets('semantics: a checked radio in a group, named by its text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(plans(initial: 'pro')));
    final data = tester.getSemantics(find.text('Pro')).getSemanticsData();
    expect(data.flagsCollection.isChecked, CheckedState.isTrue);
    expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    expect(data.label, contains('Pro'));
    // The description is read after the name and state, as the hint.
    expect(data.label, isNot(contains('For teams up to 20')));
    expect(data.hint, 'For teams up to 20');
    final free = tester.getSemantics(find.text('Free')).getSemanticsData();
    expect(free.flagsCollection.isChecked, CheckedState.isFalse);
    handle.dispose();
  });

  testWidgets('a semantic label replaces the card text', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        DsRadioGroup<int>(
          value: 1,
          onChanged: (_) {},
          child: const DsRadioCard<int>(
            value: 1,
            label: Text('Aa'),
            semanticLabel: 'Serif theme',
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(DsRadioCard<int>)),
      isSemantics(label: 'Serif theme', isChecked: true),
    );
    handle.dispose();
  });

  testWidgets('soft selection: the tint, the accent circle', (tester) async {
    final theme = DsThemeData();
    await tester.pumpWidget(host(plans(initial: 'pro'), theme: theme));
    expect(card(tester, 'Pro').color, theme.colors.selection);
    expect(card(tester, 'Free').color, theme.colors.surface);
    expect(circle(tester, 'Pro').background, theme.colors.accent);
  });

  testWidgets('strong selection: the filled card, an inverted circle', (
    tester,
  ) async {
    final theme = DsThemeData(selectionStyle: DsSelectionStyle.strong);
    await tester.pumpWidget(
      host(
        plans(initial: 'pro', extra: const Text('₺120')),
        theme: theme,
      ),
    );
    expect(card(tester, 'Pro').color, theme.colors.selectionStrong);
    final r = circle(tester, 'Pro');
    expect(r.background, theme.onSelectedFill);
    expect(r.dotColor, theme.selectedFill);
    expect(
      tester
          .widget<DefaultTextStyle>(
            find
                .ancestor(
                  of: find.text('For teams up to 20'),
                  matching: find.byType(DefaultTextStyle),
                )
                .first,
          )
          .style
          .color,
      theme.onSelectedFill,
      reason: 'the description reads on the fill',
    );
    expect(
      tester
          .widget<RichText>(
            find.descendant(
              of: find.text('₺120'),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!
          .color,
      theme.onSelectedFill,
      reason: 'extra content takes the title color',
    );
  });

  testWidgets('a group error draws a 2px error outline and reads invalid', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final theme = DsThemeData();
    await tester.pumpWidget(
      host(plans(initial: null, error: true), theme: theme),
    );
    final edge = card(tester, 'Pro').shadows.where((s) => s.inset).last;
    expect(edge.spread, 2);
    expect(
      tester
          .getSemantics(find.byType(DsRadioCard<String>).first)
          .getSemanticsData()
          .validationResult,
      SemanticsValidationResult.invalid,
    );
    handle.dispose();
  });

  testWidgets('style and theme layers (Ö1, Ö3); showRadio: false', (
    tester,
  ) async {
    const brand = Color(0xFF0B6E4F);
    await tester.pumpWidget(
      host(
        DsRadioCardTheme(
          data: const DsRadioCardThemeData(
            style: DsRadioCardStyle(showRadio: false),
          ),
          child: plans(
            initial: 'pro',
            style: const DsRadioCardStyle(
              selected: DsRadioCardStyle(background: brand),
            ),
          ),
        ),
      ),
    );
    expect(card(tester, 'Pro').color, brand);
    expect(find.byType(RadioCircle), findsNothing);
  });

  testWidgets('works in an unbounded Row and at 2x text', (tester) async {
    await tester.pumpWidget(
      host(
        textScale: 2,
        DsRadioGroup<int>(
          value: 1,
          onChanged: (_) {},
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsRadioCard<int>(
                value: 1,
                label: Text('Monthly'),
                description: Text('Billed every month'),
              ),
              DsRadioCard<int>(value: 2, label: Text('Yearly')),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  group('descriptions on DsCheckbox and DsRadio', () {
    const title = 'Weekly summary';
    const detail = 'Every Monday morning';

    testWidgets('checkbox: the description toggles, reads as the hint '
        'and is muted', (tester) async {
      final handle = tester.ensureSemantics();
      final theme = DsThemeData();
      var on = false;
      await tester.pumpWidget(
        host(
          theme: theme,
          StatefulBuilder(
            builder: (context, set) => DsCheckbox(
              value: on,
              onChanged: (v) => set(() => on = v!),
              label: const Text(title),
              description: const Text(detail),
            ),
          ),
        ),
      );
      await tester.tap(find.text(detail));
      await tester.pump();
      expect(on, isTrue);
      // Read after the name and state, as the hint (9edf266).
      final data = tester
          .getSemantics(find.byType(DsCheckbox))
          .getSemanticsData();
      expect(data.label, title);
      expect(data.hint, detail);
      expect(
        tester
            .widget<RichText>(
              find.descendant(
                of: find.text(detail),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style!
            .color,
        theme.colors.textMuted,
      );
      // Under the label.
      expect(
        tester.getTopLeft(find.text(detail)).dy,
        greaterThan(tester.getBottomLeft(find.text(title)).dy - .5),
      );
      expect(
        tester.getTopLeft(find.text(detail)).dx,
        tester.getTopLeft(find.text(title)).dx,
      );
      handle.dispose();
    });

    testWidgets('checkbox: disabled mutes the description', (tester) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        host(
          theme: theme,
          const DsCheckbox(
            value: false,
            onChanged: null,
            label: Text(title),
            description: Text(detail),
          ),
        ),
      );
      expect(
        tester
            .widget<RichText>(
              find.descendant(
                of: find.text(detail),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style!
            .color,
        theme.colors.onDisabled,
      );
    });

    testWidgets('radio: the description selects and reads as the hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      String? value;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) => DsRadioGroup<String>(
              value: value,
              onChanged: (v) => set(() => value = v),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DsRadio<String>(
                    value: 'express',
                    label: Text(title),
                    description: Text(detail),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text(detail));
      await tester.pump();
      expect(value, 'express');
      // Read after the name and state, as the hint (9edf266).
      final data = tester
          .getSemantics(find.byType(DsRadio<String>))
          .getSemanticsData();
      expect(data.label, title);
      expect(data.hint, detail);
      handle.dispose();
    });

    testWidgets('the control sits on the label line, above the description', (
      tester,
    ) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        host(
          theme: theme,
          DsRadioGroup<String>(
            value: 'a',
            onChanged: (_) {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsCheckbox(
                  value: true,
                  onChanged: (_) {},
                  label: const Text(title),
                  description: const Text(detail),
                ),
                const DsRadio<String>(
                  value: 'a',
                  label: Text(title),
                  description: Text(detail),
                ),
              ],
            ),
          ),
        ),
      );
      for (final (i, type, size) in [
        (0, DsCheckbox, DsCheckbox.defaultStyle(theme).size!),
        (1, DsRadio<String>, DsRadio.defaultStyle(theme).size!),
      ]) {
        final box = tester.getRect(
          find
              .descendant(
                of: find.byType(type),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is AnimatedContainer &&
                      w.constraints?.maxHeight == size,
                ),
              )
              .first,
        );
        final line = tester.getRect(find.text(title).at(i));
        expect(
          box.center.dy,
          moreOrLessEquals(line.center.dy, epsilon: .5),
          reason: '$type sits on the label line',
        );
      }
    });

    testWidgets('a description without a label', (tester) async {
      await tester.pumpWidget(
        host(
          DsCheckbox(
            value: false,
            onChanged: (_) {},
            description: const Text(detail),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(detail), findsOneWidget);
    });
  });

  group('DsRadioGroup keys', () {
    /// A horizontal group of radios a, b, c, d (c disabled) that keeps its
    /// own value; [node] focuses radio a.
    Widget row({
      required List<String?> seen,
      required FocusNode node,
      String initial = 'a',
      TextDirection direction = TextDirection.ltr,
      bool cards = false,
    }) {
      String? value = initial;
      Widget option(String v) => cards
          ? DsRadioCard<String>(
              value: v,
              label: Text(v.toUpperCase()),
              enabled: v != 'c',
              focusNode: v == initial ? node : null,
            )
          : DsRadio<String>(
              value: v,
              label: Text(v.toUpperCase()),
              enabled: v != 'c',
              focusNode: v == initial ? node : null,
            );
      return host(
        direction: direction,
        StatefulBuilder(
          builder: (context, set) => DsRadioGroup<String>(
            value: value,
            onChanged: (v) => set(() {
              value = v;
              seen.add(v);
            }),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                for (final v in ['a', 'b', 'c', 'd']) option(v),
              ],
            ),
          ),
        ),
      );
    }

    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pump();
    }

    String focusedValue() {
      final context = FocusManager.instance.primaryFocus!.context!;
      return context.findAncestorWidgetOfExactType<DsRadio<String>>()?.value ??
          context.findAncestorWidgetOfExactType<DsRadioCard<String>>()!.value;
    }

    for (final cards in [false, true]) {
      final kind = cards ? 'radio cards' : 'radios';

      testWidgets('$kind: Home and End select the first and last enabled '
          'option and move focus', (tester) async {
        final seen = <String?>[];
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(row(seen: seen, node: node, cards: cards));
        node.requestFocus();
        await tester.pump();
        await press(tester, LogicalKeyboardKey.end);
        expect(seen.last, 'd');
        expect(focusedValue(), 'd');
        await press(tester, LogicalKeyboardKey.home);
        expect(seen.last, 'a');
        expect(focusedValue(), 'a');
      });

      testWidgets('$kind: arrows skip disabled options and wrap', (
        tester,
      ) async {
        final seen = <String?>[];
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(row(seen: seen, node: node, cards: cards));
        node.requestFocus();
        await tester.pump();
        await press(tester, LogicalKeyboardKey.arrowRight);
        expect(seen.last, 'b');
        await press(tester, LogicalKeyboardKey.arrowDown);
        expect(seen.last, 'd', reason: 'c is disabled');
        await press(tester, LogicalKeyboardKey.arrowRight);
        expect(seen.last, 'a', reason: 'wraps to the first');
        await press(tester, LogicalKeyboardKey.arrowUp);
        expect(seen.last, 'd', reason: 'wraps back to the last');
      });

      testWidgets('$kind: Left and Right mirror in RTL', (tester) async {
        final seen = <String?>[];
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(
          row(
            seen: seen,
            node: node,
            cards: cards,
            direction: TextDirection.rtl,
          ),
        );
        // a is the rightmost option in RTL.
        expect(
          tester.getCenter(find.text('A')).dx,
          greaterThan(tester.getCenter(find.text('B')).dx),
        );
        node.requestFocus();
        await tester.pump();
        await press(tester, LogicalKeyboardKey.arrowLeft);
        expect(seen.last, 'b', reason: 'Left goes toward the end in RTL');
        expect(focusedValue(), 'b');
        await press(tester, LogicalKeyboardKey.arrowRight);
        expect(seen.last, 'a');
        await press(tester, LogicalKeyboardKey.arrowDown);
        expect(seen.last, 'b', reason: 'Down is the next option either way');
      });
    }

    testWidgets('keys do nothing in a disabled group', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          DsRadioGroup<String>(
            value: 'a',
            onChanged: null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsRadio<String>(
                  value: 'a',
                  label: const Text('A'),
                  focusNode: node,
                ),
                const DsRadio<String>(value: 'b', label: Text('B')),
              ],
            ),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
