import 'package:flutter/widgets.dart';

import '../../overlay/plain_text.dart';

/// [description] as a control's hint for screen readers: a [Text] is read
/// after the control's name and state (not joined into the name), its own
/// text node left out. Another widget is read as it is. Internal to the
/// library.
Widget descriptionAsHint(Widget description) {
  final text = switch (description) {
    Text(:final semanticsLabel?) => semanticsLabel,
    _ => plainTextOf(description),
  };
  if (text == null) return description;
  return Semantics(
    hint: text,
    child: ExcludeSemantics(child: description),
  );
}

/// The text beside a checkbox or radio: the [label], and a [description]
/// under it, [gap] apart. Each is merged over the ambient text style with
/// its own style; under a label the description is the control's hint
/// ([descriptionAsHint]), alone it names the control. A label alone is
/// laid out as before, without a column.
class SelectionText extends StatelessWidget {
  /// Lays out a label and an optional description.
  const SelectionText({
    super.key,
    required this.label,
    required this.description,
    required this.labelStyle,
    required this.descriptionStyle,
    required this.gap,
  }) : assert(label != null || description != null);

  /// The label, usually a [Text].
  final Widget? label;

  /// Secondary text under the label.
  final Widget? description;

  /// Merged over the ambient style for [label].
  final TextStyle? labelStyle;

  /// Merged over the ambient style for [description].
  final TextStyle? descriptionStyle;

  /// Space between the label and the description.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final label = this.label == null
        ? null
        : DefaultTextStyle.merge(style: labelStyle, child: this.label!);
    if (description == null) return label!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: gap,
      children: [
        ?label,
        DefaultTextStyle.merge(
          style: descriptionStyle,
          child: label == null ? description! : descriptionAsHint(description!),
        ),
      ],
    );
  }
}
