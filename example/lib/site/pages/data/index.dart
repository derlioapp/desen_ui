import '../../registry.dart';
import 'avatar_page.dart';
import 'badge_page.dart';
import 'calendar_page.dart';
import 'card_page.dart';
import 'divider_page.dart';
import 'empty_state_page.dart';
import 'image_page.dart';
import 'list_page.dart';
import 'reorderable_list_page.dart';
import 'table_page.dart';

/// The "Data display" pages, in sidebar order.
final dataPages = <SitePage>[
  SitePage(
    path: '/components/table',
    title: 'Table',
    builder: (_) => const TablePage(),
    keywords: ['DsTable', 'DsTableColumn', 'data table', 'grid', 'sort'],
  ),
  SitePage(
    path: '/components/list',
    title: 'List',
    builder: (_) => const ListPage(),
    keywords: ['DsListSection', 'DsListRow', 'settings', 'rows'],
  ),
  SitePage(
    path: '/components/reorderable-list',
    title: 'Reorderable list',
    builder: (_) => const ReorderableListPage(),
    keywords: ['DsReorderableList', 'drag', 'reorder', 'sort', 'favorites'],
  ),
  SitePage(
    path: '/components/card',
    title: 'Card',
    builder: (_) => const CardPage(),
    keywords: ['DsCard', 'surface', 'panel', 'tile'],
  ),
  SitePage(
    path: '/components/divider',
    title: 'Divider',
    builder: (_) => const DividerPage(),
    keywords: ['DsDivider', 'separator', 'rule', 'hairline', 'line'],
  ),
  SitePage(
    path: '/components/badge',
    title: 'Badge',
    builder: (_) => const BadgePage(),
    keywords: [
      'DsBadge',
      'DsCount',
      'DsStatusDot',
      'DsAnchoredBadge',
      'tag',
      'pill',
      'status',
      'notification count',
    ],
  ),
  SitePage(
    path: '/components/avatar',
    title: 'Avatar',
    builder: (_) => const AvatarPage(),
    keywords: ['DsAvatar', 'DsAvatarGroup', 'profile', 'initials', 'user'],
  ),
  SitePage(
    path: '/components/image',
    title: 'Image',
    builder: (_) => const ImagePage(),
    keywords: ['DsImage', 'picture', 'photo', 'thumbnail', 'network image'],
  ),
  SitePage(
    path: '/components/calendar',
    title: 'Calendar',
    builder: (_) => const CalendarPage(),
    keywords: [
      'DsCalendar',
      'DsRangeCalendar',
      'DsDateRange',
      'date',
      'range',
      'month',
    ],
  ),
  SitePage(
    path: '/components/empty-state',
    title: 'Empty state',
    builder: (_) => const EmptyStatePage(),
    keywords: ['DsEmptyState', 'no results', 'blank', 'zero state'],
  ),
];
