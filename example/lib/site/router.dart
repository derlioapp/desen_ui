import 'package:flutter/widgets.dart';

/// Keeps the site's one page in sync with the address bar (`#/path`), so
/// links, reloads and the browser's back and forward buttons work while
/// the shell (header, sidebar) stays put.
class SiteRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  SiteRouterDelegate({required this.builder});

  /// Builds the shell for a path.
  final Widget Function(BuildContext context, String path) builder;

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  String _path = '/';
  String get path => _path;

  void go(String path) {
    if (path == _path) return;
    _path = path;
    notifyListeners();
  }

  @override
  String get currentConfiguration => _path;

  @override
  Future<void> setNewRoutePath(String configuration) async {
    _path = configuration;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    pages: [_ShellPage(child: builder(context, _path))],
    onDidRemovePage: (_) {},
  );
}

class SiteRouteParser extends RouteInformationParser<String> {
  const SiteRouteParser();

  @override
  Future<String> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final path = routeInformation.uri.path;
    return path.isEmpty ? '/' : path;
  }

  @override
  RouteInformation restoreRouteInformation(String configuration) =>
      RouteInformation(uri: Uri(path: configuration));
}

/// The shell as the navigator's only page; dialogs and panels push above
/// it.
class _ShellPage extends Page<void> {
  const _ShellPage({required this.child}) : super(key: const ValueKey('shell'));

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => _ShellRoute(this);
}

class _ShellRoute extends PageRoute<void> {
  _ShellRoute(_ShellPage page) : super(settings: page);

  _ShellPage get _page => settings as _ShellPage;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _page.child;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;
}
