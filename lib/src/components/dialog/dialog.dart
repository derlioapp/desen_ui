import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../icons/icon.dart';
import '../../l10n/localizations.dart';
import '../../overlay/modal_route.dart';
import '../../overlay/plain_text.dart';
import '../../painting/decoration.dart';
import '../../painting/surface.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_theme.dart';
import 'dialog_style.dart';

/// A dialog panel over the scrim: optional tone disk, title, description
/// and actions.
///
/// It takes its preferred width ([DsDialogStyle.width]) and shrinks on
/// narrow windows. When the window is short or the text large, the icon,
/// title and description scroll while the actions stay in view. Show it with [showDsDialog]; for a yes/no
/// question use [showDsConfirm].
class DsDialog extends StatelessWidget {
  /// Creates a dialog panel.
  const DsDialog({
    super.key,
    required this.title,
    this.icon,
    this.description,
    this.actions = const [],
    this.destructive = false,
    this.alert = false,
    this.semanticLabel,
    this.style,
  });

  /// The question or heading. When it is a [Text], its text is also the
  /// dialog's name for screen readers.
  final Widget title;

  /// Shown in a tone disk, usually a [DsIcon].
  final Widget? icon;

  /// What happens, in a sentence or two.
  final Widget? description;

  /// Buttons, laid out side by side with equal widths, or stacked at full
  /// width when one would not fit its share (narrow windows, long labels,
  /// large text). Put the safe choice first: with no `autofocus: true`
  /// inside the dialog, the first control takes focus when it opens.
  final List<Widget> actions;

  /// Uses the danger tone for the disk.
  final bool destructive;

  /// Announces the dialog as an alert dialog: it needs an answer before
  /// anything else (a confirmation).
  final bool alert;

  /// Names the dialog for screen readers. Defaults to the [title]'s text,
  /// then to the localized "Dialog".
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsDialogStyle? style;

  /// Desen's default dialog style under [theme].
  static DsDialogStyle defaultStyle(
    DsThemeData theme, {
    bool destructive = false,
  }) {
    final k = theme.colors;
    return DsDialogStyle(
      background: k.overlay,
      shadows: theme.shadows.overlay,
      borderRadius: BorderRadius.circular(theme.radii.overlay),
      padding: const EdgeInsets.all(DsSpace.s20),
      width: 340,
      gap: DsSpace.s16,
      iconBoxSize: theme.sizes.md,
      // A deep red box turns maroon in dark mode: there the box is neutral
      // and the icon carries the red.
      iconBoxColor: destructive
          ? (theme.isDark ? k.control : k.danger.tint)
          : k.accentTint,
      // No icon box radius: its corners follow the resolved box size.
      iconColor: destructive ? k.danger.text : k.accentText,
      iconSize: 20,
      titleStyle: theme.typography.heading.copyWith(color: k.text),
      descriptionStyle: theme.typography.body.copyWith(color: k.textMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsDialogStyle.resolveLayers([
      defaultStyle(t, destructive: destructive),
      DsDialogTheme.of(context).style,
      style,
    ], const {});
    final box = s.iconBoxSize!;
    final gap = s.gap ?? DsSpace.s16;
    // The screen reader name: the title's text unless one is given.
    final name =
        semanticLabel ??
        plainTextOf(title) ??
        DsLocalizations.of(context).dialog;
    return Center(
      child: Padding(
        // Clear of the system bars and the on-screen keyboard.
        padding:
            MediaQuery.paddingOf(context) +
            MediaQuery.viewInsetsOf(context) +
            const EdgeInsets.all(DsSpace.s16),
        child: Semantics(
          container: true,
          role: alert ? SemanticsRole.alertDialog : SemanticsRole.dialog,
          scopesRoute: true,
          namesRoute: true,
          label: name,
          explicitChildNodes: true,
          child: DsSurface(
            width: s.width,
            padding: s.padding,
            decoration: DsBoxDecoration(
              color: s.background,
              borderRadius: s.borderRadius ?? BorderRadius.zero,
              shadows: s.shadows ?? const [],
            ),
            backdropFilter: s.backdropFilter,
            // The text scrolls when the window is short or the text large;
            // the actions stay in view below it.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: gap,
                      children: [
                        if (icon != null)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: ExcludeSemantics(
                              child: Container(
                                width: box,
                                height: box,
                                alignment: Alignment.center,
                                decoration: DsBoxDecoration(
                                  color: s.iconBoxColor,
                                  borderRadius: t.radii.controlCorners(
                                    s.iconBoxRadius,
                                    box,
                                  ),
                                ),
                                child: IconTheme.merge(
                                  data: IconThemeData(
                                    color: s.iconColor,
                                    size: s.iconSize,
                                  ),
                                  child: icon!,
                                ),
                              ),
                            ),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: DsSpace.s8,
                          children: [
                            Semantics(
                              header: true,
                              child: DefaultTextStyle.merge(
                                style: s.titleStyle,
                                child: title,
                              ),
                            ),
                            if (description != null)
                              DefaultTextStyle.merge(
                                style: s.descriptionStyle,
                                child: description!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: DsSpace.s4),
                    child: _DialogActions(
                      gap: DsSpace.s8,
                      direction: Directionality.of(context),
                      children: actions,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays the actions side by side with equal widths, or stacks them at full
/// width when one of them would not fit its share (a narrow window, long
/// labels, large text). The order stays the same, so focus order does too.
class _DialogActions extends MultiChildRenderObjectWidget {
  const _DialogActions({
    required this.gap,
    required this.direction,
    required super.children,
  });

  final double gap;
  final TextDirection direction;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDialogActions(gap, direction);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderDialogActions renderObject,
  ) => renderObject
    ..gap = gap
    ..direction = direction;
}

class _ActionsParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderDialogActions extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ActionsParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ActionsParentData> {
  _RenderDialogActions(this._gap, this._direction);

  TextDirection _direction;
  set direction(TextDirection value) {
    if (_direction == value) return;
    _direction = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ActionsParentData) {
      child.parentData = _ActionsParentData();
    }
  }

  List<RenderBox> get _children {
    final result = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      result.add(child);
      child = childAfter(child);
    }
    return result;
  }

  /// Whether every action fits its equal share of [width].
  bool _fitsInRow(double width) {
    final children = _children;
    if (children.length < 2) return true;
    final share = (width - _gap * (children.length - 1)) / children.length;
    return children.every(
      (c) => c.getMaxIntrinsicWidth(double.infinity) <= share + 0.5,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => _children.fold(
    0,
    (w, c) =>
        w > c.getMinIntrinsicWidth(height) ? w : c.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) {
    final children = _children;
    if (children.isEmpty) return 0;
    final widest = children.fold<double>(0, (w, c) {
      final cw = c.getMaxIntrinsicWidth(height);
      return w > cw ? w : cw;
    });
    return widest * children.length + _gap * (children.length - 1);
  }

  @override
  double computeMinIntrinsicHeight(double width) => _height(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _height(width);

  double _height(double width) {
    final children = _children;
    if (children.isEmpty) return 0;
    if (_fitsInRow(width)) {
      final share = (width - _gap * (children.length - 1)) / children.length;
      return children.fold(0, (h, c) {
        final ch = c.getMaxIntrinsicHeight(share);
        return h > ch ? h : ch;
      });
    }
    return children.fold<double>(
          0,
          (h, c) => h + c.getMaxIntrinsicHeight(width),
        ) +
        _gap * (children.length - 1);
  }

  @override
  void performLayout() {
    final children = _children;
    final width = constraints.maxWidth;
    if (children.isEmpty) {
      size = constraints.smallest;
      return;
    }
    if (_fitsInRow(width)) {
      final share = (width - _gap * (children.length - 1)) / children.length;
      var height = 0.0;
      for (final c in children) {
        c.layout(BoxConstraints.tightFor(width: share), parentUsesSize: true);
        if (c.size.height > height) height = c.size.height;
      }
      final rtl = _direction == TextDirection.rtl;
      var x = 0.0;
      for (final c in children) {
        final dx = rtl ? width - x - share : x;
        (c.parentData! as _ActionsParentData).offset = Offset(
          dx,
          (height - c.size.height) / 2,
        );
        x += share + _gap;
      }
      size = constraints.constrain(Size(width, height));
      return;
    }
    var y = 0.0;
    for (final c in children) {
      c.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      (c.parentData! as _ActionsParentData).offset = Offset(0, y);
      y += c.size.height + _gap;
    }
    size = constraints.constrain(Size(width, y - _gap));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// Shows a dialog built by [builder] over the scrim. Escape, a tap on the
/// scrim and system back (the Android back button or gesture) close it
/// (returning null) when [dismissible]; otherwise none of them does, so
/// the dialog's own actions must close it.
///
/// [scrim] set to [DsScrim.clear] leaves the page at full contrast, e.g.
/// for a dialog whose choices preview on the page behind it; the page
/// still takes no input while the dialog is open.
Future<T?> showDsDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
  DsScrim scrim = DsScrim.dim,
  bool useRootNavigator = true,
}) => showDsModal<T>(
  context: context,
  builder: builder,
  dismissible: dismissible,
  scrim: scrim,
  useRootNavigator: useRootNavigator,
);

/// Asks a yes/no question and returns whether the user confirmed. The safe
/// choice ([cancelLabel], default "Cancel" localized) comes first and has
/// focus; Escape, a tap on the scrim or system back answer no.
///
/// ```dart
/// final delete = await showDsConfirm(
///   context: context,
///   title: 'Projeyi sil?',
///   description: 'Derlio Web ve 48 görev kalıcı olarak silinir.',
///   confirmLabel: 'Sil',
///   destructive: true,
///   icon: const DsIcon(DsIcons.trash),
/// );
/// ```
Future<bool> showDsConfirm({
  required BuildContext context,
  required String title,
  String? description,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  Widget? icon,
  bool useRootNavigator = true,
}) async {
  final l10n = DsLocalizations.of(context);
  final result = await showDsDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (context) => DsDialog(
      alert: true,
      destructive: destructive,
      icon: icon,
      title: Text(title),
      description: description == null ? null : Text(description),
      actions: [
        DsButton(
          variant: DsButtonVariant.secondary,
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel ?? l10n.cancel),
        ),
        DsButton(
          variant: destructive
              ? DsButtonVariant.danger
              : DsButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel ?? l10n.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}
