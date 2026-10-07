import 'package:flutter/painting.dart';

/// [text] in [style], with tabular figures on its digits only.
///
/// A style from `DsTypography.numeric` sets tabular figures (OpenType
/// `tnum`) for the whole text. In some faces, Schibsted Grotesk among
/// them, `tnum` also widens the punctuation between the digits (`.`, `,`,
/// `:`, `/`) to a digit's width, so "12.480,00" reads like a typewriter.
/// This keeps `tnum` on runs of digits, so the digits still line up in a
/// column and a changing value does not shift, and sets every other run
/// (separators, signs, letters, spaces) with the face's own spacing.
///
/// When [style] does not ask for tabular figures, the text is one plain
/// span.
TextSpan numericSpan(String text, {TextStyle? style}) {
  final features = style?.fontFeatures;
  if (features == null || !features.contains(_tabular)) {
    return TextSpan(text: text, style: style);
  }
  final runs = _digits.allMatches(text).toList();
  // All digits, or none: nothing to split.
  if (runs.isEmpty || (runs.length == 1 && runs.single.group(0) == text)) {
    return TextSpan(text: text, style: style);
  }
  // Turned off explicitly: a run with tabular figures merely left out of
  // its list still takes the parent's.
  final proportional = TextStyle(
    fontFeatures: [
      for (final f in features)
        if (f != _tabular) f,
      const FontFeature.disable('tnum'),
    ],
  );
  final children = <TextSpan>[];
  var at = 0;
  for (final run in runs) {
    if (run.start > at) {
      children.add(
        TextSpan(text: text.substring(at, run.start), style: proportional),
      );
    }
    children.add(TextSpan(text: run.group(0)));
    at = run.end;
  }
  if (at < text.length) {
    children.add(TextSpan(text: text.substring(at), style: proportional));
  }
  return TextSpan(style: style, children: children);
}

const _tabular = FontFeature.tabularFigures();

/// Runs of decimal digits, in any script.
final _digits = RegExp(r'\p{Nd}+', unicode: true);
