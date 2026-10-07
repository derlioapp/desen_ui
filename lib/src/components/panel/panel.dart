import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';

import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../overlay/modal_route.dart';
import '../../overlay/plain_text.dart';
import '../../overlay/scroll_keys.dart';
import '../../painting/decoration.dart';
import '../../painting/surface.dart';
import '../../theme/radii.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_theme.dart';
import '../../foundation/component_theme.dart';
import 'panel_style.dart';

/// How [showDsPanel] presents a panel.
enum DsPanelPresentation {
  /// A side panel on wide screens, a bottom sheet on narrow ones.
  auto,

  /// From the end edge (right in LTR).
  side,

  /// From the bottom, with a drag handle.
  bottom,
}

/// Below this width [DsPanelPresentation.auto] shows a bottom sheet.
const double kDsPanelBreakpoint = 640;

/// A side panel or bottom sheet: a title with a close button, content that
/// scrolls when long, and an optional footer. Show it with [showDsPanel],
/// which places it; the panel draws its own surface there, sized by its
/// style ([DsPanelStyle.width], [DsPanelStyle.sheetMaxWidth]).
///
/// With focus on the close button, the footer or another control in the
/// panel, Page Up, Page Down, Arrow Up, Arrow Down, Home and End scroll
/// long content; a focused text field keeps these keys.
class DsPanel extends StatelessWidget {
  /// Creates a panel.
  const DsPanel({
    super.key,
    required this.title,
    required this.child,
    this.footer,
    this.showClose,
    this.scrollable = true,
    this.semanticLabel,
    this.style,
  });

  /// The panel's name, shown in the header. When it is a [Text], its text
  /// also names the panel for screen readers.
  final Widget title;

  /// The content; scrolls when it does not fit, unless [scrollable] is
  /// false.
  final Widget child;

  /// Whether the panel scrolls [child] when it does not fit. Set it to false
  /// for content that scrolls itself, such as a `ListView` built lazily:
  /// the child then gets the room left between the header and the footer
  /// as a bounded height (all of it in a side panel; up to it in a bottom
  /// sheet, which a `ListView` fills). The keys that scroll long content
  /// are then the child's own.
  final bool scrollable;

  /// Actions along the bottom, e.g. a full-width primary button.
  final Widget? footer;

  /// Shows a close button in the header. Defaults to whether the panel
  /// can be dismissed (`showDsPanel(dismissible:)`).
  final bool? showClose;

  /// Names the panel for screen readers. Defaults to the [title]'s text,
  /// then to the localized "Dialog".
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsPanelStyle? style;

  /// Desen's default panel style under [theme].
  static DsPanelStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsPanelStyle(
      background: k.overlay,
      shadows: theme.shadows.overlay,
      borderRadius: BorderRadius.circular(theme.radii.overlay),
      padding: const EdgeInsets.all(DsSpace.s20),
      margin: const EdgeInsets.all(DsSpace.s8),
      width: 400,
      gap: DsSpace.s16,
      titleStyle: theme.typography.heading.copyWith(color: k.text),
      grabberColor: k.channelStrong,
      grabberSize: const Size(36, 4),
      sheetMaxWidth: 560,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsPanelStyle.resolveLayers([
      defaultStyle(t),
      DsPanelTheme.of(context).style,
      style,
    ], const {});
    final kind = _PanelKind.maybeOf(context);
    final bottom = kind?.bottom ?? false;
    final l10n = DsLocalizations.of(context);
    final body = Semantics(
      container: true,
      role: SemanticsRole.dialog,
      scopesRoute: true,
      namesRoute: true,
      label: semanticLabel ?? plainTextOf(title) ?? l10n.dialog,
      explicitChildNodes: true,
      child: Padding(
        padding: s.padding ?? EdgeInsets.zero,
        // A side panel is full height: the body fills it and the footer
        // sits at the bottom. A bottom sheet hugs its content.
        child: LayerScrollKeys(
          builder: (context, controller) => Column(
            mainAxisSize: bottom ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: s.gap ?? DsSpace.s16,
            children: [
              if (bottom)
                ExcludeSemantics(
                  child: Center(
                    child: Container(
                      width: s.grabberSize!.width,
                      height: s.grabberSize!.height,
                      decoration: BoxDecoration(
                        color: s.grabberColor,
                        borderRadius: BorderRadius.circular(DsRadii.pill),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: DefaultTextStyle.merge(
                        style: s.titleStyle,
                        child: title,
                      ),
                    ),
                  ),
                  if (showClose ?? kind?.dismissible ?? true)
                    DsComponentThemeReset<DsButtonThemeData>(
                      child: DsButton.icon(
                        variant: DsButtonVariant.ghost,
                        size: DsSize.sm,
                        icon: const DsIcon(DsIcons.x),
                        semanticLabel: l10n.close,
                        // A close button shown on a panel that cannot be
                        // dismissed (showClose: true) is the panel's own
                        // action: it closes even though back does not.
                        onPressed: () => kind?.dismissible == false
                            ? Navigator.of(context).pop()
                            : Navigator.of(context).maybePop(),
                      ),
                    ),
                ],
              ),
              Flexible(
                fit: bottom ? FlexFit.loose : FlexFit.tight,
                child: scrollable
                    ? SingleChildScrollView(
                        controller: controller,
                        child: child,
                      )
                    : child,
              ),
              ?footer,
            ],
          ),
        ),
      ),
    );
    // Outside showDsPanel (a preview) the panel is only its content.
    if (kind == null) return body;
    final surface = DsSurface(
      decoration: DsBoxDecoration(
        color: s.background,
        borderRadius: s.borderRadius ?? BorderRadius.zero,
        shadows: s.shadows ?? const [],
      ),
      backdropFilter: s.backdropFilter,
      child: body,
    );
    return Padding(
      padding: s.margin ?? EdgeInsets.zero,
      // One box for both, so that the content keeps its state when the
      // window's size turns one presentation into the other.
      child: ConstrainedBox(
        constraints: bottom
            ? BoxConstraints(
                maxWidth: s.sheetMaxWidth!,
                maxHeight: MediaQuery.sizeOf(context).height * .9,
              )
            : BoxConstraints.tightFor(width: s.width),
        child: surface,
      ),
    );
  }
}

/// Positions the panel for its presentation, clear of the system bars and
/// the on-screen keyboard, and handles the bottom sheet's drag to dismiss.
/// The panel draws its own surface, so its style sizes it.
class _PanelFrame extends StatefulWidget {
  const _PanelFrame({
    required this.bottom,
    required this.dismissible,
    required this.child,
  });

  final bool bottom;
  final bool dismissible;
  final Widget child;

  @override
  State<_PanelFrame> createState() => _PanelFrameState();
}

class _PanelKind extends InheritedWidget {
  const _PanelKind({
    required this.bottom,
    required this.dismissible,
    required super.child,
  });

  final bool bottom;
  final bool dismissible;

  static _PanelKind? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PanelKind>();

  @override
  bool updateShouldNotify(_PanelKind oldWidget) =>
      oldWidget.bottom != bottom || oldWidget.dismissible != dismissible;
}

class _PanelFrameState extends State<_PanelFrame> {
  final _sheet = GlobalKey();
  double _drag = 0;

  @override
  void didUpdateWidget(_PanelFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bottom != widget.bottom) _drag = 0;
  }

  /// A drag past the threshold: asks the route to close. When it refuses
  /// (a [PopScope] that cannot pop, e.g. to ask about unsaved changes),
  /// the sheet goes back in place.
  Future<void> _dismiss() async {
    final route = ModalRoute.of(context);
    await Navigator.of(context).maybePop();
    if (!mounted) return;
    final closing = switch (route?.animation?.status) {
      AnimationStatus.reverse || AnimationStatus.dismissed => true,
      _ => false,
    };
    if (!closing) setState(() => _drag = 0);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Clear of the system bars and the on-screen keyboard.
    final margin =
        media.padding + EdgeInsets.only(bottom: media.viewInsets.bottom);
    // Keyed, so that the panel keeps its state (and focus) when the
    // window's size turns one presentation into the other.
    final panel = KeyedSubtree(
      key: _sheet,
      child: _PanelKind(
        bottom: widget.bottom,
        dismissible: widget.dismissible,
        child: widget.child,
      ),
    );
    if (!widget.bottom) {
      return Padding(
        padding: margin,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(height: double.infinity, child: panel),
        ),
      );
    }
    return Padding(
      padding: margin,
      child: Align(
        alignment: Alignment.bottomCenter,
        // Drag down to dismiss: past a third of the sheet's height, or
        // flicked. A sheet that cannot be dismissed does not drag. Screen
        // readers get no scroll action from the drag, which would close the
        // sheet: the close button, the scrim and Escape do that.
        child: GestureDetector(
          excludeFromSemantics: true,
          onVerticalDragUpdate: widget.dismissible
              ? (d) =>
                    setState(() => _drag = (_drag + d.delta.dy).clamp(0, 9999))
              : null,
          onVerticalDragEnd: widget.dismissible
              ? (d) {
                  // ds-raw: a divisor guard, not a size
                  final height = _sheet.currentContext?.size?.height ?? 1;
                  if (_drag > height / 3 || (d.primaryVelocity ?? 0) > 700) {
                    _dismiss();
                  } else {
                    setState(() => _drag = 0);
                  }
                }
              : null,
          child: Transform.translate(offset: Offset(0, _drag), child: panel),
        ),
      ),
    );
  }
}

/// Shows a panel built by [builder] (usually a [DsPanel]): from the end
/// edge on wide screens and from the bottom on narrow ones (below
/// [kDsPanelBreakpoint]), unless [presentation] says otherwise. Escape, the
/// close button, a tap on the scrim, system back (the Android back button
/// or gesture) and dragging a bottom sheet down close it when
/// [dismissible]; otherwise none of them does and the close button is
/// hidden, so the panel's own actions must close it.
///
/// The [DsPanel] draws the panel's surface and takes its size from its
/// style; other content is placed as it is and draws its own.
///
/// With [DsPanelPresentation.auto] the choice follows the window while the
/// panel is open: resizing the window or turning a tablet across the
/// breakpoint turns a side panel into a bottom sheet and back.
///
/// [scrim] set to [DsScrim.clear] leaves the page at full contrast, for a
/// live preview: a short bottom sheet of settings whose effect shows on
/// the page above it. A tap on the page still closes the panel.
///
/// [routeSettings] names the panel's route for navigator observers and
/// analytics, and can carry arguments.
Future<T?> showDsPanel<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  DsPanelPresentation presentation = DsPanelPresentation.auto,
  bool dismissible = true,
  DsScrim scrim = DsScrim.dim,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  // Decided from the modal's own context each time it builds, so that it
  // follows the window's current size.
  bool bottomIn(BuildContext context) => switch (presentation) {
    DsPanelPresentation.bottom => true,
    DsPanelPresentation.side => false,
    DsPanelPresentation.auto =>
      MediaQuery.sizeOf(context).width < kDsPanelBreakpoint,
  };
  return pushDsModal<T>(
    context: context,
    placementOf: (context) =>
        bottomIn(context) ? DsModalPlacement.bottom : DsModalPlacement.end,
    dismissible: dismissible,
    scrim: scrim,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    builder: (context) => _PanelFrame(
      bottom: bottomIn(context),
      dismissible: dismissible,
      child: Builder(builder: builder),
    ),
  );
}
