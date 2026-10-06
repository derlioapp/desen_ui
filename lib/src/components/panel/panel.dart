import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';

import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../overlay/modal_route.dart';
import '../../overlay/plain_text.dart';
import '../../painting/decoration.dart';
import '../../painting/surface.dart';
import '../../theme/radii.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_theme.dart';
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

/// The body of a side panel or bottom sheet: a title with a close button,
/// content that scrolls when long, and an optional footer. Show it with
/// [showDsPanel].
class DsPanel extends StatelessWidget {
  /// Creates a panel body.
  const DsPanel({
    super.key,
    required this.title,
    required this.child,
    this.footer,
    this.showClose,
    this.semanticLabel,
    this.style,
  });

  /// The panel's name, shown in the header. When it is a [Text], its text
  /// also names the panel for screen readers.
  final Widget title;

  /// The content; scrolls when it does not fit.
  final Widget child;

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
    return Semantics(
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
        child: Column(
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
                  DsButton.icon(
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
              ],
            ),
            Flexible(
              fit: bottom ? FlexFit.loose : FlexFit.tight,
              child: SingleChildScrollView(child: child),
            ),
            ?footer,
          ],
        ),
      ),
    );
  }
}

/// Positions the panel for its presentation and handles the bottom
/// sheet's drag to dismiss.
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
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsPanelStyle.resolveLayers([
      DsPanel.defaultStyle(t),
      DsPanelTheme.of(context).style,
    ], const {});
    final media = MediaQuery.of(context);
    // Clear of the system bars and the on-screen keyboard.
    final margin =
        (s.margin ?? EdgeInsets.zero).resolve(Directionality.of(context)) +
        media.padding +
        EdgeInsets.only(bottom: media.viewInsets.bottom);
    final surface = DsSurface(
      decoration: DsBoxDecoration(
        color: s.background,
        borderRadius: s.borderRadius ?? BorderRadius.zero,
        shadows: s.shadows ?? const [],
      ),
      backdropFilter: s.backdropFilter,
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
          child: SizedBox(
            width: s.width!,
            height: double.infinity,
            child: surface,
          ),
        ),
      );
    }
    return Padding(
      padding: margin,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: s.sheetMaxWidth!,
            maxHeight: media.size.height * .9,
          ),
          // Drag down to dismiss: past a third of the sheet's height, or
          // flicked. A sheet that cannot be dismissed does not drag.
          child: GestureDetector(
            onVerticalDragUpdate: widget.dismissible
                ? (d) => setState(
                    () => _drag = (_drag + d.delta.dy).clamp(0, 9999),
                  )
                : null,
            onVerticalDragEnd: widget.dismissible
                ? (d) {
                    // ds-raw: a divisor guard, not a size
                    final height = _sheet.currentContext?.size?.height ?? 1;
                    if (_drag > height / 3 || (d.primaryVelocity ?? 0) > 700) {
                      Navigator.of(context).maybePop();
                    } else {
                      setState(() => _drag = 0);
                    }
                  }
                : null,
            child: Transform.translate(
              offset: Offset(0, _drag),
              child: KeyedSubtree(key: _sheet, child: surface),
            ),
          ),
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
/// [scrim] set to [DsScrim.clear] leaves the page at full contrast, for a
/// live preview: a short bottom sheet of settings whose effect shows on
/// the page above it. A tap on the page still closes the panel.
Future<T?> showDsPanel<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  DsPanelPresentation presentation = DsPanelPresentation.auto,
  bool dismissible = true,
  DsScrim scrim = DsScrim.dim,
  bool useRootNavigator = true,
}) {
  final bottom = switch (presentation) {
    DsPanelPresentation.bottom => true,
    DsPanelPresentation.side => false,
    DsPanelPresentation.auto =>
      MediaQuery.sizeOf(context).width < kDsPanelBreakpoint,
  };
  return showDsModal<T>(
    context: context,
    placement: bottom ? DsModalPlacement.bottom : DsModalPlacement.end,
    dismissible: dismissible,
    scrim: scrim,
    useRootNavigator: useRootNavigator,
    builder: (context) => _PanelFrame(
      bottom: bottom,
      dismissible: dismissible,
      child: Builder(builder: builder),
    ),
  );
}
