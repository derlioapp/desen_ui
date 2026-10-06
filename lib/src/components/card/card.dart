import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/pressable.dart';
import '../../foundation/color_utils.dart';
import '../../painting/decoration.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../file_upload/dashed_border.dart';
import 'card_style.dart';

/// A content card: surface fill, a hairline edge, the card radius.
///
/// With [onPressed] the whole card is pressable: hovering lifts it
/// (`DsShadows.surfaceRaised`) and keyboard focus draws the focus ring.
///
/// With [dashed] it is an empty slot instead: no fill or shadow, a dashed
/// outline in the theme's form control boundary color (3:1, so the slot
/// stands out) along the card corners. Use it for a place to add something ("Add
/// a widget") or to drop something onto; pressable, it fills and its
/// outline darkens on hover.
///
/// ```dart
/// DsCard(
///   dashed: true,
///   onPressed: addWidget,
///   semanticLabel: 'Add a widget',
///   child: const Center(child: DsIcon(DsIcons.plus)),
/// )
/// ```
class DsCard extends StatefulWidget {
  /// Creates a card.
  const DsCard({
    super.key,
    required this.child,
    this.onPressed,
    this.dashed = false,
    this.style,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The content.
  final Widget child;

  /// Draws the card as an empty slot: a dashed outline instead of the fill,
  /// edge and shadow (see the class docs). Styled by
  /// [DsCardStyle.dashed].
  final bool dashed;

  /// Style laid over the theme and defaults (padding, fill, shadows…).
  final DsCardStyle? style;

  /// Observe or force interaction states (hovered, focused, pressed).
  final WidgetStatesController? statesController;

  /// Desen's default card style under [theme].
  static DsCardStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsCardStyle(
      background: k.surface,
      shadows: theme.shadows.surface,
      borderRadius: BorderRadius.circular(theme.radii.card),
      padding: const EdgeInsets.all(DsSpace.s16),
      focusShadows: theme.focusShadows,
      hovered: DsCardStyle(shadows: theme.shadows.surfaceRaised),
      // An empty slot: the page shows through, the edge is dashed in the
      // form control boundary (3:1), so the slot is seen.
      dashed: DsCardStyle(
        background: const Color(0x00000000),
        shadows: const [],
        borderColor: k.borderField,
        borderWidth: 1.5,
        dashLength: 6,
        dashGap: 4,
        // A pressable slot fills on hover, without the lift of a raised
        // card; the edge steps up to the muted text, so the fill under it
        // never takes it below 3:1.
        hovered: DsCardStyle(background: k.hover, borderColor: k.textMuted),
        pressed: DsCardStyle(background: k.press, borderColor: k.textMuted),
      ),
    );
  }

  /// Makes the card pressable.
  final VoidCallback? onPressed;

  /// Label for screen readers when the card is pressable.
  final String? semanticLabel;

  /// Focus node when the card is pressable; one is created when null.
  final FocusNode? focusNode;

  /// Whether a pressable card takes focus when first built.
  final bool autofocus;

  @override
  State<DsCard> createState() => _DsCardState();
}

class _DsCardState extends State<DsCard> {
  Set<WidgetState>? _lastStates;

  /// Keeps the content's state when [DsCard.onPressed] turns on or off,
  /// which changes the tree around it.
  final _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final layers = [
      DsCard.defaultStyle(t),
      DsCardTheme.of(context).style,
      widget.style,
    ];
    Widget box(Set<WidgetState> states, Duration duration, Widget? child) {
      final s = DsCardStyle.resolveLayers(
        layers,
        states,
        dashed: widget.dashed,
      );
      final radius = s.borderRadius ?? BorderRadius.zero;
      final card = AnimatedContainer(
        duration: duration,
        curve: t.motion.toneCurve,
        padding: s.padding,
        decoration: DsBoxDecoration(
          color: s.background,
          borderRadius: radius,
          shadows: [
            ...?s.shadows,
            if (states.contains(WidgetState.focused)) ...?s.focusShadows,
          ],
        ),
        child: child,
      );
      if (!widget.dashed) return card;
      // The dashes follow the card's corners, inside its edge.
      return TweenAnimationBuilder<Color?>(
        tween: DsColorTween(end: s.borderColor),
        duration: duration,
        curve: t.motion.toneCurve,
        builder: (context, color, child) => DsDashedBorder(
          color: color ?? const Color(0x00000000),
          width: s.borderWidth ?? 0,
          dashLength: s.dashLength ?? 0,
          dashGap: s.dashGap ?? 0,
          borderRadius: radius,
          child: child,
        ),
        child: card,
      );
    }

    final content = KeyedSubtree(key: _contentKey, child: widget.child);
    if (widget.onPressed == null) {
      return box(const {}, Duration.zero, content);
    }
    return DsPressable(
      statesController: widget.statesController,
      onPressed: widget.onPressed,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      semanticLabel: widget.semanticLabel,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsCardStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, states, child) {
        // Animate interaction changes only; follow theme changes directly.
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        return box(
          states,
          animate ? t.motion.toneDuration : Duration.zero,
          child,
        );
      },
      child: content,
    );
  }
}
