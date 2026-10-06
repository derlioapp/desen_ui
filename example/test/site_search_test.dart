import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui_example/site/links.dart';
import 'package:desen_ui_example/site/settings.dart';
import 'package:desen_ui_example/site/shell.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ctrl+K opens the palette from anywhere; typing filters, the arrows
/// move and Enter opens the page.
void main() {
  testWidgets('Ctrl+K, type, arrow, Enter', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? opened;
    await tester.pumpWidget(
      DsApp(
        locale: const Locale('en'),
        home: SiteSettingsScope(
          settings: const SiteSettings(),
          onChanged: (_) {},
          child: SiteLinks(
            path: '/',
            go: (p) => opened = p,
            child: const SiteShell(path: '/'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Search pages'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(DsSearchField),
        matching: find.byType(EditableText),
      ),
      'calendar',
    );
    await tester.pump();
    // Date picker (tagged "calendar") comes first in sidebar order, then
    // Calendar; Down moves to the second.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened, '/components/calendar');
    expect(find.text('Search pages'), findsNothing);
  });
}
