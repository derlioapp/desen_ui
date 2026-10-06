import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Menu and select options (regression tests).
void main() {
  const long =
      'Internationalisation configuration settings for the organisation';

  RenderParagraph paragraph(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(
        find.descendant(of: find.byType(DsMenu), matching: find.text(text)),
      );

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget app(Widget child, {double scale = 1}) => DsApp(
    theme: DsThemeData(platform: TargetPlatform.macOS),
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: c!,
    ),
    home: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    ),
  );

  group('checked items (choice menus)', () {
    Finder check() =>
        find.byWidgetPredicate((w) => w is DsIcon && w.icon == DsIcons.check);

    for (final rtl in [false, true]) {
      testWidgets('a check in the leading gutter; labels line up '
          '(${rtl ? 'RTL' : 'LTR'})', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          app(
            Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: SizedBox(
                width: 240,
                child: DsMenu(
                  children: [
                    DsMenuItem(
                      label: const Text('List'),
                      checked: true,
                      onPressed: () {},
                    ),
                    DsMenuItem(
                      label: const Text('Board'),
                      checked: false,
                      onPressed: () {},
                    ),
                    const DsMenuDivider(),
                    DsMenuItem(label: const Text('Settings'), onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(check(), findsOneWidget);
        final mark = tester.getRect(check());
        final list = tester.getRect(find.text('List'));
        final start = [
          for (final label in ['List', 'Board', 'Settings'])
            rtl
                ? tester.getRect(find.text(label)).right
                : tester.getRect(find.text(label)).left,
        ];
        expect(start.toSet(), hasLength(1), reason: 'labels line up');
        if (rtl) {
          expect(mark.left, greaterThan(list.right));
        } else {
          expect(mark.right, lessThan(list.left));
        }
        expect(mark.center.dy, moreOrLessEquals(list.center.dy, epsilon: 1));
        expect(
          tester.getSemantics(find.text('List')),
          isSemantics(isChecked: true, hasCheckedState: true),
        );
        expect(
          tester.getSemantics(find.text('Board')),
          isSemantics(isChecked: false, hasCheckedState: true),
        );
        semantics.dispose();
      });
    }

    testWidgets('with icons: a check column, then the icon column', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 260,
            child: DsMenu(
              children: [
                DsMenuItem(
                  label: const Text('Grid'),
                  leading: const DsIcon(DsIcons.search),
                  checked: true,
                  onPressed: () {},
                ),
                DsMenuItem(
                  label: const Text('Plain'),
                  checked: false,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(check(), findsOneWidget);
      final icon = find.byWidgetPredicate(
        (w) => w is DsIcon && w.icon == DsIcons.search,
      );
      expect(
        tester.getRect(check()).right,
        lessThan(tester.getRect(icon).left),
      );
      expect(
        tester.getRect(find.text('Grid')).left,
        tester.getRect(find.text('Plain')).left,
      );
    });

    testWidgets('a select shows its choice with the same leading check', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 240,
            child: DsSelect<int>(
              value: 2,
              onChanged: (_) {},
              options: const [
                DsSelectOption(value: 1, label: 'One'),
                DsSelectOption(value: 2, label: 'Two'),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DsSelect<int>));
      await tester.pumpAndSettle();
      expect(check(), findsOneWidget);
      final two = find.descendant(
        of: find.byType(DsMenu),
        matching: find.text('Two'),
      );
      expect(tester.getRect(check()).right, lessThan(tester.getRect(two).left));
    });
  });

  group('long option labels wrap once, then end in an ellipsis', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('select at 320px, text scale $scale', (tester) async {
        await phone(tester);
        await tester.pumpWidget(
          app(
            SizedBox(
              width: 304,
              child: DsSelect<int>(
                value: 1,
                onChanged: (_) {},
                options: const [
                  DsSelectOption(value: 1, label: long),
                  DsSelectOption(value: 2, label: 'Short'),
                ],
              ),
            ),
            scale: scale,
          ),
        );
        await tester.tap(find.byType(DsSelect<int>));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final p = paragraph(tester, long);
        expect(p.maxLines, 2);
        // At 1x the whole label fits in two lines.
        if (scale == 1) expect(p.didExceedMaxLines, isFalse);
        final line = p.preferredLineHeight;
        final row = tester.getSize(
          find
              .ancestor(of: find.text(long), matching: find.byType(DsMenuItem))
              .first,
        );
        // Two lines plus a little air; never more than two lines tall.
        expect(row.height, greaterThanOrEqualTo(2 * line));
        expect(row.height, lessThanOrEqualTo(2 * line + 2 * DsSpace.s4 + 1));
        // A one-line option keeps its row height at 1x.
        if (scale == 1) {
          expect(
            tester
                .getSize(
                  find
                      .ancestor(
                        of: find.text('Short'),
                        matching: find.byType(DsMenuItem),
                      )
                      .first,
                )
                .height,
            32,
          );
        }
      });
    }
  });

  testWidgets('a lone icon does not push its label out of line', (
    tester,
  ) async {
    final c = DsOverlayController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      app(
        DsMenuAnchor(
          controller: c,
          items: [
            DsMenuItem(label: const Text('Edit'), onPressed: () {}),
            DsMenuItem(
              label: const Text('Move'),
              leading: const DsIcon(DsIcons.folder),
              onPressed: () {},
            ),
            DsMenuItem(label: const Text('Delete'), onPressed: () {}),
          ],
          child: DsButton(onPressed: c.toggle, child: const Text('Menu')),
        ),
      ),
    );
    c.open();
    await tester.pumpAndSettle();
    final starts = [
      for (final t in ['Edit', 'Move', 'Delete'])
        tester.getTopLeft(find.text(t)).dx,
    ];
    expect(starts.toSet(), hasLength(1), reason: '$starts');
  });

  testWidgets('a submenu meets the parent edge and leaves the item\'s '
      'highlight whole', (tester) async {
    final c = DsOverlayController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      app(
        DsMenuAnchor(
          controller: c,
          items: [
            DsMenuItem.submenu(
              label: const Text('Move'),
              submenu: [
                DsMenuItem(label: const Text('Archive'), onPressed: () {}),
              ],
            ),
          ],
          child: DsButton(onPressed: c.toggle, child: const Text('Menu')),
        ),
      ),
    );
    c.open();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    final menus = find.byType(DsMenu);
    final parent = tester.getRect(menus.first);
    final sub = tester.getRect(menus.last);
    final item = tester.getRect(
      find.ancestor(of: find.text('Move'), matching: find.byType(DsPressable)),
    );
    expect(sub.left, greaterThanOrEqualTo(item.right), reason: 'highlight');
    expect(sub.left, lessThanOrEqualTo(parent.right), reason: 'attached');
    expect(parent.right - sub.left, lessThanOrEqualTo(4));
  });

  testWidgets('an empty select says it has no options', (tester) async {
    await tester.pumpWidget(
      app(
        SizedBox(
          width: 240,
          child: DsSelect<int>(value: null, onChanged: (_) {}, options: []),
        ),
      ),
    );
    await tester.tap(find.byType(DsSelect<int>));
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
    expect(tester.getSize(find.byType(DsMenu)).height, greaterThan(32));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsNothing);
  });
}
