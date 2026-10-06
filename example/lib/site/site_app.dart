import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import 'links.dart';
import 'router.dart';
import 'settings.dart';
import 'shell.dart';

/// The documentation site: every page built with Desen itself.
class SiteApp extends StatefulWidget {
  const SiteApp({super.key});

  @override
  State<SiteApp> createState() => _SiteAppState();
}

class _SiteAppState extends State<SiteApp> {
  var _settings = SiteSettings.fromQuery(Uri.base.queryParameters);

  late final SiteRouterDelegate _delegate = SiteRouterDelegate(
    builder: (context, path) => SiteLinks(
      path: path,
      go: _delegate.go,
      child: SiteShell(path: path),
    ),
  );

  late final _router = RouterConfig<String>(
    routerDelegate: _delegate,
    routeInformationParser: const SiteRouteParser(),
    routeInformationProvider: PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(
        uri: Uri.parse(
          WidgetsBinding.instance.platformDispatcher.defaultRouteName,
        ),
      ),
    ),
    backButtonDispatcher: RootBackButtonDispatcher(),
  );

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DsApp.router(
    title: 'Desen UI',
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    themeMode: _settings.mode,
    theme: _settings.theme(),
    routerConfig: _router,
    builder: (context, child) => SiteSettingsScope(
      settings: _settings,
      onChanged: (s) => setState(() => _settings = s),
      child: child!,
    ),
  );
}
