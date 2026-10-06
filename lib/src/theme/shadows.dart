import 'package:flutter/foundation.dart';

import '../painting/shadow.dart';

/// The shadow stacks of a Desen theme.
///
/// Desen has three elevation tiers: surfaces ([surface]), controls
/// ([control]) and overlays ([overlay]), named like the matching
/// `DsColors` and `DsRadii` roles. The remaining stacks are
/// component-specific edges that still come from the seed color.
@immutable
class DsShadows {
  /// Creates a shadow set. Themes generate one from their colors
  /// (`DsThemeData(seed: …).shadows`).
  ///
  /// Building one by hand is meant for tests and tools. It is not covered
  /// by the compatibility promise: later versions may add stacks. To
  /// customize shadows, use `DsThemeData(adjustShadows: …)` with
  /// [copyWith].
  const DsShadows({
    required this.surface,
    required this.surfaceRaised,
    required this.control,
    required this.controlLift,
    required this.fieldError,
    required this.accent,
    required this.danger,
    required this.overlay,
    required this.sidebarEdge,
    required this.channel,
    required this.channelThumb,
    required this.knob,
    required this.knobOn,
    required this.tooltip,
    required this.focusOffset,
    List<DsShadow>? focusTight,
    // A private field cannot be a named parameter; null derives it.
    // ignore: prefer_initializing_formals
  }) : _focusTight = focusTight;

  /// Surface tier: cards, list groups, tables. A hairline ring.
  final List<DsShadow> surface;

  /// [surface] lifted: an interactive card while hovered.
  final List<DsShadow> surfaceRaised;

  /// Control tier: raised controls such as secondary buttons.
  /// A 1px `borderControl` ring followed by [controlLift].
  final List<DsShadow> control;

  /// [control] without its edge ring: the lift (and, in dark mode, the top
  /// highlight). For components that draw their edge separately.
  final List<DsShadow> controlLift;

  /// A field's edge in the error state. Its color draws the error edge of
  /// text fields, selects and selection controls.
  final List<DsShadow> fieldError;

  /// Accent-filled (primary) button, drawn over [DsColors.accent]. Flat:
  /// empty, except an inner hairline in the dark label color under a bright
  /// accent (when [DsColors.accentEdge] is set), which would otherwise melt
  /// into a light card. Add a lift or glow here through `adjustShadows` if
  /// a design wants one.
  final List<DsShadow> accent;

  /// Filled destructive button. Flat: empty by default; its fill stands
  /// on its own in both modes.
  final List<DsShadow> danger;

  /// Overlay tier: menus, popovers, toasts, dialogs, toolbars.
  final List<DsShadow> overlay;

  /// The hairline on the trailing edge of a sidebar.
  final List<DsShadow> sidebarEdge;

  /// Inner outline of channels and tracks: segmented control, stepper,
  /// slider, progress bar. Empty by default at every contrast level (high
  /// contrast deepens the channel's fill instead of outlining it).
  final List<DsShadow> channel;

  /// The raised piece in a channel: the selected segment of a soft
  /// segmented control, stepper buttons.
  final List<DsShadow> channelThumb;

  /// Switch knob and slider thumb over a neutral track.
  final List<DsShadow> knob;

  /// Switch knob over the on track ([DsColors.accent]). The same as [knob],
  /// except under a bright accent (a light brand with a dark [onAccent]):
  /// then its edge is a 1px dark line that stands 3:1 off the accent, since
  /// the white knob itself cannot.
  final List<DsShadow> knobOn;

  /// Tooltip: a short, soft drop under a small dark surface.
  final List<DsShadow> tooltip;

  /// Keyboard focus ring for buttons and accent-filled controls (checkbox,
  /// radio, switch): a solid 2px `focus` outline on a 2px transparent gap.
  final List<DsShadow> focusOffset;

  /// Keyboard focus ring for bordered, unfilled controls (secondary
  /// button, unselected chip): it takes the place of their 1px border
  /// instead of circling it, so focus reads as one line hugging the
  /// control. By default [focusOffset] with each outline moved onto the
  /// box edge (`gap` minus half its width): a 2px `focus` line centered on
  /// the edge, which covers a 1px border inside or outside the box.
  /// Components draw it above their fill.
  List<DsShadow> get focusTight =>
      _focusTight ??
      [
        for (final s in focusOffset)
          s.isOutline ? s.copyWith(gap: -s.spread / 2) : s,
      ];
  final List<DsShadow>? _focusTight;

  /// Returns a copy with the given stacks replaced.
  DsShadows copyWith({
    List<DsShadow>? surface,
    List<DsShadow>? surfaceRaised,
    List<DsShadow>? control,
    List<DsShadow>? controlLift,
    List<DsShadow>? fieldError,
    List<DsShadow>? accent,
    List<DsShadow>? danger,
    List<DsShadow>? overlay,
    List<DsShadow>? sidebarEdge,
    List<DsShadow>? channel,
    List<DsShadow>? channelThumb,
    List<DsShadow>? knob,
    List<DsShadow>? knobOn,
    List<DsShadow>? tooltip,
    List<DsShadow>? focusOffset,
    List<DsShadow>? focusTight,
  }) => DsShadows(
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    control: control ?? this.control,
    controlLift: controlLift ?? this.controlLift,
    fieldError: fieldError ?? this.fieldError,
    accent: accent ?? this.accent,
    danger: danger ?? this.danger,
    overlay: overlay ?? this.overlay,
    sidebarEdge: sidebarEdge ?? this.sidebarEdge,
    channel: channel ?? this.channel,
    channelThumb: channelThumb ?? this.channelThumb,
    knob: knob ?? this.knob,
    knobOn: knobOn ?? this.knobOn,
    tooltip: tooltip ?? this.tooltip,
    focusOffset: focusOffset ?? this.focusOffset,
    // Derived from focusOffset unless set, so a new focusOffset carries over.
    focusTight: focusTight ?? _focusTight,
  );

  /// Linearly interpolates between two shadow sets.
  static DsShadows lerp(DsShadows a, DsShadows b, double t) {
    if (identical(a, b)) return a;
    List<DsShadow> l(List<DsShadow> x, List<DsShadow> y) =>
        DsShadow.lerpList(x, y, t);
    return DsShadows(
      surface: l(a.surface, b.surface),
      surfaceRaised: l(a.surfaceRaised, b.surfaceRaised),
      control: l(a.control, b.control),
      controlLift: l(a.controlLift, b.controlLift),
      fieldError: l(a.fieldError, b.fieldError),
      accent: l(a.accent, b.accent),
      danger: l(a.danger, b.danger),
      overlay: l(a.overlay, b.overlay),
      sidebarEdge: l(a.sidebarEdge, b.sidebarEdge),
      channel: l(a.channel, b.channel),
      channelThumb: l(a.channelThumb, b.channelThumb),
      knob: l(a.knob, b.knob),
      knobOn: l(a.knobOn, b.knobOn),
      tooltip: l(a.tooltip, b.tooltip),
      focusOffset: l(a.focusOffset, b.focusOffset),
      focusTight: a._focusTight == null && b._focusTight == null
          ? null
          : l(a.focusTight, b.focusTight),
    );
  }

  List<List<DsShadow>> get _all => [
    surface, surfaceRaised, control, controlLift, fieldError, //
    accent,
    danger,
    overlay,
    sidebarEdge,
    channel,
    channelThumb,
    knob,
    knobOn, //
    tooltip, focusOffset, focusTight,
  ];

  @override
  bool operator ==(Object other) {
    if (other is! DsShadows) return false;
    final a = _all, b = other._all;
    for (var i = 0; i < a.length; i++) {
      if (!listEquals(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_all.map(Object.hashAll));
}
