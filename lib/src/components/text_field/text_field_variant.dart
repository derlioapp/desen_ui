/// The forms of a text field, each with its own default look; a
/// [DsTextFieldThemeData] can style one form through its `variants`.
///
/// The form follows from the widget: `DsTextField()` is [singleLine],
/// `DsTextField.multiline()` is [multiline] and `DsSearchField` is
/// [search].
enum DsTextFieldVariant {
  /// One line of text in a well.
  singleLine,

  /// Several lines that grow with the text, then scroll.
  multiline,

  /// A search box drawn as a control, with a magnifier.
  search,
}
