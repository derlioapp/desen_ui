import '../../registry.dart';
import 'colors_page.dart';
import 'corners_page.dart';
import 'icons_page.dart';
import 'motion_page.dart';
import 'spacing_page.dart';
import 'typography_page.dart';

/// The "Foundations" pages, in sidebar order.
final foundationPages = <SitePage>[
  SitePage(
    path: '/foundations/colors',
    title: 'Colors',
    builder: (_) => const ColorsPage(),
    keywords: ['palette', 'seed', 'OKLCH', 'contrast', 'DsColors', 'brand'],
    summary: 'One seed generates every color role.',
  ),
  SitePage(
    path: '/foundations/typography',
    title: 'Typography',
    builder: (_) => const TypographyPage(),
    keywords: ['type', 'font', 'DsTypography', 'numeric', 'mono', 'text'],
    summary: 'The type scale, tabular numbers and fonts.',
  ),
  SitePage(
    path: '/foundations/spacing',
    title: 'Spacing and sizes',
    builder: (_) => const SpacingPage(),
    keywords: ['DsSpace', 'DsSizes', 'density', 'tap target', 'height'],
    summary: 'The 4px rhythm, control heights and tap areas.',
  ),
  SitePage(
    path: '/foundations/corners',
    title: 'Corners and shadows',
    builder: (_) => const CornersPage(),
    keywords: [
      'radius',
      'DsRadii',
      'DsShadows',
      'elevation',
      'DsBoxDecoration',
      'inset',
    ],
    summary: 'Concentric radii, elevation tiers and inset shadows.',
  ),
  SitePage(
    path: '/foundations/motion',
    title: 'Motion',
    builder: (_) => const MotionPage(),
    keywords: [
      'animation',
      'spring',
      'DsMotion',
      'reduced motion',
      'haptics',
      'vibration',
      'DsHaptics',
    ],
    summary: 'Springs for tone and movement; reduced motion; haptics.',
  ),
  SitePage(
    path: '/foundations/icons',
    title: 'Icons',
    builder: (_) => const IconsPage(),
    keywords: ['DsIcons', 'DsIcon', 'icon set', 'svg', 'Lucide'],
    summary: 'Every built-in icon, and how to use your own.',
  ),
];
