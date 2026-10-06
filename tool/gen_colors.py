# Generates lib/src/theme/colors.dart. Each field: (name, type, doc)
groups = [
 ("Surfaces", [
  ("canvas","Color","Page background, the lowest layer."),
  ("surface","Color","Cards, list groups, tables."),
  ("sidebar","Color","Side navigation background."),
  ("control","Color","Secondary buttons and other raised controls."),
  ("controlHover","Color","[control] while hovered."),
  ("controlPress","Color","[control] while pressed: one step beyond [controlHover]."),
  ("overlay","Color","Floating layers: menus, popovers, toasts, dialogs."),
  ("field","Color","Text field and checkbox well."),
 ]),
 ("Text", [
  ("text","Color","Primary text."),
  ("textMuted","Color","Secondary text, field labels."),
  ("textSubtle","Color","Tertiary text, placeholders, meta."),
 ]),
 ("Accent", [
  ("accent","Color","Brand fill: primary button, checked controls, switch track. Usually labeled white; a light brand (yellow, orange, sky) keeps its own bright fill with a dark [onAccent] instead."),
  ("accentHover","Color","[accent] while hovered: a step away from [onAccent]."),
  ("accentPress","Color","[accent] while pressed: one step beyond [accentHover], further from [onAccent]."),
  ("onAccent","Color","Text and icons on [accent]: white, or a dark ink tinted toward the seed on a bright accent."),
  ("accentEdge","Color","1px edge of an [accent] fill that stands under 3:1 off the layers it sits on: a bright accent (dark [onAccent]) on a light card, or a white-labeled fill in dark mode, held dark by its label, on the lighter floating layer. Checked checkboxes and radios, the switch's on track and filled selections draw it inside their fill, so their shape does not melt into the layer (WCAG 1.4.11). The [onAccent] label at the lowest opacity that brings the edge to 3:1 on every layer, hover and press included; transparent when the fill stands on its own. Labeled buttons do not draw it."),
  ("indicator","Color","Accent marks with no label on them: progress and slider fill, tab underline, text caret. [accent] in light mode (darkened under a bright accent), a lighter accent in dark mode. Stands 3:1 off [channelStrong], the surface and the field. Never olive, mustard or brown: where the accent hue's deep tone would be (a yellow or amber in light mode), it turns to the nearest clean hue at the same contrast, a deep orange or lime; in dark mode a warm hue rises toward the lightness where it is vivid."),
  ("accentTint","Color","Translucent accent wash: date range band, icon boxes. In light mode a bright accent's wash comes from its fill (a pale butter, not a beige); in dark mode a warm brand's is a neutral wash, since a warm tint on dark gray reads olive or brown."),
  ("accentText","Color","Accent used as text, e.g. today in a calendar."),
  ("link","Color","Links and text buttons."),
 ]),
 ("Selection", [
  ("selection","Color","Soft selection background (chips, menu rows, nav items)."),
  ("selectionHover","Color","[selection] while hovered or keyboard focused: a stronger tint, so focus stays visible on a selected item."),
  ("onSelection","Color","Text on [selection] and [selectionHover]."),
  ("selectionStrong","Color","Filled selection background."),
  ("selectionStrongHover","Color","[selectionStrong] while hovered or keyboard focused; darkens under its light label."),
  ("onSelectionStrong","Color","Text on [selectionStrong] and [selectionStrongHover]."),
 ]),
 ("Focus", [
  ("focus","Color","Keyboard focus outline. Stands 3:1 off the page and the surfaces."),
 ]),
 ("Lines", [
  ("border","Color","Dividers and container outlines."),
  ("borderControl","Color","Edge of raised controls."),
  ("borderField","Color","Inner outline of text fields and checkboxes: 3:1 at standard contrast; a light edge (about 1.5:1) at soft contrast."),
  ("borderChip","Color","Outline of unselected chips."),
 ]),
 ("Channels and rails", [
  ("channel","Color","Recessed channel of segmented controls and steppers. May be translucent; layer it on a surface."),
  ("channelStrong","Color","A step stronger than [channel]: the unfilled part of slider and progress tracks, and small neutral fills such as the sheet grabber."),
  ("rail","Color","The switch's track while off. Meets 3:1 against surfaces (WCAG 1.4.11) at standard contrast, unlike the decorative channels; a light, iOS-like fill at soft contrast."),
  ("channelThumb","Color","The raised piece in a [channel]: the selected segment of a soft segmented control, stepper buttons."),
  ("knob","Color","Switch knob and slider thumb."),
  ("skeleton","Color","Skeleton blocks and lines: a neutral fill that stands about 1.25:1 off a white card, like iOS's placeholder fill, and as much off the page and the sidebar. Translucent; layer it on a surface."),
  ("skeletonStrong","Color","A step stronger than [skeleton]: strong skeleton lines, such as a title."),
  ("shimmer","Color","Highlight swept across [skeleton] fills while loading."),
 ]),
 ("Interaction", [
  ("hover","Color","Translucent hover layer."),
  ("press","Color","Translucent pressed layer."),
  ("disabled","Color","Disabled control background."),
  ("onDisabled","Color","Disabled text and icons."),
  ("scrim","Color","Modal barrier."),
 ]),
 ("Tooltip", [
  ("tooltip","Color","Tooltip background."),
  ("onTooltip","Color","Tooltip text."),
  ("onTooltipMuted","Color","Secondary tooltip text, e.g. shortcuts."),
 ]),
 ("Status", [
  ("neutral","DsStatusColors","Neutral badges."),
  ("danger","DsStatusColors","Errors and destructive actions."),
  ("success","DsStatusColors","Success."),
  ("warning","DsStatusColors","Warnings."),
  ("info","DsStatusColors","Information."),
 ]),
]
fields=[f for _,g in groups for f in g]
o=[]
w=o.append
w("""// GENERATED by tool/gen_colors.py. Do not edit by hand.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../foundation/color_utils.dart';

/// The colors for one status (danger, success, warning, info, neutral).
@immutable
class DsStatusColors {
  /// Creates status colors.
  ///
  /// Building them by hand is meant for tests and tools. It is not covered
  /// by the compatibility promise: later versions may add fields. To change
  /// a status, use `DsThemeData(adjustColors: …)` with [copyWith].
  const DsStatusColors({
    required this.fill,
    required this.fillHover,
    required this.fillPress,
    required this.onFill,
    required this.tint,
    required this.tintHover,
    required this.tintPress,
    required this.text,
    required this.signal,
  });

  /// Solid fill, e.g. a destructive button or a count bubble.
  final Color fill;

  /// [fill] while hovered: a step away from [onFill].
  final Color fillHover;

  /// [fill] while pressed: one step beyond [fillHover].
  final Color fillPress;

  /// Icons and text on [fill].
  ///
  /// Danger reaches 4.5:1 for body text. Success, warning and info fills are
  /// meant for icons, dots and bold labels, and guarantee 3:1 (WCAG 1.4.11).
  final Color onFill;

  /// Soft background: badges, light-mode alerts, soft buttons. Opaque.
  final Color tint;

  /// [tint] while hovered.
  final Color tintHover;

  /// [tint] while pressed: one step beyond [tintHover].
  final Color tintPress;

  /// Status-colored text on a surface or on [tint].
  final Color text;

  /// Vivid status color for marks with no text on them: status dots, alert
  /// and toast icons, status icons in lists. Stands 3:1 off the canvas, the
  /// surface and floating layers (WCAG 1.4.11), and in light mode off
  /// [tint] too. Not for text: use [text].
  final Color signal;

  /// Returns a copy with the given fields replaced.
  DsStatusColors copyWith({
    Color? fill,
    Color? fillHover,
    Color? fillPress,
    Color? onFill,
    Color? tint,
    Color? tintHover,
    Color? tintPress,
    Color? text,
    Color? signal,
  }) =>
      DsStatusColors(
        fill: fill ?? this.fill,
        fillHover: fillHover ?? this.fillHover,
        fillPress: fillPress ?? this.fillPress,
        onFill: onFill ?? this.onFill,
        tint: tint ?? this.tint,
        tintHover: tintHover ?? this.tintHover,
        tintPress: tintPress ?? this.tintPress,
        text: text ?? this.text,
        signal: signal ?? this.signal,
      );

  /// Linearly interpolates between two sets.
  static DsStatusColors lerp(DsStatusColors a, DsStatusColors b, double t) {
    if (identical(a, b)) return a;
    return DsStatusColors(
      fill: DsColorUtils.lerp(a.fill, b.fill, t)!,
      fillHover: DsColorUtils.lerp(a.fillHover, b.fillHover, t)!,
      fillPress: DsColorUtils.lerp(a.fillPress, b.fillPress, t)!,
      onFill: DsColorUtils.lerp(a.onFill, b.onFill, t)!,
      tint: DsColorUtils.lerp(a.tint, b.tint, t)!,
      tintHover: DsColorUtils.lerp(a.tintHover, b.tintHover, t)!,
      tintPress: DsColorUtils.lerp(a.tintPress, b.tintPress, t)!,
      text: DsColorUtils.lerp(a.text, b.text, t)!,
      signal: DsColorUtils.lerp(a.signal, b.signal, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DsStatusColors &&
      other.fill == fill &&
      other.fillHover == fillHover &&
      other.fillPress == fillPress &&
      other.onFill == onFill &&
      other.tint == tint &&
      other.tintHover == tintHover &&
      other.tintPress == tintPress &&
      other.text == text &&
      other.signal == signal;

  @override
  int get hashCode => Object.hash(
        fill,
        fillHover,
        fillPress,
        onFill,
        tint,
        tintHover,
        tintPress,
        text,
        signal,
      );
}

/// Every color role in a Desen theme.
///
/// Generated by the theme from its seed: read them from
/// `DsThemeData(seed: …).colors` or `DsTheme.colorsOf(context)`. Every
/// role can be replaced with [copyWith]. Component code reads colors only
/// from here, never from literals.
///
/// Translucent roles ([hover], [press], [border], tints…) are meant to be
/// layered on top of a surface, so they adapt to whatever is underneath.
@immutable
class DsColors {
  /// Creates a color set with every role given.
  ///
  /// Building one by hand is meant for tests and tools. It is not covered
  /// by the compatibility promise: later versions may add roles. To
  /// customize colors, use `DsThemeData(adjustColors: …)` with [copyWith]
  /// on the generated set (`DsThemeData(seed: …).colors`).
  const DsColors({""")
for n,t,d in fields: w(f"    required this.{n},")
w("""  });
""")
for gname,g in groups:
    w(f"  // {gname}\n")
    for n,t,d in g:
        w(f"  /// {d}\n  final {t} {n};\n")
w("  /// Returns a copy with the given roles replaced.\n  DsColors copyWith({")
for n,t,d in fields: w(f"    {t}? {n},")
w("  }) =>\n      DsColors(")
for n,t,d in fields: w(f"        {n}: {n} ?? this.{n},")
w("      );\n")
w("  /// Every role as a flat map, status sets expanded (`danger.fill`, …).\n  /// Keys are the field names; useful for export, debugging and snapshots.\n  Map<String, Color> toMap() => {")
for n,t,d in fields:
    if t=="Color": w(f"    '{n}': {n},")
    else:
        for sub in ["fill","fillHover","fillPress","onFill","tint","tintHover","tintPress","text","signal"]:
            w(f"    '{n}.{sub}': {n}.{sub},")
w("  };\n")
w("  /// Linearly interpolates between two color sets.\n  static DsColors lerp(DsColors a, DsColors b, double t) {\n    if (identical(a, b)) return a;\n    return DsColors(")
for n,t,d in fields:
    if t=="Color": w(f"      {n}: DsColorUtils.lerp(a.{n}, b.{n}, t)!,")
    else: w(f"      {n}: DsStatusColors.lerp(a.{n}, b.{n}, t),")
w("    );\n  }\n")
w("  @override\n  bool operator ==(Object other) =>\n      other is DsColors &&")
w(" &&\n".join(f"      other.{n} == {n}" for n,_,_ in fields)+";\n")
w("  @override\n  int get hashCode => Object.hashAll([")
for n,t,d in fields: w(f"        {n},")
w("      ]);\n}")
import sys
open(sys.argv[1],"w").write("\n".join(o)+"\n")
print(len(fields),"fields")
