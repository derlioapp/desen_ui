import 'dart:ui' show CheckedState, SemanticsRole;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// What screen readers hear in a menu: checkbox items apart from radio
/// items, and shortcuts read by key name.
void main() {
  Widget app(Widget child) => DsApp(home: Center(child: child));

  group('checkable items', () {
    testWidgets('radio by default; checkbox on request; plain otherwise', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsMenu(
            children: [
              DsMenuItem(
                label: const Text('By name'),
                checked: true,
                onPressed: () {},
              ),
              DsMenuItem(
                label: const Text('Show grid'),
                checked: true,
                checkRole: DsMenuCheckRole.checkbox,
                onPressed: () {},
              ),
              DsMenuItem(
                label: const Text('Show rulers'),
                checked: false,
                checkRole: .checkbox,
                onPressed: () {},
              ),
              DsMenuItem(label: const Text('Rename'), onPressed: () {}),
            ],
          ),
        ),
      );
      SemanticsData data(String label) =>
          tester.getSemantics(find.text(label)).getSemanticsData();

      expect(data('By name').role, SemanticsRole.menuItemRadio);
      expect(data('By name').flagsCollection.isChecked, CheckedState.isTrue);
      expect(data('Show grid').role, SemanticsRole.menuItemCheckbox);
      expect(data('Show grid').flagsCollection.isChecked, CheckedState.isTrue);
      expect(data('Show rulers').role, SemanticsRole.menuItemCheckbox);
      expect(
        data('Show rulers').flagsCollection.isChecked,
        CheckedState.isFalse,
      );
      expect(data('Rename').role, SemanticsRole.menuItem);
      handle.dispose();
    });

    testWidgets('a checkbox item looks like a radio item', (tester) async {
      Future<List<DsIconData>> icons(DsMenuCheckRole role) async {
        await tester.pumpWidget(
          app(
            DsMenu(
              children: [
                DsMenuItem(
                  label: const Text('Show grid'),
                  checked: true,
                  checkRole: role,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
        return [
          for (final icon in tester.widgetList<DsIcon>(find.byType(DsIcon)))
            icon.icon,
        ];
      }

      expect(
        await icons(DsMenuCheckRole.checkbox),
        await icons(DsMenuCheckRole.radio),
      );
    });

    testWidgets('a select\'s options are radio items, a multi-select\'s '
        'checkbox items', (tester) async {
      final handle = tester.ensureSemantics();
      const options = [
        DsSelectOption(value: 'a', label: 'Alpha'),
        DsSelectOption(value: 'b', label: 'Beta'),
      ];
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 240,
            child: DsSelect<String>(
              value: 'a',
              onChanged: (_) {},
              options: options,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DsSelect<String>));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('Beta').last).getSemanticsData().role,
        SemanticsRole.menuItemRadio,
      );

      await tester.pumpWidget(
        app(
          SizedBox(
            width: 240,
            child: DsMultiSelect<String>(
              value: const ['a'],
              onChanged: (_) {},
              options: options,
              semanticLabel: 'Letters',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('Beta').last).getSemanticsData().role,
        SemanticsRole.menuItemCheckbox,
      );
      handle.dispose();
    });
  });

  group('shortcuts', () {
    test('symbols are read by their localized names', () {
      const en = DsLocalizationsEn(), tr = DsLocalizationsTr();
      expect(DsShortcut.spokenLabel('⌘E', en), 'Command E');
      expect(DsShortcut.spokenLabel('⇧⌘⌫', en), 'Shift Command Backspace');
      expect(DsShortcut.spokenLabel('⌃⌥⏎', en), 'Control Option Enter');
      expect(DsShortcut.spokenLabel('⌘↵', en), 'Command Enter');
      // Text stays as written.
      expect(DsShortcut.spokenLabel('Ctrl+K', en), 'Ctrl+K');
      expect(DsShortcut.spokenLabel('F8', en), 'F8');
      expect(DsShortcut.spokenLabel('⇧⌘E', tr), 'Üst Karakter Komut E');
    });

    testWidgets('a menu item reads its shortcut by name', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsMenu(
            children: [
              DsMenuItem(
                label: const Text('Edit'),
                shortcut: '⌘E',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      final label = tester
          .getSemantics(find.text('Edit'))
          .getSemanticsData()
          .label;
      expect(label, 'Edit\nCommand E');
      expect(label, isNot(contains('⌘')));
      handle.dispose();
    });
  });
  group('context menu region', () {
    Widget region() => app(
      SizedBox(
        width: 400,
        child: DsContextMenuRegion(
          items: [DsMenuItem(label: const Text('Open'), onPressed: () {})],
          child: DsListRow(title: const Text('a.pdf'), onPressed: () {}),
        ),
      ),
    );

    testWidgets('adds no node of its own around the row', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(region());
      final row = tester.getSemantics(find.text('a.pdf'));
      var parent = row.parent;
      while (parent != null) {
        final data = parent.getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isFalse);
        expect(data.hasAction(SemanticsAction.longPress), isFalse);
        parent = parent.parent;
      }
      handle.dispose();
    });

    testWidgets('the row opens the menu on a long press or "Show menu"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(region());
      final row = tester.getSemantics(find.text('a.pdf'));
      final data = row.getSemanticsData();
      expect(data.label, 'a.pdf');
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hasAction(SemanticsAction.longPress), isTrue);
      expect(
        [
          for (final id in data.customSemanticsActionIds ?? <int>[])
            CustomSemanticsAction.getAction(id)!.label,
        ],
        ['Show menu'],
      );

      tester.semantics.performAction(
        find.semantics.byLabel('a.pdf'),
        SemanticsAction.longPress,
      );
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsNothing);

      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.customAction,
          viewId: tester.view.viewId,
          nodeId: tester.getSemantics(find.text('a.pdf')).id,
          arguments: CustomSemanticsAction.getIdentifier(
            const CustomSemanticsAction(label: 'Show menu'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('only the outer pressable offers the menu', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsContextMenuRegion(
            items: [DsMenuItem(label: const Text('Open'), onPressed: () {})],
            child: DsCard(
              onPressed: () {},
              child: DsButton(onPressed: () {}, child: const Text('Share')),
            ),
          ),
        ),
      );
      final button = tester.getSemantics(find.text('Share')).getSemanticsData();
      expect(button.hasAction(SemanticsAction.longPress), isFalse);
      expect(button.customSemanticsActionIds ?? <int>[], isEmpty);
      handle.dispose();
    });
  });
}
