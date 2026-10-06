import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// DsApp passes WidgetsApp's and DsScope's options through, in both its
/// navigator and router forms.
void main() {
  /// What a page sees.
  late BuildContext page;
  final probe = Builder(
    builder: (context) {
      page = context;
      return const SizedBox();
    },
  );

  group('DsApp.router', () {
    testWidgets('sets up the theme, canvas, scroll behavior and strings', (
      tester,
    ) async {
      final theme = DsThemeData(seed: DsSeed.forest);
      await tester.pumpWidget(
        DsApp.router(
          routerConfig: RouterConfig(routerDelegate: _Delegate(probe)),
          theme: theme,
          themeMode: DsThemeMode.light,
          locale: const Locale('tr'),
        ),
      );
      expect(DsTheme.of(page).seed, DsSeed.forest);
      expect(ScrollConfiguration.of(page), isA<DsScrollBehavior>());
      expect(Localizations.localeOf(page), const Locale('tr'));
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == theme.colors.canvas,
        ),
        findsWidgets,
      );
    });

    testWidgets('passes the new options through', (tester) async {
      await tester.pumpWidget(
        DsApp.router(
          routerConfig: RouterConfig(routerDelegate: _Delegate(probe)),
          theme: DsThemeData(contrast: DsContrast.soft),
          followPlatformContrast: false,
          animateChanges: false,
          scrollBehavior: const _Behavior(),
          supportedLocales: const [Locale('en'), Locale('tr')],
          localeResolutionCallback: (_, _) => const Locale('tr'),
        ),
      );
      final scope = tester.widget<DsScope>(find.byType(DsScope));
      expect(scope.followPlatformContrast, isFalse);
      expect(scope.animateChanges, isFalse);
      expect(ScrollConfiguration.of(page), isA<_Behavior>());
      expect(Localizations.localeOf(page), const Locale('tr'));
    });
  });

  group('DsApp', () {
    testWidgets('passes the new options through', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        DsApp(
          theme: DsThemeData(contrast: DsContrast.soft),
          followPlatformContrast: false,
          animateChanges: false,
          scrollBehavior: const _Behavior(),
          supportedLocales: const [Locale('en'), Locale('tr')],
          localeListResolutionCallback: (_, _) => const Locale('tr'),
          home: probe,
        ),
      );
      final scope = tester.widget<DsScope>(find.byType(DsScope));
      expect(scope.followPlatformContrast, isFalse);
      expect(scope.animateChanges, isFalse);
      // More contrast is ignored: the soft theme stays soft.
      expect(DsTheme.of(page).contrast, DsContrast.soft);
      expect(ScrollConfiguration.of(page), isA<_Behavior>());
      expect(Localizations.localeOf(page), const Locale('tr'));
    });

    testWidgets('follows the platform contrast by default', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        DsApp(
          theme: DsThemeData(contrast: DsContrast.soft),
          home: probe,
        ),
      );
      expect(DsTheme.of(page).contrast, DsContrast.standard);
      expect(ScrollConfiguration.of(page), isA<DsScrollBehavior>());
    });
  });
}

class _Behavior extends ScrollBehavior {
  const _Behavior();
}

/// A router that always shows [page].
class _Delegate extends RouterDelegate<Object> with ChangeNotifier {
  _Delegate(this.page);

  final Widget page;

  @override
  Widget build(BuildContext context) => page;

  @override
  Future<bool> popRoute() => SynchronousFuture(false);

  @override
  Future<void> setNewRoutePath(Object configuration) => SynchronousFuture(null);
}
