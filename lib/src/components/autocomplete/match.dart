import 'package:flutter/painting.dart';

import '../../foundation/case.dart';
import '../select/select.dart';

/// Where [query] first occurs in [label], compared with [dsFoldCase]
/// (Turkish dotless and dotted i, ß, final sigma), as a range of [label]'s
/// own code units; null when it does not occur or [query] is empty.
///
/// Folding can change a character's length (`ß` → `ss`, `İ` → `i`), so the
/// label is folded one character at a time and each folded code unit
/// remembers the character it came from.
TextRange? matchRange(String label, String query) {
  final wanted = dsFoldCase(query);
  if (wanted.isEmpty) return null;
  final folded = StringBuffer();
  // For each folded code unit: start and end of its source character.
  final starts = <int>[], ends = <int>[];
  var i = 0;
  for (final rune in label.runes) {
    final char = String.fromCharCode(rune);
    final piece = dsFoldCase(char);
    folded.write(piece);
    for (var k = 0; k < piece.length; k++) {
      starts.add(i);
      ends.add(i + char.length);
    }
    i += char.length;
  }
  final at = folded.toString().indexOf(wanted);
  if (at < 0) return null;
  return TextRange(start: starts[at], end: ends[at + wanted.length - 1]);
}

/// [label] as spans with the first match of [query] in [match] laid over
/// [style]: the matched letters in weight 700.
TextSpan highlightMatch(
  String label,
  String query, {
  TextStyle? style,
  TextStyle? match,
}) {
  final range = matchRange(label, query);
  if (range == null) return TextSpan(text: label, style: style);
  return TextSpan(
    style: style,
    children: [
      if (range.start > 0) TextSpan(text: range.textBefore(label)),
      TextSpan(text: range.textInside(label), style: match),
      if (range.end < label.length) TextSpan(text: range.textAfter(label)),
    ],
  );
}

/// Whether [label] contains [query], case-folded; an empty [query] matches
/// everything.
bool containsFolded(String label, String query) =>
    query.isEmpty || dsFoldCase(label).contains(dsFoldCase(query));

final _folded = Expando<String>('dsFoldedLabel');

/// [option]'s label folded with [dsFoldCase], folded once per option
/// object and then remembered.
String foldedLabel(DsSelectOption<Object?> option) =>
    _folded[option] ??= dsFoldCase(option.label);
