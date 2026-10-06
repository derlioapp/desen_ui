import 'package:flutter/widgets.dart';

/// The text beside a checkbox or radio: the [label], and a [description]
/// under it, [gap] apart. Each is merged over the ambient text style with
/// its own style. A label alone is laid out as before, without a column.
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
        DefaultTextStyle.merge(style: descriptionStyle, child: description!),
      ],
    );
  }
}
