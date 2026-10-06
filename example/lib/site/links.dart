import 'package:flutter/widgets.dart';

/// Opens site pages from anywhere below the shell.
class SiteLinks extends InheritedWidget {
  const SiteLinks({
    super.key,
    required this.path,
    required this.go,
    required super.child,
  });

  /// The page on screen.
  final String path;

  /// Shows the page at a site path such as `/components/button`.
  final ValueChanged<String> go;

  static SiteLinks of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SiteLinks>()!;

  /// Opens [target]: a site path, or (not yet supported) an outside
  /// address.
  void open(String target) {
    if (target.startsWith('/')) go(target);
  }

  @override
  bool updateShouldNotify(SiteLinks old) => old.path != path;
}
