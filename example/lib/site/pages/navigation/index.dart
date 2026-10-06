import '../../registry.dart';
import 'accordion_page.dart';
import 'bottom_nav_page.dart';
import 'breadcrumb_page.dart';
import 'pagination_page.dart';
import 'pane_header_page.dart';
import 'scrollbar_page.dart';
import 'sidebar_page.dart';
import 'tabs_page.dart';

/// The "Navigation" pages, in sidebar order.
final navigationPages = <SitePage>[
  SitePage(
    path: '/components/tabs',
    title: 'Tabs',
    builder: (_) => const TabsPage(),
    keywords: ['DsTabs', 'DsTab', 'tab bar'],
    summary: 'Moves between sections of the same page.',
  ),
  SitePage(
    path: '/components/sidebar',
    title: 'Sidebar',
    builder: (_) => const SidebarPage(),
    keywords: ['DsSidebar', 'DsSidebarItem', 'DsSidebarSection', 'side nav'],
    summary: 'The main navigation of a desktop app.',
  ),
  SitePage(
    path: '/components/bottom-navigation',
    title: 'Bottom navigation',
    builder: (_) => const BottomNavPage(),
    keywords: ['DsBottomNav', 'tab bar', 'mobile', 'phone'],
    summary: 'The main navigation of a phone app.',
  ),
  SitePage(
    path: '/components/pagination',
    title: 'Pagination',
    builder: (_) => const PaginationPage(),
    keywords: ['DsPagination', 'pages', 'pager'],
    summary: 'Moves through a result split into pages.',
  ),
  SitePage(
    path: '/components/breadcrumb',
    title: 'Breadcrumb',
    builder: (_) => const BreadcrumbPage(),
    keywords: ['DsBreadcrumb', 'path', 'hierarchy'],
    summary: 'Shows where a page sits and leads back up.',
  ),
  SitePage(
    path: '/components/pane-header',
    title: 'Pane header',
    builder: (_) => const PaneHeaderPage(),
    keywords: ['DsPaneHeader', 'header', 'title bar', 'toolbar'],
    summary: 'The title and actions row at the top of a pane.',
  ),
  SitePage(
    path: '/components/accordion',
    title: 'Accordion',
    builder: (_) => const AccordionPage(),
    keywords: ['DsAccordion', 'collapsible', 'disclosure', 'FAQ'],
    summary: 'Sections that open and close in place.',
  ),
  SitePage(
    path: '/components/scrollbar',
    title: 'Scrollbar',
    builder: (_) => const ScrollbarPage(),
    keywords: ['DsScrollbar', 'DsScrollBehavior', 'scroll', 'thumb'],
    summary: 'Shows where a scrolling area is and drags it.',
  ),
];
