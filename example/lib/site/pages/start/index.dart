import '../../registry.dart';
import 'accessibility_page.dart';
import 'customizing_page.dart';
import 'getting_started_page.dart';
import 'introduction_page.dart';
import 'localization_page.dart';
import 'theming_page.dart';

/// The "Get started" pages, in sidebar order.
final startPages = <SitePage>[
  SitePage(
    path: '/',
    title: 'Introduction',
    builder: (_) => const IntroductionPage(),
    keywords: ['home', 'overview'],
  ),
  SitePage(
    path: '/getting-started',
    title: 'Getting started',
    builder: (_) => const GettingStartedPage(),
    keywords: ['install', 'setup', 'DsApp', 'DsScope'],
  ),
  SitePage(
    path: '/theming',
    title: 'Theming',
    builder: (_) => const ThemingPage(),
    keywords: [
      'DsThemeData',
      'theme',
      'dark mode',
      'seed',
      'adjustColors',
      'tokens',
    ],
    summary: 'Seed, settings, dark mode, hooks and reading tokens.',
  ),
  SitePage(
    path: '/customizing',
    title: 'Customizing components',
    builder: (_) => const CustomizingPage(),
    keywords: ['style', 'component theme', 'DsComponentThemes', 'DsPressable'],
    summary: 'Styles, component themes, state styles and DsPressable.',
  ),
  SitePage(
    path: '/accessibility',
    title: 'Accessibility',
    builder: (_) => const AccessibilityPage(),
    keywords: ['a11y', 'contrast', 'focus', 'screen reader', 'RTL', 'WCAG'],
    summary: 'Contrast, focus, semantics, targets, motion and text size.',
  ),
  SitePage(
    path: '/localization',
    title: 'Localization',
    builder: (_) => const LocalizationPage(),
    keywords: ['l10n', 'i18n', 'language', 'locale', 'RTL', 'sorting'],
    summary: '13 languages, your own strings, dates and sorting.',
  ),
];
