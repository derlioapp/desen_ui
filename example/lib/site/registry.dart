import 'package:flutter/widgets.dart';

/// One page of the site: its address, its name in the navigation and how
/// to build it.
@immutable
class SitePage {
  const SitePage({
    required this.path,
    required this.title,
    required this.builder,
    this.keywords = const [],
    this.summary,
  });

  /// The address after `#`, e.g. `/components/button`.
  final String path;

  /// The name in the sidebar and the browser tab.
  final String title;

  final WidgetBuilder builder;

  /// Extra words the quick search matches (e.g. "dropdown" for select).
  final List<String> keywords;

  /// One line for overview cards and search results.
  final String? summary;
}

/// A titled run of pages in the sidebar.
@immutable
class SiteGroup {
  const SiteGroup(this.title, this.pages);

  final String title;
  final List<SitePage> pages;
}
