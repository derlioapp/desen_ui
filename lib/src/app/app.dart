import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../l10n/direction.dart';
import '../l10n/localizations.dart';
import '../theme/theme.dart';
import '../theme/theme_data.dart';
import 'page_route.dart';
import 'scroll_behavior.dart';

/// A convenience app root: a [WidgetsApp] with [DsScope], [DsScrollBehavior]
/// and [DsPageRoute] wired in.
///
/// Optional. Desen components work under any app root; to use them inside an
/// existing `MaterialApp`, wrap the subtree in [DsScope] instead.
class DsApp extends StatelessWidget {
  /// Creates an app driven by a [Navigator].
  const DsApp({
    super.key,
    this.navigatorKey,
    this.home,
    this.routes = const <String, WidgetBuilder>{},
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.theme,
    this.darkTheme,
    this.themeMode = DsThemeMode.system,
    this.followPlatformContrast = true,
    this.animateChanges = true,
    this.scrollBehavior,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales,
    this.localeResolutionCallback,
    this.localeListResolutionCallback,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.debugShowCheckedModeBanner = true,
  }) : routerConfig = null;

  /// Creates an app driven by a [Router], e.g. with go_router.
  const DsApp.router({
    super.key,
    required RouterConfig<Object> this.routerConfig,
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.theme,
    this.darkTheme,
    this.themeMode = DsThemeMode.system,
    this.followPlatformContrast = true,
    this.animateChanges = true,
    this.scrollBehavior,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales,
    this.localeResolutionCallback,
    this.localeListResolutionCallback,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.debugShowCheckedModeBanner = true,
  }) : navigatorKey = null,
       home = null,
       routes = const <String, WidgetBuilder>{},
       initialRoute = null,
       onGenerateRoute = null,
       onUnknownRoute = null,
       navigatorObservers = const <NavigatorObserver>[];

  /// See [WidgetsApp.navigatorKey].
  final GlobalKey<NavigatorState>? navigatorKey;

  /// See [WidgetsApp.home].
  final Widget? home;

  /// See [WidgetsApp.routes].
  final Map<String, WidgetBuilder> routes;

  /// See [WidgetsApp.initialRoute].
  final String? initialRoute;

  /// See [WidgetsApp.onGenerateRoute].
  final RouteFactory? onGenerateRoute;

  /// See [WidgetsApp.onUnknownRoute].
  final RouteFactory? onUnknownRoute;

  /// See [WidgetsApp.navigatorObservers].
  final List<NavigatorObserver> navigatorObservers;

  /// See [WidgetsApp.routerConfig].
  final RouterConfig<Object>? routerConfig;

  /// See [WidgetsApp.builder]. Runs inside [DsScope], so it can read the
  /// theme.
  final TransitionBuilder? builder;

  /// See [WidgetsApp.title].
  final String title;

  /// See [WidgetsApp.onGenerateTitle].
  final GenerateAppTitle? onGenerateTitle;

  /// See [DsScope.theme].
  final DsThemeData? theme;

  /// See [DsScope.darkTheme].
  final DsThemeData? darkTheme;

  /// See [DsScope.themeMode].
  final DsThemeMode themeMode;

  /// See [DsScope.followPlatformContrast].
  final bool followPlatformContrast;

  /// See [DsScope.animateChanges].
  final bool animateChanges;

  /// The scroll behavior of the whole app. Defaults to [DsScrollBehavior]:
  /// Desen's scrollbars, drag with every pointer, no overscroll glow.
  final ScrollBehavior? scrollBehavior;

  /// See [WidgetsApp.locale].
  final Locale? locale;

  /// See [WidgetsApp.localizationsDelegates]. Desen adds
  /// [DsWidgetsLocalizations.delegate] after these, for the text direction.
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  /// See [WidgetsApp.supportedLocales]. Defaults to [locale] when it is
  /// given, else to English, like Flutter's own app widgets: an app
  /// without translations stays in English (and left to right) on a
  /// device set to Arabic or Turkish.
  ///
  /// To follow the device's language, list the locales the app is
  /// translated into, or every locale Desen has strings for:
  /// `supportedLocales:` [DsLocalizations.supportedLocales].
  final Iterable<Locale>? supportedLocales;

  /// See [WidgetsApp.localeResolutionCallback].
  final LocaleResolutionCallback? localeResolutionCallback;

  /// See [WidgetsApp.localeListResolutionCallback].
  final LocaleListResolutionCallback? localeListResolutionCallback;

  /// See [WidgetsApp.shortcuts].
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// See [WidgetsApp.actions].
  final Map<Type, Action<Intent>>? actions;

  /// See [WidgetsApp.restorationScopeId].
  final String? restorationScopeId;

  /// See [WidgetsApp.debugShowCheckedModeBanner].
  final bool debugShowCheckedModeBanner;

  // Yours first: the first delegate of each type wins, so a
  // `GlobalWidgetsLocalizations.delegate` you pass replaces Desen's.
  Iterable<LocalizationsDelegate<dynamic>> get _delegates => [
    ...?localizationsDelegates,
    DsWidgetsLocalizations.delegate,
  ];

  Widget _builder(BuildContext context, Widget? child) => DsScope(
    theme: theme,
    darkTheme: darkTheme,
    themeMode: themeMode,
    followPlatformContrast: followPlatformContrast,
    animateChanges: animateChanges,
    child: Builder(
      builder: (context) => ScrollConfiguration(
        behavior: scrollBehavior ?? const DsScrollBehavior(),
        child: ColoredBox(
          color: DsTheme.colorsOf(context).canvas,
          child: builder?.call(context, child) ?? child ?? const SizedBox(),
        ),
      ),
    ),
  );

  Iterable<Locale> get _supportedLocales =>
      supportedLocales ?? [locale ?? const Locale('en')];

  @override
  Widget build(BuildContext context) {
    final color = (theme ?? DsThemeData()).colors.accent;
    if (routerConfig != null) {
      return WidgetsApp.router(
        routerConfig: routerConfig,
        builder: _builder,
        title: title,
        onGenerateTitle: onGenerateTitle,
        color: color,
        locale: locale,
        localizationsDelegates: _delegates,
        supportedLocales: _supportedLocales,
        localeResolutionCallback: localeResolutionCallback,
        localeListResolutionCallback: localeListResolutionCallback,
        shortcuts: shortcuts,
        actions: actions,
        restorationScopeId: restorationScopeId,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      );
    }
    return WidgetsApp(
      navigatorKey: navigatorKey,
      home: home,
      routes: routes,
      initialRoute: initialRoute,
      onGenerateRoute: onGenerateRoute,
      onUnknownRoute: onUnknownRoute,
      navigatorObservers: navigatorObservers,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          DsPageRoute<T>(settings: settings, builder: builder),
      builder: _builder,
      title: title,
      onGenerateTitle: onGenerateTitle,
      color: color,
      locale: locale,
      localizationsDelegates: _delegates,
      supportedLocales: _supportedLocales,
      localeResolutionCallback: localeResolutionCallback,
      localeListResolutionCallback: localeListResolutionCallback,
      shortcuts: shortcuts,
      actions: actions,
      restorationScopeId: restorationScopeId,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(EnumProperty('themeMode', themeMode))
      ..add(
        FlagProperty(
          'followPlatformContrast',
          value: followPlatformContrast,
          ifFalse: 'ignores platform contrast',
        ),
      )
      ..add(
        FlagProperty(
          'animateChanges',
          value: animateChanges,
          ifFalse: 'theme changes at once',
        ),
      );
  }
}
