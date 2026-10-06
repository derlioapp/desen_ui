import 'package:flutter/widgets.dart';

import '../../overlay/anchored_overlay.dart';
import '../../overlay/placement.dart';
import '../../painting/decoration.dart';
import '../../painting/surface.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'popover_style.dart';

/// A floating panel hung from its trigger; it can hold any content, form
/// controls included.
///
/// Built on [DsAnchoredOverlay]: it flips and shifts to stay in the window,
/// follows the trigger while scrolling, closes on Escape or a tap outside,
/// and moves focus in on open and back on close. It also closes when the
/// trigger leaves the window, and on system back before the page.
///
/// **Trigger.** [builder] builds it with the controller that opens and
/// closes the popover; the popover makes and disposes that controller
/// itself unless you pass [controller] (to open it from elsewhere too). A
/// plain [child] trigger needs a [controller] to toggle.
///
/// A `DsButton` trigger is announced as expanded or collapsed with the
/// popover (WAI-ARIA `aria-expanded`) by itself, as in the example below.
/// Another kind of trigger announces it with
/// `Semantics(expanded: controller.isOpen)` around its own control,
/// rebuilt by a `ListenableBuilder` on the controller.
///
/// ```dart
/// DsPopover(
///   align: DsAlign.end,
///   semanticLabel: 'Paylaş',
///   contentBuilder: (context) => const ShareForm(),
///   builder: (context, controller, _) => DsButton(
///     onPressed: controller.toggle,
///     child: const Text('Paylaş'),
///   ),
/// )
/// ```
class DsPopover extends StatefulWidget {
  /// Creates a popover. Give [builder], or [child] and [controller].
  const DsPopover({
    super.key,
    this.controller,
    required this.contentBuilder,
    this.builder,
    this.child,
    this.side = DsSide.bottom,
    this.align = DsAlign.start,
    this.semanticLabel,
    this.style,
  }) : assert(
         builder != null || (child != null && controller != null),
         'DsPopover needs a builder, or a child and a controller',
       );

  /// Opens and closes the popover; one is made when null.
  final DsOverlayController? controller;

  /// Builds the panel's content.
  final WidgetBuilder contentBuilder;

  /// Builds the trigger with the popover's controller; see the class docs.
  final DsOverlayTriggerBuilder? builder;

  /// The trigger, or with [builder], a part of it passed to [builder].
  final Widget? child;

  /// Preferred side of the trigger.
  final DsSide side;

  /// Preferred alignment along the trigger.
  final DsAlign align;

  /// Names the panel for screen readers.
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsPopoverStyle? style;

  /// Desen's default popover style under [theme].
  static DsPopoverStyle defaultStyle(DsThemeData theme) => DsPopoverStyle(
    background: theme.colors.overlay,
    shadows: theme.shadows.overlay,
    borderRadius: BorderRadius.circular(theme.radii.overlay),
    padding: const EdgeInsets.all(DsSpace.s16),
    maxWidth: 360,
  );

  @override
  State<DsPopover> createState() => _DsPopoverState();
}

class _DsPopoverState extends State<DsPopover> {
  DsOverlayController? _own;
  DsOverlayController get _controller =>
      widget.controller ?? (_own ??= DsOverlayController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DsAnchoredOverlay(
    controller: _controller,
    side: widget.side,
    align: widget.align,
    expandsTrigger: true,
    overlayBuilder: (context) {
      final t = dsThemeOf(context);
      final s = DsPopoverStyle.resolveLayers([
        DsPopover.defaultStyle(t),
        DsPopoverTheme.of(context).style,
        widget.style,
      ], const {});
      return Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: widget.semanticLabel,
        child: DsSurface(
          width: s.width,
          constraints: BoxConstraints(maxWidth: s.maxWidth ?? double.infinity),
          padding: s.padding,
          decoration: DsBoxDecoration(
            color: s.background,
            borderRadius: s.borderRadius ?? BorderRadius.zero,
            shadows: s.shadows ?? const [],
          ),
          backdropFilter: s.backdropFilter,
          // The layer sits in the overlay, away from the trigger's text
          // style: start from the theme's body text.
          child: DefaultTextStyle(
            style: t.typography.body.copyWith(color: t.colors.text),
            child: IconTheme(
              data: IconThemeData(
                color: t.colors.text,
                size: t.sizes.iconSize(DsSize.md),
              ),
              child: Builder(builder: widget.contentBuilder),
            ),
          ),
        ),
      );
    },
    child: switch (widget.builder) {
      final build? => Builder(
        builder: (context) => build(context, _controller, widget.child),
      ),
      null => widget.child!,
    },
  );
}
