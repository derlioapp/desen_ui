import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

import '../foundation/platform.dart';

/// Density, an end-user setting.
enum DsDensity {
  /// Compact controls, rows and type, for pointer screens: the default on
  /// desktop and in desktop browsers. Tap areas follow the platform: 24px
  /// on desktop, 44px on iOS and Android.
  compact,

  /// Touch input: same-size controls with 44px tap areas, taller rows and
  /// the larger type ramp. The default on iOS and Android, their browsers
  /// included.
  touch;

  /// The density a theme takes when none is given: [touch] on iOS and
  /// Android, [compact] elsewhere.
  static DsDensity forPlatform(TargetPlatform platform) =>
      isTouchPlatform(platform) ? touch : compact;
}

/// Control size steps shared by buttons, fields and other controls.
enum DsSize {
  /// Extra small.
  xs,

  /// Small.
  sm,

  /// Medium. The default.
  md,

  /// Large.
  lg,
}

/// Heights and icon sizes for a [DsDensity].
@immutable
class DsSizes {
  /// Creates a size set.
  ///
  /// Building one by hand is meant for tests and tools. It is not covered
  /// by the compatibility promise: later versions may add sizes. To
  /// customize sizes, use `DsThemeData(adjustSizes: …)` with [copyWith].
  const DsSizes({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.row,
    required this.day,
    required this.listRow,
    required this.minTapTarget,
    this.iconXs = 14,
    this.iconSm = 16,
    this.iconMd = 16,
    this.iconLg = 20,
  });

  /// Pointer density: 28 · 32 · 40 · 48.
  static const compact = DsSizes(
    xs: 28,
    sm: 32,
    md: 40,
    lg: 48,
    row: 32,
    listRow: 40,
    day: 32,
    minTapTarget: 24,
  );

  /// Touch density: controls keep their pointer sizes (28 · 32 · 40 · 48)
  /// and get an invisible 44px tap area around them instead, so
  /// nothing looks bigger. Menu and sidebar rows (44) and list rows (48)
  /// are themselves the tap surface. A calendar day draws a 38px cell but,
  /// like any small control, takes a [minTapTarget] (44px) tap area: the
  /// calendar lays its days out on that pitch.
  static const touch = DsSizes(
    xs: 28,
    sm: 32,
    md: 40,
    lg: 48,
    row: 44,
    listRow: 48,
    day: 38,
    minTapTarget: 44,
  );

  /// Compact density on a phone or tablet (iOS, Android): the [compact]
  /// controls and rows, each small control inside an invisible 44px tap
  /// area. Nothing looks bigger; side-by-side small controls
  /// sit a little further apart because the area takes real space. Rows
  /// are themselves the tap surface and keep their compact heights (32 and
  /// 40), above WCAG 2.5.8's 24px; choose [touch] for 44 and 48.
  static const compactOnTouchPlatform = DsSizes(
    xs: 28,
    sm: 32,
    md: 40,
    lg: 48,
    row: 32,
    listRow: 40,
    day: 32,
    minTapTarget: 44,
  );

  /// The size set for [density] on [platform]. iOS and Android get 44px
  /// tap areas at either density; other platforms (desktop, and the web on
  /// a desktop browser) 24px at [DsDensity.compact]. Without a [platform],
  /// the pointer sizes.
  static DsSizes forDensity(DsDensity density, {TargetPlatform? platform}) =>
      switch (density) {
        DsDensity.touch => touch,
        DsDensity.compact when isTouchPlatform(platform) =>
          compactOnTouchPlatform,
        DsDensity.compact => compact,
      };

  /// Extra-small control height.
  final double xs;

  /// Small control height.
  final double sm;

  /// Medium control height.
  final double md;

  /// Large control height.
  final double lg;

  /// Menu and sidebar row height.
  final double row;

  /// Settings-style list row height (a list section in a card).
  final double listRow;

  /// Calendar day cell, as drawn. Its tap area is [minTapTarget] when that
  /// is larger.
  final double day;

  /// Minimum hit area; visuals may be smaller.
  final double minTapTarget;

  /// Icon size in an extra-small control: 14.
  final double iconXs;

  /// Icon size in a small control: 16.
  final double iconSm;

  /// Icon size in a medium control, and the default icon size inside
  /// dialogs and popovers: 16.
  final double iconMd;

  /// Icon size in a large control: 20.
  final double iconLg;

  /// The control height for [size].
  double height(DsSize size) => switch (size) {
    DsSize.xs => xs,
    DsSize.sm => sm,
    DsSize.md => md,
    DsSize.lg => lg,
  };

  /// The icon size for a control of [size]: [iconXs], [iconSm], [iconMd]
  /// or [iconLg].
  double iconSize(DsSize size) => switch (size) {
    DsSize.xs => iconXs,
    DsSize.sm => iconSm,
    DsSize.md => iconMd,
    DsSize.lg => iconLg,
  };

  /// Returns a copy with the given values replaced.
  DsSizes copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? row,
    double? listRow,
    double? day,
    double? minTapTarget,
    double? iconXs,
    double? iconSm,
    double? iconMd,
    double? iconLg,
  }) => DsSizes(
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    row: row ?? this.row,
    listRow: listRow ?? this.listRow,
    day: day ?? this.day,
    minTapTarget: minTapTarget ?? this.minTapTarget,
    iconXs: iconXs ?? this.iconXs,
    iconSm: iconSm ?? this.iconSm,
    iconMd: iconMd ?? this.iconMd,
    iconLg: iconLg ?? this.iconLg,
  );

  /// Linearly interpolates between two size sets.
  static DsSizes lerp(DsSizes a, DsSizes b, double t) {
    if (identical(a, b)) return a;
    double l(double x, double y) => lerpDouble(x, y, t)!;
    return DsSizes(
      xs: l(a.xs, b.xs),
      sm: l(a.sm, b.sm),
      md: l(a.md, b.md),
      lg: l(a.lg, b.lg),
      row: l(a.row, b.row),
      listRow: l(a.listRow, b.listRow),
      day: l(a.day, b.day),
      minTapTarget: l(a.minTapTarget, b.minTapTarget),
      iconXs: l(a.iconXs, b.iconXs),
      iconSm: l(a.iconSm, b.iconSm),
      iconMd: l(a.iconMd, b.iconMd),
      iconLg: l(a.iconLg, b.iconLg),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DsSizes &&
      other.xs == xs &&
      other.sm == sm &&
      other.md == md &&
      other.lg == lg &&
      other.row == row &&
      other.listRow == listRow &&
      other.day == day &&
      other.minTapTarget == minTapTarget &&
      other.iconXs == iconXs &&
      other.iconSm == iconSm &&
      other.iconMd == iconMd &&
      other.iconLg == iconLg;

  @override
  int get hashCode => Object.hash(
    xs,
    sm,
    md,
    lg,
    row,
    listRow,
    day,
    minTapTarget,
    iconXs,
    iconSm,
    iconMd,
    iconLg,
  );
}

/// The spacing scale: a 4px rhythm up to [s28], then the layout steps
/// [s32], [s40], [s48] and [s64] for space between page sections.
///
/// Concentric insets inside channels (segment thumbs and the like) may use
/// the half steps [s3], [s5] and [s6].
abstract final class DsSpace {
  /// 3px, concentric inset.
  static const double s3 = 3;

  /// 4px.
  static const double s4 = 4;

  /// 5px, concentric inset.
  static const double s5 = 5;

  /// 6px, concentric inset.
  static const double s6 = 6;

  /// 8px.
  static const double s8 = 8;

  /// 12px.
  static const double s12 = 12;

  /// 16px.
  static const double s16 = 16;

  /// 20px.
  static const double s20 = 20;

  /// 24px.
  static const double s24 = 24;

  /// 28px.
  static const double s28 = 28;

  /// 32px, layout: between groups of a page.
  static const double s32 = 32;

  /// 40px, layout.
  static const double s40 = 40;

  /// 48px, layout: between sections of a page.
  static const double s48 = 48;

  /// 64px, layout: around a page's content on wide screens.
  static const double s64 = 64;
}
