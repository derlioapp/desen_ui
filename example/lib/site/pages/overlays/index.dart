import '../../registry.dart';
import 'dialog_page.dart';
import 'glass_page.dart';
import 'panel_page.dart';
import 'popover_page.dart';
import 'toast_page.dart';
import 'tooltip_page.dart';

/// The "Overlays" pages, in sidebar order.
final overlayPages = <SitePage>[
  SitePage(
    path: '/components/dialog',
    title: 'Dialog',
    builder: (_) => const DialogPage(),
    keywords: [
      'DsDialog',
      'showDsDialog',
      'showDsConfirm',
      'confirm',
      'modal',
      'alert dialog',
    ],
  ),
  SitePage(
    path: '/components/panel',
    title: 'Panel and sheet',
    builder: (_) => const PanelPage(),
    keywords: [
      'DsPanel',
      'showDsPanel',
      'side panel',
      'drawer',
      'bottom sheet',
      'sheet',
    ],
  ),
  SitePage(
    path: '/components/popover',
    title: 'Popover',
    builder: (_) => const PopoverPage(),
    keywords: [
      'DsPopover',
      'DsOverlayController',
      'popup',
      'layer behavior',
      'placement',
      'flip',
    ],
  ),
  SitePage(
    path: '/components/tooltip',
    title: 'Tooltip',
    builder: (_) => const TooltipPage(),
    keywords: ['DsTooltip', 'hint', 'shortcut'],
  ),
  SitePage(
    path: '/components/toast',
    title: 'Toast',
    builder: (_) => const ToastPage(),
    keywords: ['DsToast', 'showDsToast', 'snackbar', 'notification', 'undo'],
  ),
  SitePage(
    path: '/guides/glass',
    title: 'Layers and glass',
    builder: (_) => const GlassPage(),
    keywords: [
      'glass',
      'frosted',
      'blur',
      'backdropFilter',
      'ImageFilter',
      'DsSurface',
      'translucent',
    ],
  ),
];
