import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A block of source with light syntax colors and a copy button.
class CodeBlock extends StatefulWidget {
  const CodeBlock(
    this.code, {
    super.key,
    this.language = 'dart',
    this.collapsedLines = 14,
    this.flush = false,
  });

  final String code;

  /// 'dart', 'yaml' or 'shell'.
  final String language;

  /// Longer code shows this many lines and a button to see the rest.
  final int collapsedLines;

  /// Squares the top corners, for a block under a preview.
  final bool flush;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool _expanded = false;
  bool _copied = false;

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.code));
    } on Object {
      // The browser may refuse clipboard access; nothing to confirm.
      return;
    }
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final lines = widget.code.split('\n');
    final long = lines.length > widget.collapsedLines + 3;
    final shown = long && !_expanded
        ? lines.take(widget.collapsedLines).join('\n')
        : widget.code;
    final base = t.typography
        .mono(t.typography.small)
        .copyWith(color: k.text, height: 1.6);
    final radius = Radius.circular(t.radii.card);
    return Container(
      decoration: DsBoxDecoration(
        color: k.sidebar,
        borderRadius: widget.flush
            ? BorderRadius.vertical(bottom: radius)
            : BorderRadius.all(radius),
        shadows: [DsShadow.innerRing(k.border)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A slim bar keeps the copy button off the code at any width.
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 6, 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: k.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(switch (widget.language) {
                    'yaml' => 'YAML',
                    'shell' => 'Shell',
                    _ => 'Dart',
                  }, style: t.typography.caption.copyWith(color: k.textSubtle)),
                ),
                DsTooltip(
                  message: _copied ? 'Copied' : 'Copy code',
                  child: DsButton.icon(
                    variant: .ghost,
                    size: .xs,
                    semanticLabel: _copied ? 'Copied' : 'Copy code',
                    icon: DsIcon(_copied ? DsIcons.check : DsIcons.copy),
                    onPressed: _copy,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            // Code reads left to right in every language.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text.rich(
                TextSpan(
                  style: base,
                  children: highlight(shown, widget.language, k),
                ),
                softWrap: false,
              ),
            ),
          ),
          if (long)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: DsButton(
                variant: .ghost,
                size: .sm,
                trailing: DsIcon(
                  _expanded ? DsIcons.chevronUp : DsIcons.chevronDown,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Show all ${lines.length} lines',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const _keywords = {
  'abstract', 'as', 'async', 'await', 'break', 'case', 'class', 'const', //
  'continue', 'default', 'else', 'enum', 'extends', 'false', 'final', //
  'for', 'get', 'if', 'import', 'in', 'is', 'late', 'mixin', 'new', //
  'null', 'on', 'required', 'return', 'set', 'static', 'super', 'switch', //
  'this', 'true', 'try', 'var', 'void', 'when', 'while', 'with', 'yield',
};

final _dartToken = RegExp(
  r"(//[^\n]*)" // 1 comment
  r"|('(?:[^'\\\n]|\\.)*'|"
  r'"(?:[^"\\\n]|\\.)*")' // 2 string
  r'|(\b\d+(?:\.\d+)?\b)' // 3 number
  r'|(\b[A-Za-z_]\w*\b)(?=\s*:(?!:))' // 4 named argument
  r'|(\b[A-Z]\w*\b)' // 5 type
  r'|(\b[a-z_]\w*\b)', // 6 word
);

final _yamlToken = RegExp(r'(#[^\n]*)|(^\s*[\w_-]+)(?=:)', multiLine: true);

/// Splits [code] into colored spans. Colors come from the theme: comments
/// in the subtle text color, strings in the success ink, keywords in the
/// accent ink, types in the info ink.
List<TextSpan> highlight(String code, String language, DsColors k) {
  final comment = TextStyle(color: k.textSubtle);
  final string = TextStyle(color: k.success.text);
  final keyword = TextStyle(color: k.accentText);
  final type = TextStyle(color: k.info.text);
  final named = TextStyle(color: k.textMuted);
  final number = TextStyle(color: k.warning.text);
  final spans = <TextSpan>[];
  var last = 0;
  void plain(int end) {
    if (end > last) spans.add(TextSpan(text: code.substring(last, end)));
  }

  if (language == 'yaml') {
    for (final m in _yamlToken.allMatches(code)) {
      plain(m.start);
      spans.add(TextSpan(text: m[0], style: m[1] != null ? comment : keyword));
      last = m.end;
    }
    plain(code.length);
    return spans;
  }
  if (language != 'dart') return [TextSpan(text: code)];
  for (final m in _dartToken.allMatches(code)) {
    final TextStyle? style;
    if (m[1] != null) {
      style = comment;
    } else if (m[2] != null) {
      style = string;
    } else if (m[3] != null) {
      style = number;
    } else if (m[4] != null) {
      style = _keywords.contains(m[4]) ? keyword : named;
    } else if (m[5] != null) {
      style = type;
    } else {
      style = _keywords.contains(m[6]) ? keyword : null;
    }
    if (style == null) continue;
    plain(m.start);
    spans.add(TextSpan(text: m[0], style: style));
    last = m.end;
  }
  plain(code.length);
  return spans;
}
