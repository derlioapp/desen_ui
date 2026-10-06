import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';
import '../text_field/text_field.dart';
import '../text_field/text_field_style.dart';
import '../text_field/text_field_variant.dart';
import 'field.dart';
import 'field_well.dart';

/// The bare box of a text field, around content of your own: its fill,
/// its edge, its corners, and its focus, error, read-only and disabled
/// looks.
///
/// For a control that should sit among fields and look like one, such as
/// a trigger that opens a picker of your own:
///
/// ```dart
/// DsPressable(
///   onPressed: pickColor,
///   builder: (context, states, _) => DsFieldSurface(
///     states: states,
///     child: Row(
///       spacing: 8,
///       children: [ColorDot(color), Text(colorName)],
///     ),
///   ),
/// )
/// ```
///
/// It draws exactly what a `DsTextField` draws around its text, from the
/// same style: Desen's text field defaults, then the [DsTextFieldTheme]
/// above it, then [style]. A theme that changes your text fields changes
/// this box too. Of the style it uses the well (`height`, `padding`,
/// `background`, `borderColor`, `borderWidth`, `borderRadius`, `shadows`,
/// `focusShadows`) and gives [child] the text and icon look (`textStyle`
/// and `foreground`, `iconColor` and `iconSize`); the rest belongs to
/// editing text and is ignored.
///
/// The look follows [states]:
/// - [WidgetState.focused]: the edge turns 2px in the focus color, drawn
///   inside the box so nothing moves. Pass the focus you want shown:
///   `DsPressable` reports keyboard focus only, as a select shows it; a
///   box where typing goes shows every focus, as a text field does.
/// - [WidgetState.hovered]: the edge strengthens (not while focused).
/// - [WidgetState.error]: a 2px danger edge. Inside a `DsField` with an
///   error it shows without being passed. Pair it with an icon or a
///   message, so the error is not told by color alone.
/// - [WidgetState.disabled]: the dimmed fill, a faint edge and dimmed
///   content.
///
/// With [readOnly] it reads as a value on the page rather than a box to
/// fill in: no fill, a faint hairline edge, full-contrast content.
///
/// Corners follow the resolved height (`DsRadii.controlCorners`) unless a
/// style sets them, so a taller box keeps the field's proportion. The box
/// is at least `height` tall, shrink-wraps its content under loose
/// constraints and holds it at the start, vertically centered. It draws
/// nothing for screen readers and handles no input: the control it
/// belongs to does.
class DsFieldSurface extends StatefulWidget {
  /// Draws the field box around [child] for [states].
  const DsFieldSurface({
    super.key,
    required this.child,
    this.states = const {},
    this.readOnly = false,
    this.style,
  });

  /// The content of the box.
  final Widget child;

  /// The states to show: focused, hovered, error and disabled.
  final Set<WidgetState> states;

  /// Shows a value that cannot be changed.
  final bool readOnly;

  /// Style laid over the text field theme and defaults.
  final DsTextFieldStyle? style;

  @override
  State<DsFieldSurface> createState() => _DsFieldSurfaceState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty('states', states))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'read-only'))
      ..add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}

class _DsFieldSurfaceState extends State<DsFieldSurface> {
  Set<WidgetState>? _lastStates;
  bool? _lastReadOnly;

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final given = widget.states;
    final focused = given.contains(WidgetState.focused);
    final disabled = given.contains(WidgetState.disabled);
    final states = {
      for (final s in given)
        // A focused box keeps its focus edge under the pointer.
        if (s != WidgetState.hovered || !focused) s,
      if (DsFieldScope.maybeOf(context)?.hasError ?? false) WidgetState.error,
    };
    final readOnly = widget.readOnly && !disabled;
    final themeData = DsTextFieldTheme.of(context);
    const variant = DsTextFieldVariant.singleLine;
    final s = DsTextFieldStyle.resolveLayers(
      [
        DsTextField.defaultStyle(t),
        themeData.style,
        themeData.variants[variant],
        widget.style,
      ],
      states,
      readOnly: readOnly,
    );
    // Animate only state changes; a theme change is followed directly.
    final animate =
        _lastStates != null &&
        (!setEquals(_lastStates, states) || _lastReadOnly != readOnly);
    _lastStates = states;
    _lastReadOnly = readOnly;
    final height = s.height!;
    return FieldWell(
      duration: animate ? t.motion.toneDuration : Duration.zero,
      curve: t.motion.toneCurve,
      minHeight: height,
      padding: s.padding,
      background: s.background,
      borderColor: s.borderColor,
      borderWidth: s.borderWidth!,
      borderRadius: t.radii.controlCorners(s.borderRadius, height),
      shadows: s.shadows,
      focusShadows: s.focusShadows,
      focused: focused,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: IconTheme.merge(
          data: IconThemeData(color: s.iconColor, size: s.iconSize),
          child: DefaultTextStyle.merge(
            style: (s.textStyle ?? const TextStyle()).copyWith(
              color: s.foreground,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
