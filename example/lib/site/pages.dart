import 'pages/actions/index.dart';
import 'pages/controls/index.dart';
import 'pages/data/index.dart';
import 'pages/examples/index.dart';
import 'pages/feedback/index.dart';
import 'pages/foundations/index.dart';
import 'pages/inputs/index.dart';
import 'pages/navigation/index.dart';
import 'pages/overlays/index.dart';
import 'pages/start/index.dart';
import 'registry.dart';

/// Every page of the site, grouped as in the sidebar. Each group lists its
/// pages in its own `pages/<group>/index.dart`.
final siteGroups = [
  SiteGroup('Get started', startPages),
  SiteGroup('Foundations', foundationPages),
  SiteGroup('Actions', actionPages),
  SiteGroup('Inputs', inputPages),
  SiteGroup('Selection controls', controlPages),
  SiteGroup('Navigation', navigationPages),
  SiteGroup('Data display', dataPages),
  SiteGroup('Feedback', feedbackPages),
  SiteGroup('Overlays', overlayPages),
  SiteGroup('Examples', examplePages),
].where((g) => g.pages.isNotEmpty).toList();
