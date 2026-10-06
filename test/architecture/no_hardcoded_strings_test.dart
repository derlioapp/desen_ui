import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Everything Desen shows or announces comes from `DsLocalizations`, so it
/// is there in all 13 languages. Library code never writes a word for
/// people itself.
///
/// Checked: a string literal that is
/// - the text of a `Text(...)` or the `text:` of a `TextSpan(...)`;
/// - passed to a label-like named argument anywhere (`semanticLabel:`,
///   `label:`, `hint:`, `tooltip:`, `message:`, ...), also inside it
///   (`label: x ?? 'Close'`, `label: on ? 'On' : 'Off'`);
/// - the `value:` of `Semantics(...)`;
/// - the message of `SemanticsService.announce(...)` or
///   `sendAnnouncement(...)`.
///
/// A literal counts when something is left once its interpolations
/// (`$count`, `${a.b}`) and escapes (`\n`, ` `) are removed: `'$n'`
/// and `''` pass, `'$page / $count'` and `'*'` do not, because a separator
/// or a mark is wording too (Arabic writes `،`, Chinese `、`).
///
/// Scope: every Dart file under `lib/src` except the generated strings
/// (`l10n/strings/`). Comments are skipped, so doc examples may use any
/// text.
///
/// A literal that really is not wording (a mark whose spoken name comes
/// from `DsLocalizations`, a language-neutral counter) carries
/// `// ds-raw: <reason>` on its line or the line above, as in
/// `no_raw_values_test.dart`.
void main() {
  test('lib/src has no hardcoded user-visible strings', () {
    final offenders = <String>[];
    final files = Directory('lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => _inScope(f.path.replaceAll(r'\', '/')));
    for (final file in files) {
      final source = file.readAsStringSync();
      final lines = source.split('\n');
      for (final literal in findVisibleLiterals(source)) {
        final i = literal.line - 1;
        final excused =
            lines[i].contains('ds-raw:') ||
            (i > 0 && lines[i - 1].contains('ds-raw:'));
        if (!excused) {
          offenders.add(
            '${file.path}:${literal.line} ${literal.where}: '
            '${lines[i].trim()}',
          );
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the check catches what it should', () {
    List<String> found(String source) => [
      for (final l in findVisibleLiterals(source)) l.where,
    ];

    expect(found("Text('Save')"), ['Text']);
    expect(found("const Text('Save', maxLines: 1)"), ['Text']);
    expect(found("Text(\n  'Save',\n)"), ['Text']);
    expect(found('Text("Save")'), ['Text']);
    expect(found("Text('''Save''')"), ['Text']);
    expect(found("TextSpan(text: 'Save')"), ['text:']);
    expect(found("Semantics(label: 'Close', child: x)"), ['label:']);
    expect(found("DsIcon(i, semanticLabel: 'Close')"), ['semanticLabel:']);
    expect(found("x(label: widget.label ?? 'Close')"), ['label:']);
    expect(found("x(label: on ? 'On' : 'Off')"), ['label:', 'label:']);
    expect(found("Semantics(value: 'half')"), ['value:']);
    expect(found("SemanticsService.announce('Saved', d)"), ['announce']);
    expect(found("Text('\$page / \$count')"), ['Text']);
    expect(found("Text('*')"), ['Text']);

    // Interpolations, escapes and empty strings say nothing themselves.
    expect(found("Text('\$count')"), isEmpty);
    expect(found("Text('\${d.day}')"), isEmpty);
    expect(found(r"Text('\n')"), isEmpty);
    expect(found(r"Text('$a $b')"), isEmpty);
    expect(found("x(semanticLabel: '')"), isEmpty);
    // Nested strings inside an interpolation belong to it.
    expect(found("Text('\${a ?? 'b'}')"), isEmpty);

    // Not user-visible.
    expect(found("Text(l10n.save)"), isEmpty);
    expect(found("FocusNode(debugLabel: 'Menu')"), isEmpty);
    expect(found("x(value: 'general')"), isEmpty);
    expect(found("[a, b].join(', ')"), isEmpty);
    expect(found("Text(title, semanticsLabel: name)"), isEmpty);
    // The literal belongs to the inner call, not to the label.
    expect(found("x(label: f('id'))"), isEmpty);
    // A ternary's colon is not a named argument.
    expect(found("x(a ? label : 'b')"), isEmpty);
    // A map key's colon is not one either.
    expect(found("const {'label': 'x'}"), isEmpty);

    // Comments are skipped, also ones holding quotes.
    expect(found("/// Text('Save')\n// Text('Save')"), isEmpty);
    expect(found("/* Text('Save') */ Text(x)"), isEmpty);
    expect(found("// it's\nText(x)"), isEmpty);
    // `//` inside a string is not a comment.
    expect(found("x('http://a'); Text('Save')"), ['Text']);
    // Raw strings keep their backslashes and dollars as text.
    expect(found(r"Text(r'$x')"), ['Text']);

    expect(findVisibleLiterals("a\nb\nText('x')").single.line, 3);

    expect(_inScope('lib/src/components/x/x.dart'), isTrue);
    expect(_inScope('lib/src/overlay/x.dart'), isTrue);
    expect(_inScope('lib/src/l10n/strings/tr.dart'), isFalse);
  });
}

bool _inScope(String path) =>
    path.endsWith('.dart') &&
    path.startsWith('lib/src/') &&
    !path.startsWith('lib/src/l10n/strings/');

/// Named arguments whose string is read or shown to people.
const _labelArguments = {
  'semanticLabel',
  'semanticsLabel',
  'semanticsValue',
  'label',
  'labelText',
  'hint',
  'hintText',
  'helperText',
  'errorText',
  'placeholder',
  'tooltip',
  'message',
  'title',
  'increasedValue',
  'decreasedValue',
  'onTapHint',
  'onLongPressHint',
};

/// Calls whose first positional argument is shown or announced.
const _textCalls = {'Text', 'announce', 'sendAnnouncement'};

/// A user-visible string literal: [where] names the call or argument.
class VisibleLiteral {
  VisibleLiteral(this.line, this.where);

  final int line;
  final String where;
}

class _Frame {
  _Frame(this.callee);

  final String? callee;
  String? argument;
  int position = 0;
}

/// The string literals in [source] that are shown or announced and say
/// something themselves (see the test's doc).
List<VisibleLiteral> findVisibleLiterals(String source) =>
    _Scanner(source).run();

class _Scanner {
  _Scanner(this.s);

  final String s;
  final found = <VisibleLiteral>[];
  final frames = [_Frame(null)];

  /// The last two tokens: an identifier's name or a punctuation mark.
  String? last, beforeLast;

  void token(String t) {
    beforeLast = last;
    last = t;
  }

  static bool _identStart(int c) =>
      (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x61 && c <= 0x7A) ||
      c == 0x5F ||
      c == 0x24;

  static bool _identPart(int c) => _identStart(c) || (c >= 0x30 && c <= 0x39);

  bool _isIdent(String? t) =>
      t != null && t.isNotEmpty && _identStart(t.codeUnitAt(0));

  int lineAt(int i) => '\n'.allMatches(s.substring(0, i)).length + 1;

  List<VisibleLiteral> run() {
    var i = 0;
    while (i < s.length) {
      i = step(i, top: true);
    }
    return found;
  }

  /// Reads one token at [i] and returns where the next one starts. At the
  /// [top] level, literals are checked and calls tracked; inside an
  /// interpolation they are only skipped.
  int step(int i, {required bool top}) {
    final c = s.codeUnitAt(i);
    final ch = s[i];
    if (ch.trim().isEmpty) return i + 1;
    if (s.startsWith('//', i)) {
      final end = s.indexOf('\n', i);
      return end < 0 ? s.length : end;
    }
    if (s.startsWith('/*', i)) {
      var depth = 0;
      var j = i;
      while (j < s.length) {
        if (s.startsWith('/*', j)) {
          depth++;
          j += 2;
        } else if (s.startsWith('*/', j)) {
          depth--;
          j += 2;
          if (depth == 0) break;
        } else {
          j++;
        }
      }
      return j;
    }
    final raw =
        ch == 'r' &&
        i + 1 < s.length &&
        (s[i + 1] == "'" || s[i + 1] == '"') &&
        (i == 0 || !_identPart(s.codeUnitAt(i - 1)));
    if (raw || ch == "'" || ch == '"') {
      final start = raw ? i + 1 : i;
      final (end, visible) = readString(start, raw: raw);
      if (top) literal(i, visible);
      token("''");
      return end;
    }
    if (_identStart(c)) {
      var j = i + 1;
      while (j < s.length && _identPart(s.codeUnitAt(j))) {
        j++;
      }
      token(s.substring(i, j));
      return j;
    }
    if (c >= 0x30 && c <= 0x39) {
      var j = i + 1;
      while (j < s.length && (_identPart(s.codeUnitAt(j)) || s[j] == '.')) {
        j++;
      }
      token('0');
      return j;
    }
    if (top) punctuation(ch);
    token(ch);
    return i + 1;
  }

  void punctuation(String ch) {
    switch (ch) {
      case '(':
        frames.add(_Frame(_isIdent(last) ? last : null));
      case '[' || '{':
        frames.add(_Frame(null));
      case ')' || ']' || '}':
        if (frames.length > 1) frames.removeLast();
      case ',':
        frames.last
          ..argument = null
          ..position += 1;
      case ':':
        if (_isIdent(last) && (beforeLast == '(' || beforeLast == ',')) {
          frames.last.argument = last;
        }
    }
  }

  void literal(int at, String visible) {
    if (visible.trim().isEmpty) return;
    final f = frames.last;
    final where = switch ((f.callee, f.argument)) {
      (_, final a?) when _labelArguments.contains(a) => '$a:',
      ('TextSpan', 'text') => 'text:',
      ('Semantics', 'value') => 'value:',
      (final c?, null) when f.position == 0 && _textCalls.contains(c) => c,
      _ => null,
    };
    if (where != null) found.add(VisibleLiteral(lineAt(at), where));
  }

  /// Reads the string starting at the quote at [i]; returns where it ends
  /// and its text without interpolations and escapes.
  (int, String) readString(int i, {required bool raw}) {
    final quote = s[i];
    final triple = s.startsWith(quote * 3, i);
    final close = triple ? quote * 3 : quote;
    var j = i + close.length;
    final text = StringBuffer();
    while (j < s.length) {
      if (s.startsWith(close, j)) return (j + close.length, text.toString());
      final ch = s[j];
      if (!triple && ch == '\n') break; // unterminated: stop at the line
      if (!raw && ch == r'\') {
        j += 2;
        continue;
      }
      if (!raw && ch == r'$') {
        if (j + 1 < s.length && s[j + 1] == '{') {
          j = skipInterpolation(j + 2);
        } else {
          j++;
          while (j < s.length && _identPart(s.codeUnitAt(j))) {
            j++;
          }
        }
        continue;
      }
      text.write(ch);
      j++;
    }
    return (j, text.toString());
  }

  /// Skips a `${...}` body starting after its brace; returns the index
  /// after the closing brace.
  int skipInterpolation(int i) {
    var depth = 1;
    var j = i;
    while (j < s.length) {
      final ch = s[j];
      if (ch == '{') depth++;
      if (ch == '}') {
        depth--;
        if (depth == 0) return j + 1;
      }
      if (ch == "'" || ch == '"' || ch == 'r') {
        final before = beforeLast;
        final prev = last;
        final next = step(j, top: false);
        beforeLast = before;
        last = prev;
        j = next;
        continue;
      }
      j++;
    }
    return j;
  }
}
