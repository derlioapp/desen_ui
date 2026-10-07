import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui_example/site/doc.dart';
import 'package:desen_ui_example/site/links.dart';
import 'package:desen_ui_example/site/pages/examples/dashboard_page.dart';
import 'package:desen_ui_example/site/pages/examples/northwind.dart';
import 'package:desen_ui_example/site/settings.dart';
import 'package:desen_ui_example/site/shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Details of the docs site: inline code is a padded, rounded chip on the
/// text's baseline, and the phone task list keeps the due date when it
/// runs out of room.
void main() {
  testWidgets('inline code is a rounded chip, smaller than the prose', (
    tester,
  ) async {
    await tester.pumpWidget(
      const DsApp(home: Center(child: DocText('Use `md` for most buttons.'))),
    );
    final code = find.text('md');
    expect(code, findsOneWidget);
    final chip = tester.widget<Container>(
      find.ancestor(of: code, matching: find.byType(Container)).first,
    );
    final box = chip.decoration! as DsBoxDecoration;
    expect(box.borderRadius, isNot(BorderRadius.zero));
    expect(chip.padding, isNot(EdgeInsets.zero));
    final codeSize = tester.widget<Text>(code).style!.fontSize!;
    final body = DsTheme.of(tester.element(code)).typography.body.fontSize!;
    expect(codeSize, lessThan(body));
    // On the text's baseline, inside the paragraph.
    final span = tester
        .widget<RichText>(
          find.ancestor(of: code, matching: find.byType(RichText)).last,
        )
        .text;
    var placed = false;
    span.visitChildren((s) {
      if (s is WidgetSpan) {
        placed = s.alignment == PlaceholderAlignment.baseline;
      }
      return true;
    });
    expect(placed, isTrue);
  });

  testWidgets('the phone task list leads with the due date', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // On the site the dashboard sits in a scrolling page and takes its own
    // height; a fixed 900px box would overflow the phone layout.
    await tester.pumpWidget(
      DsApp(
        home: SiteLinks(
          path: '/',
          go: (_) {},
          child: const SingleChildScrollView(child: NorthwindDashboard()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final task = seedTasks().firstWhere((t) => t.isOpen && t.due != null);
    final meta = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.textSpan != null &&
          w.textSpan!.toPlainText() == '${shortDate(task.due!)} · ${task.key}',
    );
    expect(meta, findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the icon browser finds icons by tag and by alias', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1280, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DsApp(
        locale: const Locale('en'),
        home: SiteSettingsScope(
          settings: const SiteSettings(),
          onChanged: (_) {},
          child: SiteLinks(
            path: '/foundations/icons',
            go: (_) {},
            child: const SiteShell(path: '/foundations/icons'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final search = find.descendant(
      of: find.bySemanticsLabel('Search icons'),
      matching: find.byType(EditableText),
    );
    await tester.enterText(search, 'warning');
    await tester.pump();
    expect(find.text('triangleAlert'), findsOneWidget);
    await tester.enterText(search, 'volumeUp');
    await tester.pump();
    expect(find.text('volume2'), findsWidgets);
    expect(find.text('triangleAlert'), findsNothing);
  });
}
