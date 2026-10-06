import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A breadcrumb level can lead with an icon: in the label's color and the
/// style's icon size, before the label, hidden from screen readers.
void main() {
  final theme = DsThemeData.light();
  final pressed = <String>[];
  setUp(pressed.clear);

  Finder house() =>
      find.byWidgetPredicate((w) => w is DsIcon && w.icon == DsIcons.house);

  List<DsBreadcrumbItem> path({bool iconOnCurrent = false}) => [
    DsBreadcrumbItem(
      label: 'Home',
      icon: const DsIcon(DsIcons.house),
      onPressed: () => pressed.add('Home'),
    ),
    DsBreadcrumbItem(label: 'Projects', onPressed: () => pressed.add('P')),
    DsBreadcrumbItem(
      label: 'Website',
      icon: iconOnCurrent ? const DsIcon(DsIcons.folder) : null,
    ),
  ];

  testWidgets('the icon sits before the label in its color and size', (
    tester,
  ) async {
    await tester.pumpWidget(host(DsBreadcrumb(items: path()), theme: theme));
    final icon = tester.getRect(house());
    final label = tester.getRect(find.textContaining('Home'));
    expect(icon.width, theme.sizes.iconXs);
    expect(icon.left, greaterThanOrEqualTo(label.left));
    // Vertically centered on the line.
    expect(icon.center.dy, moreOrLessEquals(label.center.dy, epsilon: 1.5));
    final ink = IconTheme.of(tester.element(house()));
    expect(ink.color, DsBreadcrumb.defaultStyle(theme).foreground);
  });

  testWidgets('mirrors in right-to-left text', (tester) async {
    await tester.pumpWidget(
      host(
        DsBreadcrumb(items: path()),
        theme: theme,
        direction: TextDirection.rtl,
      ),
    );
    final icon = tester.getRect(house());
    final level = tester.getRect(find.textContaining('Home'));
    // The icon leads, on the right.
    expect(icon.right, moreOrLessEquals(level.right, epsilon: 1));
  });

  testWidgets('the level is still a link named by its label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(DsBreadcrumb(items: path(iconOnCurrent: true)), theme: theme),
    );
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Website'), findsOneWidget);
    await tester.tap(house());
    expect(pressed, ['Home']);
    semantics.dispose();
  });

  testWidgets('style sets the icon size and gap', (tester) async {
    await tester.pumpWidget(
      host(
        DsBreadcrumb(
          items: path(),
          style: const DsBreadcrumbStyle(iconSize: 20, iconGap: 10),
        ),
        theme: theme,
      ),
    );
    expect(tester.getSize(house()), const Size(20, 20));
  });

  testWidgets('collapsing counts the icon and the menu shows it', (
    tester,
  ) async {
    final items = [
      DsBreadcrumbItem(
        label: 'Acme',
        icon: const DsIcon(DsIcons.house),
        onPressed: () {},
      ),
      for (final label in ['Website redesign', 'Settings', 'Integrations'])
        DsBreadcrumbItem(
          label: label,
          icon: const DsIcon(DsIcons.folder),
          onPressed: () {},
        ),
      const DsBreadcrumbItem(label: 'Webhooks'),
    ];
    await tester.pumpWidget(
      DsApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: DsBreadcrumb(
              items: items,
              overflow: DsBreadcrumbOverflow.collapse,
            ),
          ),
        ),
      ),
    );
    // Fits on one line with the icons counted: nothing overflows.
    expect(tester.takeException(), isNull);
    final more = find.byWidgetPredicate(
      (w) => w is DsIcon && w.icon == DsIcons.ellipsis,
    );
    expect(more, findsOneWidget);
    await tester.tap(more);
    await tester.pumpAndSettle();
    // The hidden levels' icons come along into the menu.
    expect(
      find.descendant(
        of: find.byType(DsMenuItem),
        matching: find.byWidgetPredicate(
          (w) => w is DsIcon && w.icon == DsIcons.folder,
        ),
      ),
      findsWidgets,
    );
  });
}
