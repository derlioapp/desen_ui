import '../../registry.dart';
import 'dashboard_page.dart';
import 'settings_page.dart';
import 'sign_in_page.dart';

/// The "Examples" pages, in sidebar order.
final examplePages = <SitePage>[
  SitePage(
    path: '/examples/dashboard',
    title: 'Dashboard',
    builder: (_) => const DashboardPage(),
    keywords: ['example', 'project management', 'table', 'sidebar', 'app'],
    summary: 'A project tracker with a sidebar, task table and dialogs.',
  ),
  SitePage(
    path: '/examples/settings',
    title: 'Settings',
    builder: (_) => const SettingsPage(),
    keywords: ['example', 'preferences', 'account', 'profile', 'form'],
    summary: 'Account and workspace settings with forms and a danger zone.',
  ),
  SitePage(
    path: '/examples/sign-in',
    title: 'Sign in',
    builder: (_) => const SignInPage(),
    keywords: ['example', 'login', 'sign up', 'register', 'password', 'auth'],
    summary: 'Sign in, sign up and password reset with validation.',
  ),
];
