import 'dart:ui' show CheckedState, SemanticsRole, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A toolbar too narrow for its items: the items that do not fit move,
/// from the end, into a "More actions" menu; dividers at the cut are
/// dropped; the menu is reached and left from the keyboard like any menu.
void main() {
  final desktop = DsThemeData(platform: TargetPlatform.macOS);
  late List<String> log;
  setUp(() => log = []);

  // Keys of the items, start to end. 2 and 5 are dividers.
  const keys = [
    ValueKey('bold'),
    ValueKey('italic'),
    ValueKey('divider1'),
    ValueKey('link'),
    ValueKey('archive'),
    ValueKey('divider2'),
    ValueKey('delete'),
    ValueKey('comment'),
  ];

  List<Widget> items() => [
    DsToolbarToggle(
      key: keys[0],
      icon: const DsIcon(DsIcons.bold),
      semanticLabel: 'Bold',
      selected: true,
      onChanged: (v) => log.add('bold:$v'),
    ),
    DsToolbarToggle(
      key: keys[1],
      icon: const DsIcon(DsIcons.italic),
      semanticLabel: 'Italic',
      selected: false,
      onChanged: (v) => log.add('italic:$v'),
    ),
    DsToolbarDivider(key: keys[2]),
    DsTooltip(
      key: keys[3],
      message: 'Add link',
      shortcut: '⌘K',
      child: DsButton.icon(
        variant: DsButtonVariant.ghost,
        size: DsSize.sm,
        icon: const DsIcon(DsIcons.link),
        semanticLabel: 'Add link',
        onPressed: () => log.add('link'),
      ),
    ),
    DsButton.icon(
      key: keys[4],
      variant: DsButtonVariant.ghost,
      size: DsSize.sm,
      icon: const DsIcon(DsIcons.inbox),
      semanticLabel: 'Archive',
      onPressed: null,
    ),
    DsToolbarDivider(key: keys[5]),
    DsButton.icon(
      key: keys[6],
      variant: DsButtonVariant.dangerSoft,
      size: DsSize.sm,
      icon: const DsIcon(DsIcons.trash),
      semanticLabel: 'Delete',
      onPressed: () => log.add('delete'),
    ),
    DsButton(
      key: keys[7],
      size: DsSize.sm,
      onPressed: () => log.add('comment'),
      child: const Text('Comment'),
    ),
  ];

  Widget app({
    double maxWidth = 2000,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    DsThemeData? theme,
    Locale? locale,
    List<Widget>? children,
    // Null leaves the toolbar's default, so every test checks it.
    DsToolbarOverflow? overflow,
  }) => DsApp(
    theme: theme ?? desktop,
    locale: locale,
    builder: (context, child) => Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
    home: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: overflow == null
              ? DsToolbar(
                  semanticLabel: 'Formatting',
                  children: children ?? items(),
                )
              : DsToolbar(
                  semanticLabel: 'Formatting',
                  overflow: overflow,
                  children: children ?? items(),
                ),
        ),
      ),
    ),
  );

  final more = find.byWidgetPredicate(
    (w) => w is DsButton && w.semanticLabel == 'More actions',
  );

  /// The keys of the items in the bar, in order.
  List<Key> shown(WidgetTester tester) => [
    for (final key in keys)
      if (!tester
          .widget<ExcludeFocus>(
            find
                .ancestor(
                  of: find.byKey(key),
                  matching: find.byType(ExcludeFocus),
                )
                .first,
          )
          .excluding)
        key,
  ];

  /// Whether the ⋯ button is in the bar.
  bool moreShown(WidgetTester tester) => !tester
      .widget<ExcludeFocus>(
        find.ancestor(of: more, matching: find.byType(ExcludeFocus)).first,
      )
      .excluding;

  /// The menu's entries: labels, '—' for a divider.
  List<String> menu(WidgetTester tester) => [
    for (final entry in tester.widget<DsMenu>(find.byType(DsMenu)).children)
      switch (entry) {
        DsMenuItem(:final Text label) => label.data!,
        DsMenuDivider() => '—',
        _ => '?',
      },
  ];

  /// The name of what has focus: a menu item as `menu:Label`.
  String? focused() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return null;
    if (context.findAncestorWidgetOfExactType<DsMenuItem>() case final item?) {
      return 'menu:${(item.label as Text).data}';
    }
    if (context.findAncestorWidgetOfExactType<DsToolbarToggle>()
        case final toggle?) {
      return toggle.semanticLabel;
    }
    if (context.findAncestorWidgetOfExactType<DsButton>() case final button?) {
      return button.semanticLabel ?? (button.child as Text).data;
    }
    return null;
  }

  /// The layout of every item with room for all of them, relative to the
  /// bar's start edge: what the overflow cuts from.
  late List<double> ends;
  late double padding, gap, moreWidth;

  Future<void> measure(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final bar = tester.getRect(find.byType(DsToolbar));
    ends = [
      for (final k in keys) tester.getRect(find.byKey(k)).right - bar.left,
    ];
    padding = tester.getRect(find.byKey(keys[0])).left - bar.left;
    gap = DsToolbar.defaultStyle(desktop).gap!;
    await tester.pumpWidget(app(maxWidth: 10));
    await tester.pumpAndSettle();
    moreWidth = tester.getSize(more).width;
  }

  /// The widest bar that shows the first [k] items beside the ⋯ button.
  double widthFor(int k) => ends[k - 1] + gap + moreWidth + padding;

  Future<void> pumpAt(
    WidgetTester tester,
    double maxWidth, {
    TextDirection direction = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(app(maxWidth: maxWidth, direction: direction));
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(more);
    await tester.pumpAndSettle();
  }

  test('the menu is the default', () {
    expect(const DsToolbar(children: []).overflow, DsToolbarOverflow.menu);
  });

  group('which items overflow', () {
    testWidgets('with room for all, every item shows and there is no ⋯', (
      tester,
    ) async {
      await pumpAt(tester, 2000);
      expect(shown(tester), keys);
      expect(moreShown(tester), isFalse);
      expect(more.hitTestable(), findsNothing);
      // As wide as the scrolling row: the same layout.
      final width = tester.getSize(find.byType(DsToolbar)).width;
      await tester.pumpWidget(app(overflow: DsToolbarOverflow.scroll));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(DsToolbar)).width, width);
    });

    testWidgets('items move from the end at several widths', (tester) async {
      await measure(tester);
      // (width, items in the bar, menu)
      final cases = [
        (widthFor(7), 7, ['Comment']),
        // Six fit, but the sixth is a divider: it is dropped too.
        (widthFor(6), 5, ['Delete', 'Comment']),
        (widthFor(5), 5, ['Delete', 'Comment']),
        (widthFor(5) - 1, 4, ['Archive', '—', 'Delete', 'Comment']),
        (widthFor(4), 4, ['Archive', '—', 'Delete', 'Comment']),
        (widthFor(3), 2, ['Add link', 'Archive', '—', 'Delete', 'Comment']),
        (
          widthFor(1),
          1,
          ['Italic', '—', 'Add link', 'Archive', '—', 'Delete', 'Comment'],
        ),
        (
          moreWidth + 2 * padding,
          0,
          [
            'Bold',
            'Italic',
            '—',
            'Add link',
            'Archive',
            '—',
            'Delete',
            'Comment',
          ],
        ),
      ];
      for (final (width, count, entries) in cases) {
        await pumpAt(tester, width);
        expect(shown(tester), keys.take(count), reason: 'at $width');
        expect(moreShown(tester), isTrue, reason: 'at $width');
        // The bar holds exactly the shown items and the button: no divider
        // dangles before it.
        final barWidth = tester.getSize(find.byType(DsToolbar)).width;
        final expected = count == 0 ? moreWidth + 2 * padding : widthFor(count);
        expect(barWidth, moreCloseTo(expected), reason: 'at $width');
        expect(barWidth, lessThanOrEqualTo(width), reason: 'at $width');
        await openMenu(tester);
        expect(menu(tester), entries, reason: 'at $width');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('hidden items are not painted, hit or read', (tester) async {
      final semantics = tester.ensureSemantics();
      await measure(tester);
      await pumpAt(tester, widthFor(4));
      for (final label in ['Bold', 'Italic', 'Add link']) {
        expect(find.semantics.byLabel(label), findsOne, reason: label);
      }
      for (final label in ['Archive', 'Delete', 'Comment']) {
        expect(find.semantics.byLabel(label), findsNothing, reason: label);
      }
      expect(find.byKey(keys[6]).hitTestable(), findsNothing);
      expect(find.byKey(keys[7]).hitTestable(), findsNothing);
      expect(more.hitTestable(), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('resizing down and up: items leave and come back', (
      tester,
    ) async {
      await measure(tester);
      for (final (width, count) in [
        (2000.0, 8),
        (widthFor(4), 4),
        (widthFor(1), 1),
        (widthFor(5), 5),
        (2000.0, 8),
        (widthFor(7), 7),
      ]) {
        await pumpAt(tester, width);
        expect(shown(tester), keys.take(count), reason: 'at $width');
        expect(moreShown(tester), count < 8, reason: 'at $width');
      }
    });

    testWidgets('an open menu closes when every item comes back', (
      tester,
    ) async {
      await measure(tester);
      await pumpAt(tester, widthFor(4));
      await openMenu(tester);
      expect(find.byType(DsMenu), findsOneWidget);
      await pumpAt(tester, 2000);
      expect(find.byType(DsMenu), findsNothing);
      expect(moreShown(tester), isFalse);
    });

    testWidgets('the layout is stable: a second frame changes nothing', (
      tester,
    ) async {
      await measure(tester);
      await tester.pumpWidget(app(maxWidth: widthFor(4)));
      final first = tester.getRect(find.byType(DsToolbar));
      final items = [
        for (final k in keys.take(4)) tester.getRect(find.byKey(k)),
      ];
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(find.byType(DsToolbar)), first);
      expect([
        for (final k in keys.take(4)) tester.getRect(find.byKey(k)),
      ], items);
      expect(shown(tester), keys.take(4));
    });

    testWidgets('RTL: the overflow comes from the visual end, the left', (
      tester,
    ) async {
      await measure(tester);
      await pumpAt(tester, widthFor(4), direction: TextDirection.rtl);
      expect(shown(tester), keys.take(4));
      final bar = tester.getRect(find.byType(DsToolbar));
      final bold = tester.getRect(find.byKey(keys[0]));
      final button = tester.getRect(more);
      // Bold starts at the right; the button ends the row on the left.
      expect(bold.right, moreCloseTo(bar.right - padding));
      expect(button.left, moreCloseTo(bar.left + padding));
      expect(
        tester.getRect(find.byKey(keys[3])).left - gap,
        moreCloseTo(button.right),
      );
      await openMenu(tester);
      expect(menu(tester), ['Archive', '—', 'Delete', 'Comment']);
    });

    testWidgets('large text: items collapse instead of clipping', (
      tester,
    ) async {
      await measure(tester);
      final width = ends.last + padding;
      await tester.pumpWidget(app(maxWidth: width));
      await tester.pumpAndSettle();
      expect(shown(tester), keys);
      await tester.pumpWidget(app(maxWidth: width, textScale: 2));
      await tester.pumpAndSettle();
      expect(moreShown(tester), isTrue);
      expect(shown(tester), isNot(contains(keys[7])));
      expect(
        tester.getSize(find.byType(DsToolbar)).width,
        lessThanOrEqualTo(width),
      );
      // The text button is in the menu, whole.
      await openMenu(tester);
      expect(menu(tester), contains('Comment'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('touch density: tap areas count, and items collapse', (
      tester,
    ) async {
      final touch = DsThemeData(platform: TargetPlatform.iOS);
      await tester.pumpWidget(app(theme: touch, maxWidth: 200));
      await tester.pumpAndSettle();
      expect(moreShown(tester), isTrue);
      final bar = tester.getSize(find.byType(DsToolbar));
      expect(bar.width, lessThanOrEqualTo(200));
      // Every item and the button keep a 44px tap area.
      expect(tester.getSize(more).height, greaterThanOrEqualTo(44));
      await openMenu(tester);
      expect(menu(tester).last, 'Comment');
    });
  });

  group('the menu', () {
    testWidgets('items map to menu items: icon, shortcut, state', (
      tester,
    ) async {
      await measure(tester);
      await pumpAt(tester, moreWidth + 2 * padding);
      await openMenu(tester);
      DsMenuItem item(String label) => tester.widget<DsMenuItem>(
        find.ancestor(of: find.text(label), matching: find.byType(DsMenuItem)),
      );
      expect(item('Bold').checked, isTrue);
      expect(item('Bold').checkRole, DsMenuCheckRole.checkbox);
      expect(item('Italic').checked, isFalse);
      expect((item('Bold').leading! as DsIcon).icon, DsIcons.bold);
      expect(item('Add link').shortcut, '⌘K');
      expect((item('Add link').leading! as DsIcon).icon, DsIcons.link);
      expect(item('Archive').onPressed, isNull);
      expect(item('Delete').destructive, isTrue);
      expect(item('Comment').leading, isNull);
      expect(item('Comment').checked, isNull);
    });

    testWidgets('choosing an item runs it and closes the menu', (tester) async {
      await measure(tester);
      await pumpAt(tester, widthFor(1));
      await openMenu(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(log, ['delete']);
      expect(find.byType(DsMenu), findsNothing);
      // A toggle from the menu turns over.
      await openMenu(tester);
      await tester.tap(find.text('Italic'));
      await tester.pumpAndSettle();
      expect(log, ['delete', 'italic:true']);
      // A disabled button is a disabled item.
      await openMenu(tester);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(log, ['delete', 'italic:true']);
    });

    testWidgets('toggles are checkbox items, checked while on', (tester) async {
      final semantics = tester.ensureSemantics();
      await measure(tester);
      await pumpAt(tester, moreWidth + 2 * padding);
      await openMenu(tester);
      SemanticsData data(String label) => tester
          .getSemantics(
            find.descendant(
              of: find.byType(DsMenu),
              matching: find.text(label),
            ),
          )
          .getSemanticsData();
      expect(data('Bold').role, SemanticsRole.menuItemCheckbox);
      expect(data('Bold').flagsCollection.isChecked, CheckedState.isTrue);
      expect(data('Italic').flagsCollection.isChecked, CheckedState.isFalse);
      expect(data('Comment').role, SemanticsRole.menuItem);
      semantics.dispose();
    });

    testWidgets('a DsToolbarItem gives the menu form', (tester) async {
      await tester.pumpWidget(
        app(
          maxWidth: 100,
          children: [
            const DsToolbarItem(
              menuItems: [],
              child: SizedBox(width: 40, height: 20),
            ),
            DsToolbarItem(
              menuItems: [
                DsMenuItem(
                  label: const Text('Grid'),
                  checked: true,
                  onPressed: () => log.add('grid'),
                ),
                const DsMenuDivider(),
                DsMenuItem(
                  label: const Text('Board'),
                  onPressed: () => log.add('board'),
                ),
              ],
              child: const SizedBox(width: 80, height: 20),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await openMenu(tester);
      expect(menu(tester), ['Grid', '—', 'Board']);
      // A radio item, as the item asked.
      expect(
        tester.widget<DsMenuItem>(find.byType(DsMenuItem).first).checkRole,
        DsMenuCheckRole.radio,
      );
    });

    testWidgets('an item with no menu form is left out without a ⋯', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          maxWidth: 100,
          children: [
            DsToolbarToggle(
              icon: const DsIcon(DsIcons.bold),
              semanticLabel: 'Bold',
              selected: false,
              onChanged: (_) {},
            ),
            const DsToolbarDivider(),
            const DsToolbarItem(
              menuItems: [],
              child: SizedBox(width: 120, height: 20),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(moreShown(tester), isFalse);
      // Bold shows; the divider before the cut and the label do not.
      final bar = tester.getRect(find.byType(DsToolbar));
      final bold = tester.getRect(find.byType(DsToolbarToggle));
      expect(bar.right - bold.right, moreCloseTo(bold.left - bar.left));
    });

    testWidgets('a child with no menu form makes the bar scroll, keeping '
        'every child', (tester) async {
      final custom = [
        ...items(),
        const SizedBox(key: ValueKey('custom'), width: 60, height: 20),
      ];
      await tester.pumpWidget(app(maxWidth: 160, children: custom));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // No menu: every child is in the bar, which scrolls.
      expect(more, findsNothing);
      for (final key in [...keys, const ValueKey('custom')]) {
        expect(find.byKey(key), findsOneWidget, reason: '$key');
      }
      final scrollable = find.descendant(
        of: find.byType(DsToolbar),
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsOneWidget);
      expect(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
        greaterThan(0),
      );
      expect(
        tester.getSize(find.byType(DsToolbar)).width,
        lessThanOrEqualTo(160),
      );
      // Wrapped in a DsToolbarItem, the same child lets the bar collapse.
      await tester.pumpWidget(
        app(
          maxWidth: 160,
          children: [
            ...items(),
            const DsToolbarItem(
              menuItems: [],
              child: SizedBox(key: ValueKey('custom'), width: 60, height: 20),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(scrollable, findsNothing);
      expect(moreShown(tester), isTrue);
    });
  });

  group('keyboard and focus', () {
    testWidgets('⋯ is the last Tab stop; hidden items are not stops', (
      tester,
    ) async {
      await measure(tester);
      await pumpAt(tester, widthFor(4));
      final order = <String?>[];
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        order.add(focused());
      }
      expect(order, ['Bold', 'Italic', 'Add link', 'More actions', 'Bold']);
    });

    testWidgets('arrows reach ⋯ and wrap; End lands on it', (tester) async {
      await measure(tester);
      await pumpAt(tester, widthFor(4));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final order = <String?>[];
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        order.add(focused());
      }
      expect(order, ['Italic', 'Add link', 'More actions', 'Bold']);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(focused(), 'More actions');
    });

    testWidgets('Enter opens the menu; Escape returns focus to ⋯', (
      tester,
    ) async {
      await measure(tester);
      await pumpAt(tester, widthFor(4));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(focused(), 'More actions');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      // The first enabled item: Archive is disabled.
      expect(focused(), 'menu:Delete');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(focused(), 'menu:Comment');
      // Left and Right belong to the menu, not to the bar behind it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(focused(), 'menu:Comment');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(DsMenu), findsNothing);
      expect(focused(), 'More actions');
    });

    testWidgets('choosing from the keyboard returns focus to ⋯', (
      tester,
    ) async {
      await measure(tester);
      await pumpAt(tester, widthFor(4));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(focused(), 'menu:Comment');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(log, ['comment']);
      expect(find.byType(DsMenu), findsNothing);
      expect(focused(), 'More actions');
    });

    testWidgets('a focused item that moves into the menu hands focus to ⋯', (
      tester,
    ) async {
      await measure(tester);
      await pumpAt(tester, 2000);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(focused(), 'Comment');
      await pumpAt(tester, widthFor(4));
      expect(focused(), 'More actions');
    });
  });

  group('screen readers', () {
    testWidgets('⋯ is a "More actions" button, collapsed or expanded', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await measure(tester);
      await pumpAt(tester, widthFor(4));
      SemanticsData data() => tester.getSemantics(more).getSemanticsData();
      expect(data().label, 'More actions');
      expect(data().flagsCollection.isButton, isTrue);
      expect(data().flagsCollection.isExpanded, Tristate.isFalse);
      await openMenu(tester);
      expect(data().flagsCollection.isExpanded, Tristate.isTrue);
      // The menu is named too.
      final menuNode = tester
          .getSemantics(find.byType(DsMenu))
          .getSemanticsData();
      expect(menuNode.label, 'More actions');
      semantics.dispose();
    });

    testWidgets('the label is localized', (tester) async {
      await tester.pumpWidget(app(maxWidth: 120, locale: const Locale('tr')));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is DsButton && w.semanticLabel == 'Diğer işlemler',
        ),
        findsOneWidget,
      );
    });
  });
}

/// Layout arithmetic in doubles: equal within a hair.
Matcher moreCloseTo(double value) => closeTo(value, 0.01);
