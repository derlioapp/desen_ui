import '../../registry.dart';
import 'alert_page.dart';
import 'progress_page.dart';
import 'skeleton_page.dart';
import 'spinner_page.dart';

/// The "Feedback" pages, in sidebar order.
final feedbackPages = <SitePage>[
  SitePage(
    path: '/components/alert',
    title: 'Alert',
    builder: (_) => const AlertPage(),
    keywords: ['DsAlert', 'banner', 'callout', 'message', 'notice'],
  ),
  SitePage(
    path: '/components/progress',
    title: 'Progress',
    builder: (_) => const ProgressPage(),
    keywords: ['DsProgressBar', 'DsProgressRing', 'progress bar', 'meter'],
  ),
  SitePage(
    path: '/components/spinner',
    title: 'Spinner',
    builder: (_) => const SpinnerPage(),
    keywords: ['DsSpinner', 'loading', 'activity indicator'],
  ),
  SitePage(
    path: '/components/skeleton',
    title: 'Skeleton',
    builder: (_) => const SkeletonPage(),
    keywords: ['DsSkeleton', 'DsShimmer', 'placeholder', 'loading'],
  ),
];
