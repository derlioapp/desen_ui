import 'dart:ui' show CheckedState, SemanticsRole, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsChoiceChips: a single-choice chip row (radio group) that looks like
/// the filter chips, scrolls when it overflows and keeps the selection in
/// view.
void main() {
  const labels = ['All', 'Unread', 'Flagged', 'Archived', 'Drafts', 'Sent'];

  Widget chips({
    required String value,
    required ValueChanged<String>? onChanged,
    FocusNode? node,
    Set<String> disabled = const {},
    DsChipStyle? style,
    List<String> options = const ['All', 'Unread', 'Flagged'],
  }) => DsChoiceChips<String>(
    value: value,
    onChanged: onChanged,
    focusNode: node,
    style: style,
    semanticLabel: 'Show',
    options: [
      for (final o in options)
        DsChipOption(value: o, label: Text(o), enabled: !disabled.contains(o)),
    ],
  );

  /// A row that keeps its own value, reporting each change to [seen].
  Widget stateful(
    String initial, {
    List<String>? seen,
    FocusNode? node,
    Set<String> disabled = const {},
    List<String> options = const ['All', 'Unread', 'Flagged'],
  }) {
    var value = initial;
    return StatefulBuilder(
      builder: (context, set) => chips(
        value: value,
        node: node,
        disabled: disabled,
        options: options,
        onChanged: (v) => set(() {
          value = v;
          seen?.add(v);
        }),
      ),
    );
  }

  /// The decoration the chip labelled [label] paints.
  DsBoxDecoration face(WidgetTester tester, String label) =>
      tester
              .widget<AnimatedContainer>(
                find.ancestor(
                  of: find.text(label),
                  matching: find.byType(AnimatedContainer),
                ),
              )
              .decoration!
          as DsBoxDecoration;

  testWidgets('a tap selects; the selected chip and disabled chips do not '
      'report', (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(
      host(stateful('All', seen: seen, disabled: {'Flagged'})),
    );
    await tester.tap(find.text('Unread'));
    await tester.pump();
    expect(seen, ['Unread']);
    await tester.tap(find.text('Unread'));
    await tester.tap(find.text('Flagged'));
    await tester.pump();
    expect(seen, ['Unread']);
  });

  testWidgets('a null onChanged disables every chip', (tester) async {
    await tester.pumpWidget(host(chips(value: 'All', onChanged: null)));
    await tester.tap(find.text('Unread'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    final theme = DsThemeData();
    await tester.pumpWidget(
      host(chips(value: 'All', onChanged: null), theme: theme),
    );
    final disabled = DsChip.defaultStyle(theme).disabled!;
    expect(face(tester, 'Unread').color, disabled.background);
    expect(face(tester, 'All').color, disabled.selected!.background);
  });

  testWidgets('looks like a DsChip: the selected chip takes the selection '
      'fill and a check', (tester) async {
    final theme = DsThemeData();
    await tester.pumpWidget(
      host(
        theme: theme,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            chips(value: 'Unread', onChanged: (_) {}),
            DsChip(
              label: const Text('Filter'),
              selected: true,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    expect(face(tester, 'Unread').color, theme.selectedFill);
    expect(face(tester, 'Unread').color, face(tester, 'Filter').color);
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.text('Unread'),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .height,
      tester
          .getSize(
            find.ancestor(
              of: find.text('Filter'),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .height,
    );
    // The check: one in the row (Unread) and one on the filter chip.
    expect(
      find.byWidgetPredicate((w) => w is DsIcon && w.icon == DsIcons.check),
      findsNWidgets(2),
    );
  });

  testWidgets('the style reaches every chip, over DsChipTheme', (tester) async {
    const brand = Color(0xFF0B6E4F);
    const themed = Color(0xFF123456);
    Widget themedRow(DsChipStyle? style) => DsChipTheme(
      data: const DsChipThemeData(
        style: DsChipStyle(selected: DsChipStyle(background: themed)),
      ),
      child: chips(value: 'All', onChanged: (_) {}, style: style),
    );
    await tester.pumpWidget(host(themedRow(null)));
    expect(face(tester, 'All').color, themed);
    await tester.pumpWidget(
      host(
        themedRow(const DsChipStyle(selected: DsChipStyle(background: brand))),
      ),
    );
    expect(face(tester, 'All').color, brand);
  });

  testWidgets('one Tab stop; arrows move the selection, skip disabled chips '
      'and wrap; Home and End', (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(
      DsApp(
        home: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              stateful('All', seen: seen, disabled: {'Flagged'}),
              DsButton(onPressed: () {}, child: const Text('After')),
            ],
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(seen.last, 'Unread');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(seen.last, 'All', reason: 'skips Flagged and wraps to the first');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(seen.last, 'Unread', reason: 'back from the first wraps');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(seen.last, 'All');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(seen.last, 'Unread', reason: 'End: the last enabled chip');
    // The next Tab leaves the row for the button.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(focused.findAncestorWidgetOfExactType<DsButton>(), isNotNull);
  });

  testWidgets('Left and Right mirror in RTL', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    final seen = <String>[];
    await tester.pumpWidget(
      host(
        stateful('Unread', seen: seen, node: node),
        direction: .rtl,
      ),
    );
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(seen.last, 'All', reason: 'Right goes toward the start in RTL');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(seen.last, 'Unread');
    // The first chip sits on the right in RTL.
    expect(
      tester.getCenter(find.text('All')).dx,
      greaterThan(tester.getCenter(find.text('Unread')).dx),
    );
  });

  testWidgets('keyboard focus rings the selected chip', (tester) async {
    useTraditionalHighlights();
    final node = FocusNode();
    addTearDown(node.dispose);
    final theme = DsThemeData();
    await tester.pumpWidget(host(theme: theme, stateful('Unread', node: node)));
    node.requestFocus();
    // Any key marks keyboard modality.
    await tester.sendKeyEvent(LogicalKeyboardKey.f12);
    await tester.pumpAndSettle();
    List<DsShadow> ring(String label) =>
        (tester
                    .widget<AnimatedContainer>(
                      find.ancestor(
                        of: find.text(label),
                        matching: find.byType(AnimatedContainer),
                      ),
                    )
                    .foregroundDecoration!
                as DsBoxDecoration)
            .shadows;
    expect(ring('Unread'), theme.focusShadows);
    expect(ring('All'), isEmpty);
  });

  testWidgets('semantics: a radio group of radios; focus is reported on the '
      'selected chip', (tester) async {
    final handle = tester.ensureSemantics();
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(host(stateful('Unread', node: node)));
    node.requestFocus();
    await tester.pump();

    final unread = tester.getSemantics(find.text('Unread')).getSemanticsData();
    expect(unread.label, 'Unread');
    expect(unread.flagsCollection.isChecked, CheckedState.isTrue);
    expect(unread.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    expect(unread.flagsCollection.isButton, isFalse);
    expect(unread.flagsCollection.isFocused, Tristate.isTrue);
    final all = tester.getSemantics(find.text('All')).getSemanticsData();
    expect(all.flagsCollection.isChecked, CheckedState.isFalse);
    expect(all.flagsCollection.isFocused, isNot(Tristate.isTrue));

    var group = tester.getSemantics(find.text('All')).parent;
    while (group != null && group.getSemanticsData().role != .radioGroup) {
      group = group.parent;
    }
    expect(group, isNotNull);
    expect(group!.getSemanticsData().role, SemanticsRole.radioGroup);
    expect(group.getSemanticsData().label, 'Show');
    handle.dispose();
  });

  testWidgets('a semantic label replaces the chip text', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        DsChoiceChips<int>(
          value: 0,
          onChanged: (_) {},
          options: const [
            DsChipOption(value: 0, label: Text('Wk'), semanticLabel: 'Week'),
            DsChipOption(value: 1, label: Text('Mo'), semanticLabel: 'Month'),
          ],
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Wk')).getSemanticsData().label,
      'Week',
    );
    handle.dispose();
  });

  group('overflow', () {
    /// The visible part of the row.
    Rect viewport(WidgetTester tester) =>
        tester.getRect(find.byType(SingleChildScrollView));

    ScrollPosition position(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable)).position;

    testWidgets('scrolls sideways and opens on the selected chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(SizedBox(width: 200, child: stateful('Sent', options: labels))),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(position(tester).maxScrollExtent, greaterThan(0));
      final view = viewport(tester);
      final chip = tester.getRect(find.text('Sent'));
      expect(chip.right, lessThanOrEqualTo(view.right + .5));
      expect(chip.left, greaterThanOrEqualTo(view.left - .5));
    });

    testWidgets('a new selection scrolls into view the least distance', (
      tester,
    ) async {
      var value = 'All';
      late StateSetter set;
      await tester.pumpWidget(
        host(
          SizedBox(
            // Wide enough for a chip clear of both faded edges.
            width: 260,
            child: StatefulBuilder(
              builder: (context, s) {
                set = s;
                return chips(
                  value: value,
                  options: labels,
                  onChanged: (v) => s(() => value = v),
                );
              },
            ),
          ),
          theme: DsThemeData(density: DsDensity.compact),
        ),
      );
      await tester.pump();
      expect(position(tester).pixels, 0);

      set(() => value = 'Drafts');
      await tester.pumpAndSettle();
      final view = viewport(tester);
      final drafts = tester.getRect(
        find.ancestor(
          of: find.text('Drafts'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      // Moved forward: the chip ends just inside the faded end edge (Sent
      // is still past it), not centered.
      expect(
        drafts.right,
        moreOrLessEquals(view.right - DsEdgeFade.defaultWidth, epsilon: 1),
      );

      // A chip already in view does not move the row.
      final before = position(tester).pixels;
      // Whole chips, not just their labels: a chip cut at its padding is
      // not in view.
      Rect chipOf(String l) => tester.getRect(
        find.ancestor(
          of: find.text(l),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final visible = labels.firstWhere(
        (l) =>
            l != 'Drafts' &&
            chipOf(l).left >= view.left + DsEdgeFade.defaultWidth &&
            chipOf(l).right <= view.right - DsEdgeFade.defaultWidth,
      );
      set(() => value = visible);
      await tester.pumpAndSettle();
      expect(position(tester).pixels, before);

      // Back to the first: it lands on the start edge.
      set(() => value = 'All');
      await tester.pumpAndSettle();
      expect(position(tester).pixels, 0);
    });

    /// Whether the row's edge fade is on.
    bool faded(WidgetTester tester) => find
        .descendant(
          of: find.byType(DsChoiceChips<String>),
          matching: find.byType(ShaderMask),
        )
        .evaluate()
        .isNotEmpty;

    testWidgets('an edge that hides chips fades; a row that fits does not', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(SizedBox(width: 200, child: stateful('All', options: labels))),
      );
      await tester.pump();
      expect(faded(tester), isTrue);

      await tester.pumpWidget(
        host(SizedBox(width: 400, child: stateful('All'))),
      );
      await tester.pump();
      expect(faded(tester), isFalse);
    });

    testWidgets('a chip under the faded edge is brought clear of it', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(width: 200, child: stateful('All', options: labels)),
          theme: DsThemeData(density: DsDensity.compact),
        ),
      );
      await tester.pump();
      final view = viewport(tester);
      Rect chipOf(String l) => tester.getRect(
        find.ancestor(
          of: find.text(l),
          matching: find.byType(AnimatedContainer),
        ),
      );
      // The chip under the faded end edge, tapped on its visible part.
      final x = view.right - DsEdgeFade.defaultWidth / 2;
      final under = labels.firstWhere(
        (l) => chipOf(l).left < x && chipOf(l).right > x,
      );
      await tester.tapAt(Offset(x, view.center.dy));
      await tester.pumpAndSettle();
      expect(
        chipOf(under).right,
        moreOrLessEquals(view.right - DsEdgeFade.defaultWidth, epsilon: 1),
      );
    });

    testWidgets('arrow keys keep the selected chip in view', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 200,
            child: stateful('All', node: node, options: labels),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      final view = viewport(tester);
      expect(
        tester.getRect(find.text('Sent')).right,
        lessThanOrEqualTo(view.right + .5),
      );
    });
  });

  testWidgets('works without a DsScope, in an unbounded Row and at 2x text', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        textScale: 2,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [stateful('All', options: labels)],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      host(
        textScale: 2,
        SizedBox(width: 358, child: stateful('Sent', options: labels)),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
