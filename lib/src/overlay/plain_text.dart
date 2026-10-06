import 'package:flutter/widgets.dart';

/// The plain text of [widget] when it is a [Text] or a [RichText], e.g. a
/// dialog title used as the dialog's name for screen readers. Null for any
/// other widget. Internal to the library.
String? plainTextOf(Widget widget) {
  final text = switch (widget) {
    Text(:final data?) => data,
    Text(:final textSpan?) => textSpan.toPlainText(),
    RichText(:final text) => text.toPlainText(),
    _ => null,
  };
  return text == null || text.trim().isEmpty ? null : text;
}
