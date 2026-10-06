import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui_example/site/links.dart';
import 'package:desen_ui_example/site/pages.dart';
import 'package:desen_ui_example/site/settings.dart';
import 'package:desen_ui_example/site/shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every page of the docs site opens at phone, tablet, laptop and desktop
/// widths, in light and dark, without an overflow or an error (KALITE 9a).
void main() {
  const widths = [390.0, 768.0, 1280.0, 1600.0];
  final paths = [
    for (final group in siteGroups)
      for (final page in group.pages) page.path,
  ];

  Widget site(String path, {DsThemeMode mode = DsThemeMode.light}) => DsApp(
    locale: const Locale('en'),
    themeMode: mode,
    home: SiteSettingsScope(
      settings: SiteSettings(mode: mode),
      onChanged: (_) {},
      child: SiteLinks(
        path: path,
        go: (_) {},
        child: SiteShell(path: path),
      ),
    ),
  );

  for (final path in paths) {
    testWidgets('$path fits every width', (tester) async {
      for (final width in widths) {
        tester.view
          ..physicalSize = Size(width, 900)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(site(path));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull, reason: '$path at $width');
      }
      // Dark at one width: the same widgets, other tokens.
      await tester.pumpWidget(site(path, mode: DsThemeMode.dark));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: '$path dark');
      // Let timers (toasts, demos) finish.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    });
  }
}
