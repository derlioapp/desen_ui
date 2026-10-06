import '../../registry.dart';
import 'button_page.dart';
import 'link_page.dart';
import 'menu_page.dart';
import 'toolbar_page.dart';

/// The "Actions" pages, in sidebar order.
final actionPages = <SitePage>[
  SitePage(
    path: '/components/button',
    title: 'Button',
    builder: (_) => const ButtonPage(),
    keywords: ['DsButton', 'icon button', 'action'],
  ),
  SitePage(
    path: '/components/link',
    title: 'Link',
    builder: (_) => const LinkPage(),
    keywords: ['DsLink', 'anchor', 'href', 'external link', 'url'],
  ),
  SitePage(
    path: '/components/toolbar',
    title: 'Toolbar',
    builder: (_) => const ToolbarPage(),
    keywords: [
      'DsToolbar',
      'DsToolbarToggle',
      'DsToolbarDivider',
      'toggle button',
      'formatting bar',
    ],
  ),
  SitePage(
    path: '/components/menu',
    title: 'Menu',
    builder: (_) => const MenuPage(),
    keywords: [
      'DsMenu',
      'DsMenuAnchor',
      'DsMenuItem',
      'DsMenuDivider',
      'DsShortcut',
      'DsContextMenuRegion',
      'dropdown menu',
      'context menu',
      'right-click',
      'submenu',
      'keyboard shortcut',
    ],
  ),
];
