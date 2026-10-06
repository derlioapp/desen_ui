import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../painting/line.dart';

import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'divider_style.dart';

/// A thin line between two things: rows, sections, groups of controls.
///
/// ```dart
/// const DsDivider()                       // full width
/// const DsDivider(indent: DsSpace.s16)    // inset from the leading edge
/// const DsDivider.vertical()              // between controls in a row
/// ```
///
/// **The line, not the gap.** A divider takes exactly its thickness and
/// no margin; the space around it belongs to the layout (a `Column`'s
/// `spacing`, a list's padding).
///
/// **Insets follow the text direction.** [indent] is at the leading edge
/// of a horizontal line, so it moves to the right in right-to-left text;
/// for a vertical line it is at the top.
///
/// **It fills its length.** A horizontal divider is as wide as its parent
/// allows, a vertical one as tall. Without a bound (a horizontal divider
/// in a `Row`, a vertical one in a `Column`) it takes no length, so give a
/// vertical divider's row a height or wrap it in an `IntrinsicHeight`.
///
/// **Decorative.** It adds nothing for screen readers: the structure it
/// draws comes from headings and section labels.
///
/// The color is the theme's `border` role by default, the color of every
/// other divider and container outline.
/// See [DsDividerStyle] and [DsDividerTheme] to change it.
class DsDivider extends StatelessWidget {
  /// A horizontal line, as wide as it may be.
  const DsDivider({super.key, this.indent, this.endIndent, this.style})
    : axis = Axis.horizontal;

  /// A vertical line, as tall as it may be.
  const DsDivider.vertical({super.key, this.indent, this.endIndent, this.style})
    : axis = Axis.vertical;

  /// Which way the line runs.
  final Axis axis;

  /// Inset at the start: the leading edge of a horizontal line, the top
  /// of a vertical one. Wins over the style's `indent`.
  final double? indent;

  /// Inset at the end: the trailing edge of a horizontal line, the bottom
  /// of a vertical one. Wins over the style's `endIndent`.
  final double? endIndent;

  /// Style laid over the theme and defaults.
  final DsDividerStyle? style;

  /// Desen's default divider style under [theme]: one pixel in the
  /// `border` color, no insets.
  static DsDividerStyle defaultStyle(DsThemeData theme) {
    return DsDividerStyle(
      thickness: 1,
      color: theme.colors.border,
      indent: 0,
      endIndent: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = DsTheme.of(context);
    final s = DsDividerStyle.resolveLayers([
      DsDivider.defaultStyle(theme),
      DsDividerTheme.of(context).style,
      style,
      DsDividerStyle(indent: indent, endIndent: endIndent),
    ], const {});
    final horizontal = axis == Axis.horizontal;
    final thickness = s.thickness!;
    // Fills the length it is given; LimitedBox makes that zero when the
    // length is unbounded, instead of failing.
    final line = LimitedBox(
      maxWidth: horizontal ? 0 : double.infinity,
      maxHeight: horizontal ? double.infinity : 0,
      child: SizedBox(
        width: horizontal ? double.infinity : thickness,
        height: horizontal ? thickness : double.infinity,
        // A one-pixel divider is a hairline like every separator: one
        // device pixel.
        child: thickness == 1
            ? DsLine(color: s.color!, axis: axis)
            : ColoredBox(color: s.color!),
      ),
    );
    return Padding(
      padding: horizontal
          ? EdgeInsetsDirectional.only(start: s.indent!, end: s.endIndent!)
          : EdgeInsetsDirectional.only(top: s.indent!, bottom: s.endIndent!),
      child: line,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty('axis', axis))
      ..add(DoubleProperty('indent', indent, defaultValue: null))
      ..add(DoubleProperty('endIndent', endIndent, defaultValue: null))
      ..add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}
