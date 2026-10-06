import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Corner style, an end-user setting.
///
/// Every style follows the same three rules (see [DsRadii]); the style only
/// picks the numbers.
enum DsCornerStyle {
  /// Nearly square: controls at a tenth of their height, cards and layers
  /// at 4. It reads as a different style rather than a smaller default.
  sharp,

  /// The default: controls at a quarter of their height (10 at 40px),
  /// cards and layers at 14.
  standard,

  /// Rounder: controls at three eighths of their height (15 at 40px),
  /// cards and layers at 21.
  soft,

  /// Every control is a capsule, text fields included. Cards and
  /// floating layers keep the standard 14: a container never becomes a
  /// capsule.
  pill,
}

/// The corner rules.
///
/// Desen has no list of per-component radii. Three rules give every
/// corner, and a corner style only changes their numbers:
///
/// 1. **Controls** (buttons, fields, select triggers, chips, segmented
///    controls, tooltips, calendar days, icon boxes, the floating bottom
///    navigation…) are rounded in proportion to their height:
///    [control] is `height × controlFactor`. A field and a button of the
///    same height always match, a small button is not nearly a capsule
///    while a large one looks boxy, and at a factor of 0.5 (the `pill`
///    style) every control is a capsule. A control's default style leaves
///    the radius unset and the control applies the rule to the height it
///    ends up with ([controlCorners]), so a style that changes only the
///    height keeps the proportion; a radius set in a style wins.
/// 2. **Containers** have one radius whatever their size: [card] for
///    cards, list sections and tables, [overlay] for floating layers
///    (menus, popovers, dialogs, panels, toasts).
/// 3. **Nested pieces** derive from what holds them: [nested] is the outer
///    radius less the inset, never below [nestedMin], so inner corners are
///    concentric with the outer ones. A segmented control's thumb, a
///    stepper's buttons, menu and list rows, bottom-navigation items, a
///    toolbar's toggles, tags in a multi-select field and media in a card
///    all follow it; [nestedCorners] applies it to the corners a container
///    ends up with.
///
/// The checkbox is the one small exception: [checkbox] rounds it in
/// proportion to its size, capped so it never turns into a circle and
/// reads as a radio.
///
/// Customize with `DsThemeData(adjustRadii: …)`, e.g.
/// `(r, style) => r.copyWith(card: r.card + 4)` or
/// `(r, style) => r.copyWith(controlFactor: .3)`.
@immutable
class DsRadii {
  /// Creates a set of corner rules.
  ///
  /// Building one by hand is meant for tests and tools. It is not covered
  /// by the compatibility promise: later versions may add values. To
  /// customize corners, use `DsThemeData(adjustRadii: …)` with [copyWith].
  const DsRadii({
    required this.controlFactor,
    required this.card,
    required this.overlay,
    required this.checkboxFactor,
    required this.nestedMin,
  });

  /// The default rules: controls at a quarter of their height, cards and
  /// layers at 14.
  static const standard = DsRadii(
    controlFactor: .25,
    card: 14,
    overlay: 14,
    checkboxFactor: .28,
    nestedMin: 4,
  );

  /// The rules for a [DsCornerStyle].
  static DsRadii forStyle(DsCornerStyle style) => switch (style) {
    DsCornerStyle.standard => standard,
    DsCornerStyle.sharp => const DsRadii(
      controlFactor: .1,
      card: 4,
      overlay: 4,
      checkboxFactor: .1,
      nestedMin: 2,
    ),
    DsCornerStyle.soft => const DsRadii(
      controlFactor: .375,
      card: 21,
      overlay: 21,
      checkboxFactor: maxCheckboxFactor,
      nestedMin: 6,
    ),
    // Containers stay standard, so what sits inside them does too.
    DsCornerStyle.pill => const DsRadii(
      controlFactor: .5,
      card: 14,
      overlay: 14,
      checkboxFactor: maxCheckboxFactor,
      nestedMin: 4,
    ),
  };

  /// A radius large enough to make any box a capsule, for shapes that are
  /// round in every corner style: progress bars, badges, slider tracks,
  /// the sheet grabber.
  static const double pill = 999;

  /// The largest share of its size a checkbox rounds by: a third. Beyond
  /// it, a small box with continuous corners starts to read as a radio.
  static const double maxCheckboxFactor = 1 / 3;

  /// A control's radius as a share of its height: 0.1 (sharp), 0.25
  /// (standard), 0.375 (soft), 0.5 (pill, a capsule). See [control].
  final double controlFactor;

  /// Cards, list sections, tables, alerts, accordions and other boxes on
  /// the page.
  final double card;

  /// Floating layers: menus, popovers, dialogs, panels and sheets, toasts.
  final double overlay;

  /// The checkbox's radius as a share of its size; [checkbox] caps it at
  /// [maxCheckboxFactor].
  final double checkboxFactor;

  /// The smallest radius a nested piece takes when its inset is as large
  /// as its container's radius (see [nested]).
  final double nestedMin;

  /// The radius of a control [height] tall: `height × controlFactor`. At
  /// the `pill` factor (0.5) this is half the height, a capsule.
  double control(double height) => height * controlFactor;

  /// The radius of a checkbox [size] wide: `size × checkboxFactor`, never
  /// more than [maxCheckboxFactor] of it, so it never becomes a circle.
  double checkbox(double size) =>
      size * math.min(checkboxFactor, maxCheckboxFactor);

  /// The radius of a piece inset by [inset] inside a box with radius
  /// [outer]: `outer - inset`, at least [nestedMin], never more than
  /// [outer]. Its corners are concentric with the outer ones, and a piece
  /// nested in a capsule is a capsule.
  double nested(double outer, double inset) =>
      math.min(outer, math.max(outer - inset, nestedMin));

  /// The corners of a control [height] tall: [radius] when a style sets
  /// one, otherwise [control] of the height.
  ///
  /// Control styles leave their radius unset, so a style that changes only
  /// the height (`DsButtonStyle(height: 48)`) keeps the corners in
  /// proportion, a capsule stays a capsule, and an explicit radius always
  /// wins.
  BorderRadiusGeometry controlCorners(
    BorderRadiusGeometry? radius,
    double height,
  ) => radius ?? BorderRadius.circular(control(height));

  /// The corners of a piece inset by [inset] inside a box with corners
  /// [outer]: [radius] when a style sets one, otherwise [nested] of each
  /// outer corner, so the piece stays concentric with whatever corners its
  /// container ends up with.
  BorderRadiusGeometry nestedCorners(
    BorderRadiusGeometry? radius,
    BorderRadiusGeometry outer,
    double inset,
  ) {
    if (radius != null) return radius;
    Radius n(Radius r) =>
        Radius.elliptical(nested(r.x, inset), nested(r.y, inset));
    return switch (outer) {
      BorderRadius() => BorderRadius.only(
        topLeft: n(outer.topLeft),
        topRight: n(outer.topRight),
        bottomLeft: n(outer.bottomLeft),
        bottomRight: n(outer.bottomRight),
      ),
      BorderRadiusDirectional() => BorderRadiusDirectional.only(
        topStart: n(outer.topStart),
        topEnd: n(outer.topEnd),
        bottomStart: n(outer.bottomStart),
        bottomEnd: n(outer.bottomEnd),
      ),
      // A mix of both kinds, which only arithmetic on radii produces.
      _ => nestedCorners(null, outer.resolve(TextDirection.ltr), inset),
    };
  }

  /// Returns a copy with the given values replaced.
  DsRadii copyWith({
    double? controlFactor,
    double? card,
    double? overlay,
    double? checkboxFactor,
    double? nestedMin,
  }) => DsRadii(
    controlFactor: controlFactor ?? this.controlFactor,
    card: card ?? this.card,
    overlay: overlay ?? this.overlay,
    checkboxFactor: checkboxFactor ?? this.checkboxFactor,
    nestedMin: nestedMin ?? this.nestedMin,
  );

  /// Linearly interpolates between two sets of rules.
  static DsRadii lerp(DsRadii a, DsRadii b, double t) {
    if (identical(a, b)) return a;
    double l(double x, double y) => lerpDouble(x, y, t)!;
    return DsRadii(
      controlFactor: l(a.controlFactor, b.controlFactor),
      card: l(a.card, b.card),
      overlay: l(a.overlay, b.overlay),
      checkboxFactor: l(a.checkboxFactor, b.checkboxFactor),
      nestedMin: l(a.nestedMin, b.nestedMin),
    );
  }

  List<double> get _all => [
    controlFactor,
    card,
    overlay,
    checkboxFactor,
    nestedMin,
  ];

  @override
  bool operator ==(Object other) =>
      other is DsRadii && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);
}
