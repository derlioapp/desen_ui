import 'dart:ui' show SemanticsRole, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/components/pagination/pagination_slots.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'selection_test.dart' show focusInside;

/// Behavior of the button-based components. Every test runs
/// without DsScope unless it passes a theme.
void main() {
  group('DsTabs', () {
    Widget tabs(int value, ValueChanged<int> onChanged) => DsTabs<int>(
      value: value,
      onChanged: onChanged,
      tabs: const [
        DsTab(value: 0, label: Text('Genel')),
        DsTab(value: 1, label: Text('Üyeler'), count: 12),
        DsTab(value: 2, label: Text('Güvenlik'), enabled: false),
        DsTab(value: 3, label: Text('Faturalar')),
      ],
    );

    testWidgets('tap, arrows (skipping disabled), Home and End', (
      tester,
    ) async {
      var value = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (c, set) => tabs(value, (v) => set(() => value = v)),
          ),
        ),
      );
      await tester.tap(find.text('Üyeler'));
      await tester.pump();
      expect(value, 1);
      focusInside(tester, find.byType(DsTabs<int>));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, 3, reason: 'Güvenlik is disabled and skipped');
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(value, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(value, 3);
      await tester.tap(find.text('Güvenlik'));
      await tester.pump();
      expect(value, 3, reason: 'a disabled tab does not select');
    });

    testWidgets('arrows mirror in RTL', (tester) async {
      var value = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (c, set) => tabs(value, (v) => set(() => value = v)),
          ),
          direction: TextDirection.rtl,
        ),
      );
      focusInside(tester, find.byType(DsTabs<int>));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(value, 1);
    });

    testWidgets('announces a tab bar of tabs with the selected one', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(tabs(1, (_) {})));
      final node = tester.getSemantics(find.text('Üyeler'));
      expect(node.getSemanticsData().role, SemanticsRole.tab);
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      semantics.dispose();
    });
  });

  group('DsAccordion', () {
    const items = [
      DsAccordionItem(
        value: 0,
        title: Text('Bir'),
        child: Text('Birinci içerik'),
      ),
      DsAccordionItem(
        value: 1,
        title: Text('İki'),
        child: Text('İkinci içerik'),
      ),
    ];

    testWidgets('one section open at a time by default', (tester) async {
      await tester.pumpWidget(host(const DsAccordion(items: items)));
      expect(find.text('Birinci içerik'), findsNothing);
      await tester.tap(find.text('Bir'));
      await tester.pumpAndSettle();
      expect(find.text('Birinci içerik'), findsOneWidget);
      await tester.tap(find.text('İki'));
      await tester.pumpAndSettle();
      expect(find.text('Birinci içerik'), findsNothing);
      expect(find.text('İkinci içerik'), findsOneWidget);
      await tester.tap(find.text('İki'));
      await tester.pumpAndSettle();
      expect(find.text('İkinci içerik'), findsNothing, reason: 'toggles');
    });

    testWidgets('allowMultiple keeps others open', (tester) async {
      await tester.pumpWidget(
        host(const DsAccordion(items: items, allowMultiple: true)),
      );
      await tester.tap(find.text('Bir'));
      await tester.tap(find.text('İki'));
      await tester.pumpAndSettle();
      expect(find.text('Birinci içerik'), findsOneWidget);
      expect(find.text('İkinci içerik'), findsOneWidget);
    });

    testWidgets('controlled: reports changes, shows what it is given', (
      tester,
    ) async {
      Set<int>? reported;
      await tester.pumpWidget(
        host(
          DsAccordion(
            items: items,
            value: const {1},
            onChanged: (v) => reported = v,
          ),
        ),
      );
      expect(find.text('İkinci içerik'), findsOneWidget);
      await tester.tap(find.text('Bir'));
      await tester.pumpAndSettle();
      expect(reported, {0});
      expect(find.text('İkinci içerik'), findsOneWidget, reason: 'controlled');
    });

    testWidgets('headers announce expanded state; Enter toggles', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(const DsAccordion(items: items)));
      expect(
        tester.getSemantics(find.text('Bir')).flagsCollection.isExpanded,
        Tristate.isFalse,
      );
      Focus.of(tester.element(find.text('Bir'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Birinci içerik'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Bir')).flagsCollection.isExpanded,
        Tristate.isTrue,
      );
      semantics.dispose();
    });
  });

  group('DsStepper', () {
    Widget stepper(int value, ValueChanged<int> onChanged) =>
        DsStepper(value: value, min: 0, max: 3, onChanged: onChanged);

    testWidgets('buttons step and stop at the limits', (tester) async {
      var value = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (c, set) => stepper(value, (v) => set(() => value = v)),
          ),
        ),
      );
      await tester.tap(
        find.byWidgetPredicate((w) => w is DsIcon && w.icon == DsIcons.minus),
      );
      expect(value, 0, reason: 'minus is inactive at min');
      for (var i = 0; i < 5; i++) {
        await tester.tap(
          find.byWidgetPredicate((w) => w is DsIcon && w.icon == DsIcons.plus),
        );
        await tester.pump();
      }
      expect(value, 3, reason: 'plus stops at max');
    });

    testWidgets('one Tab stop; arrows, Home and End', (tester) async {
      var value = 1;
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatefulBuilder(
                  builder: (c, set) =>
                      stepper(value, (v) => set(() => value = v)),
                ),
                DsButton(onPressed: () {}, child: const Text('Sonra')),
              ],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(value, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(value, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(value, 3);
      // The next Tab leaves the stepper for the button, skipping − and +.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(focused.findAncestorWidgetOfExactType<DsButton>(), isNotNull);
    });

    testWidgets('screen readers read and adjust the value', (tester) async {
      final semantics = tester.ensureSemantics();
      var value = 1;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (c, set) => DsStepper(
              value: value,
              max: 3,
              semanticLabel: 'Misafir',
              onChanged: (v) => set(() => value = v),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(DsStepper<int>)),
        isSemantics(
          label: 'Misafir',
          value: '1',
          increasedValue: '2',
          decreasedValue: '0',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          isEnabled: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('DsListSection and DsListRow', () {
    testWidgets('pressable and static rows; dividers start at the text', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: DsListSection(
              header: const Text('TERCİHLER'),
              children: [
                DsListRow(
                  leading: const DsIcon(DsIcons.bell),
                  title: const Text('Bildirimler'),
                  showChevron: true,
                  onPressed: () => taps++,
                ),
                const DsListRow(title: Text('Sürüm'), detail: Text('1.0')),
                const DsListRow(title: Text('Lisans')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Bildirimler'));
      expect(taps, 1);
      await tester.tap(find.text('Sürüm'));
      expect(taps, 1, reason: 'a static row does nothing');
      final dividers = find.byType(DsLine);
      double left(Finder f) => tester.getTopLeft(f).dx;
      expect(left(dividers.at(0)), left(find.text('Bildirimler')));
      expect(left(dividers.at(1)), left(find.text('Sürüm')));
    });

    testWidgets('destructive rows use the danger text color', (tester) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        host(
          theme: theme,
          DsListRow(
            title: const Text('Oturumu kapat'),
            destructive: true,
            onPressed: () {},
          ),
        ),
      );
      final text = tester.widget<RichText>(
        find.descendant(
          of: find.byType(DsListRow),
          matching: find.byType(RichText),
        ),
      );
      expect(text.text.style?.color, theme.colors.danger.text);
    });
  });

  group('navigation', () {
    testWidgets('sidebar items select and announce the current page', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var page = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 300,
            child: StatefulBuilder(
              builder: (c, set) => DsSidebar(
                children: [
                  DsSidebarItem(
                    label: const Text('Gelen'),
                    count: 4,
                    selected: page == 0,
                    onPressed: () => set(() => page = 0),
                  ),
                  const DsSidebarSection(label: Text('EKİPLER')),
                  DsSidebarItem(
                    label: const Text('Tasarım'),
                    selected: page == 1,
                    onPressed: () => set(() => page = 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tasarım'));
      await tester.pump();
      expect(page, 1);
      expect(
        tester.getSemantics(find.text('Tasarım')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      semantics.dispose();
    });

    testWidgets('bottom nav selects; the bar keeps clear of the safe area', (
      tester,
    ) async {
      var index = 0;
      const items = [
        DsBottomNavItem(
          value: 0,
          icon: DsIcon(DsIcons.house),
          label: Text('Ana'),
        ),
        DsBottomNavItem(
          value: 1,
          icon: DsIcon(DsIcons.user),
          label: Text('Profil'),
        ),
      ];
      Widget nav(DsBottomNavVariant v) => MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
        child: StatefulBuilder(
          builder: (c, set) => DsBottomNav(
            variant: v,
            items: items,
            value: index,
            onChanged: (i) => set(() => index = i),
          ),
        ),
      );
      await tester.pumpWidget(host(nav(DsBottomNavVariant.floating)));
      await tester.tap(find.text('Profil'));
      await tester.pump();
      expect(index, 1);
      final floating = tester.getSize(find.byType(DsBottomNav<int>)).height;
      await tester.pumpWidget(
        host(SizedBox(width: 360, child: nav(DsBottomNavVariant.bar))),
      );
      final bar = tester.getSize(find.byType(DsBottomNav<int>)).height;
      expect(bar, greaterThan(floating + 30), reason: 'safe area below');
    });

    test('pagination slots keep the ends and the neighbors', () {
      expect(paginationSlots(1, 5), [1, 2, 3, 4, 5]);
      expect(paginationSlots(1, 12), [1, 2, 3, 4, null, 12]);
      expect(paginationSlots(6, 12), [1, null, 5, 6, 7, null, 12]);
      expect(paginationSlots(11, 12), [1, null, 9, 10, 11, 12]);
    });

    testWidgets('pagination moves and disables the arrows at the ends', (
      tester,
    ) async {
      var page = 1;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (c, set) => DsPagination(
              page: page,
              pageCount: 3,
              onChanged: (p) => set(() => page = p),
            ),
          ),
        ),
      );
      final prev = find.bySemanticsLabel('Previous page');
      final next = find.bySemanticsLabel('Next page');
      await tester.tap(prev);
      await tester.pump();
      expect(page, 1, reason: 'previous is inactive on the first page');
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(page, 3);
      await tester.tap(next);
      await tester.pump();
      expect(page, 3, reason: 'next is inactive on the last page');
      await tester.tap(prev);
      await tester.pump();
      expect(page, 2);
    });

    testWidgets('a disabled pagination is no Tab stop and says disabled', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const DsPagination(page: 2, pageCount: 5, onChanged: null)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel ?? '',
        isNot(startsWith('DsPagination')),
      );
      expect(
        tester.getSemantics(find.text('2')),
        isSemantics(isEnabled: false),
      );
      semantics.dispose();
    });

    testWidgets('focusing a pagination narrowed to the counter focuses an '
        'arrow', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var width = 600.0;
      late StateSetter set;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (c, s) {
              set = s;
              return SizedBox(
                width: width,
                child: DsPagination(
                  page: 5,
                  pageCount: 20,
                  focusNode: node,
                  onChanged: (_) {},
                ),
              );
            },
          ),
        ),
      );
      set(() => width = 160);
      await tester.pump();
      expect(find.text('5 / 20'), findsOneWidget);
      node.requestFocus();
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'DsPagination next',
      );
    });

    testWidgets('a pagination page past the page count shows as the last', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final changed = <int>[];
      await tester.pumpWidget(
        host(DsPagination(page: 5, pageCount: 5, onChanged: changed.add)),
      );
      // A filter leaves two pages; the app still holds page 5.
      await tester.pumpWidget(
        host(DsPagination(page: 5, pageCount: 2, onChanged: changed.add)),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(find.text('2')).value,
        const DsLocalizationsEn().currentPage,
      );
      expect(changed, isEmpty);
      semantics.dispose();
    });

    testWidgets('a button in a toolbar takes the toggles\' nested corner', (
      tester,
    ) async {
      DsButtonStyle? seen;
      await tester.pumpWidget(
        host(
          DsToolbar(
            children: [
              DsToolbarToggle(
                icon: const DsIcon(DsIcons.bold),
                semanticLabel: 'Bold',
                selected: false,
                onChanged: (_) {},
              ),
              DsToolbarItem(
                menuItems: [
                  DsMenuItem(label: const Text('Share'), onPressed: () {}),
                ],
                child: Builder(
                  builder: (c) {
                    seen = DsButtonTheme.of(c).style;
                    return DsButton(
                      onPressed: () {},
                      child: const Text('Share'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      final toggle = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(DsToolbarToggle),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final drawn = (toggle.decoration! as DsBoxDecoration).borderRadius;
      expect(seen?.borderRadius, isNotNull);
      expect(seen?.borderRadius, drawn);
    });

    testWidgets('toolbar toggles announce their state', (tester) async {
      final semantics = tester.ensureSemantics();
      var bold = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (c, set) => DsToolbar(
              children: [
                DsToolbarToggle(
                  icon: const DsIcon(DsIcons.bold),
                  semanticLabel: 'Kalın',
                  selected: bold,
                  onChanged: (v) => set(() => bold = v),
                ),
                const DsToolbarDivider(),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Kalın'));
      await tester.pump();
      expect(bold, isTrue);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Kalın'))
            .flagsCollection
            .isToggled,
        Tristate.isTrue,
      );
      semantics.dispose();
    });
  });

  group('pane header and empty state', () {
    testWidgets('titles are headers', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsPaneHeader(title: Text('Ayarlar')),
                DsEmptyState(
                  icon: DsIcon(DsIcons.inbox),
                  title: Text('Henüz görev yok'),
                  description: Text('İlk görevi ekleyin.'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        tester
            .getSemantics(find.text('Henüz görev yok'))
            .flagsCollection
            .isHeader,
        isTrue,
      );
      semantics.dispose();
    });
  });

  testWidgets('2x text does not overflow', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        textScale: 2,
        SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsTabs<int>(
                value: 0,
                onChanged: (_) {},
                tabs: const [
                  DsTab(value: 0, label: Text('Genel')),
                  DsTab(value: 1, label: Text('Üyeler'), count: 12),
                ],
              ),
              const DsAccordion(
                initialValue: {0},
                items: [
                  DsAccordionItem(
                    value: 0,
                    title: Text('Hesap nasıl silinir?'),
                    child: Text('Ayarlar → Güvenlik.'),
                  ),
                ],
              ),
              DsListSection(
                children: [
                  DsListRow(
                    leading: const DsIcon(DsIcons.bell),
                    title: const Text('Bildirimler'),
                    detail: const Text('Açık'),
                    showChevron: true,
                    onPressed: () {},
                  ),
                ],
              ),
              DsStepper(value: 3, max: 12, onChanged: (_) {}),
              DsPagination(page: 6, pageCount: 12, onChanged: (_) {}),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
