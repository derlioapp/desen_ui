import 'package:flutter/widgets.dart';

import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';

/// A keyboard shortcut hint such as "⌘E" or "⇧⌘⌫", as menus and tooltips
/// show it.
///
/// The modifier and editing key symbols (⌘ ⌥ ⇧ ⌫ ⏎, and ↵ for Enter) are
/// drawn as [DsIcons] at the text size, so they never depend on the font
/// having the glyph; other characters stay text. Screen readers hear the
/// keys by name, in the app's language ("⇧⌘E" as "Shift Command E";
/// [spokenLabel]), not the symbols.
class DsShortcut extends StatelessWidget {
  /// Creates a shortcut hint.
  const DsShortcut(this.keys, {super.key, this.textStyle});

  /// The keys, e.g. "⌘E".
  final String keys;

  /// Text style; its color and size also color and size the key icons.
  final TextStyle? textStyle;

  /// The key symbols drawn as icons.
  static const Map<String, DsIconData> icons = {
    '⌘': DsIcons.command,
    '⌥': DsIcons.option,
    '⇧': DsIcons.arrowBigUp,
    '⌫': DsIcons.backspace,
    '⏎': DsIcons.enter,
    '↵': DsIcons.enter,
  };

  /// [keys] as screen readers hear them: each modifier and editing key
  /// symbol (⌘ ⌥ ⇧ ⌃ ⌫ ⏎ ↵) by its localized name, the rest as written,
  /// apart by spaces ("⇧⌘E" is "Shift Command E").
  static String spokenLabel(String keys, DsLocalizations l10n) {
    final words = <String>[];
    final text = StringBuffer();
    void flush() {
      final word = text.toString().trim();
      if (word.isNotEmpty) words.add(word);
      text.clear();
    }

    for (final char in keys.characters) {
      final name = switch (char) {
        '⌘' => l10n.keyCommand,
        '⌥' => l10n.keyOption,
        '⇧' => l10n.keyShift,
        '⌃' => l10n.keyControl,
        '⌫' => l10n.keyBackspace,
        '⏎' || '↵' => l10n.keyEnter,
        _ => null,
      };
      if (name == null) {
        text.write(char);
        continue;
      }
      flush();
      words.add(name);
    }
    flush();
    return words.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final resolved = DefaultTextStyle.of(context).style.merge(textStyle);
    // ds-raw: an unsized style; the icons then match the caption size
    final fontSize = resolved.fontSize ?? 12;
    final scaler = MediaQuery.textScalerOf(context);
    final iconSize = scaler.scale(fontSize);
    final color = resolved.color;
    final parts = <Widget>[];
    final text = StringBuffer();
    void flush() {
      if (text.isEmpty) return;
      parts.add(Text(text.toString(), style: textStyle, maxLines: 1));
      text.clear();
    }

    for (final char in keys.characters) {
      final icon = icons[char];
      if (icon == null) {
        text.write(char);
        continue;
      }
      flush();
      parts.add(DsIcon(icon, size: iconSize, color: color));
    }
    flush();
    return Semantics(
      label: spokenLabel(keys, DsLocalizations.of(context)),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: fontSize / 12,
          children: parts,
        ),
      ),
    );
  }
}
