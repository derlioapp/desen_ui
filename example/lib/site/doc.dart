import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import 'code.dart';
import 'links.dart';
import 'settings.dart';
import 'snippets.g.dart';

/// Content widths: prose stays readable, examples get more room.
const double kProseWidth = 680;
const double kPageWidth = 880;
const double kWidePageWidth = 1240;

/// A documentation page: title, lead, sections and, on wide windows, an
/// "On this page" list beside them.
class DocPage extends StatefulWidget {
  const DocPage({
    super.key,
    required this.title,
    this.eyebrow,
    this.lead,
    this.sections = const [],
    this.wide = false,
  });

  final String title;

  /// Full app screens: a wider column and no "On this page" list.
  final bool wide;

  /// A small label above the title, e.g. the sidebar group.
  final String? eyebrow;

  /// The opening paragraph; supports the [DocText] markup.
  final String? lead;

  final List<DocSection> sections;

  @override
  State<DocPage> createState() => _DocPageState();
}

class _DocPageState extends State<DocPage> {
  final _scroll = ScrollController();
  late List<GlobalKey> _keys = _makeKeys();

  List<GlobalKey> _makeKeys() => [for (final _ in widget.sections) GlobalKey()];

  @override
  void didUpdateWidget(DocPage old) {
    super.didUpdateWidget(old);
    if (old.sections.length != widget.sections.length) _keys = _makeKeys();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jump(int i) {
    final c = _keys[i].currentContext;
    if (c == null) return;
    Scrollable.ensureVisible(
      c,
      duration: DsTheme.of(context).motion.reduced
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final y = t.typography;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1180;
        final side = constraints.maxWidth < 600 ? 16.0 : 40.0;
        final body = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.wide ? kWidePageWidth : kPageWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.eyebrow case final e?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    e.toUpperCase(),
                    style: y.overline.copyWith(color: k.accentText),
                  ),
                ),
              Semantics(
                header: true,
                child: Text(
                  widget.title,
                  style: y.display.copyWith(color: k.text),
                ),
              ),
              if (widget.lead case final lead?)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kProseWidth),
                    child: DocText(
                      lead,
                      style: y.body.copyWith(
                        fontSize: 17,
                        height: 1.55,
                        color: k.textMuted,
                      ),
                    ),
                  ),
                ),
              for (final (i, s) in widget.sections.indexed)
                KeyedSubtree(key: _keys[i], child: s),
              const SizedBox(height: 96),
            ],
          ),
        );
        return SingleChildScrollView(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(side, 40, side, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: body,
                ),
              ),
              if (wide && !widget.wide && widget.sections.length > 1)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 40),
                  child: SizedBox(
                    width: 200,
                    child: _OnThisPage(
                      titles: [for (final s in widget.sections) s.title],
                      onTap: _jump,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OnThisPage extends StatelessWidget {
  const _OnThisPage({required this.titles, required this.onTap});

  final List<String> titles;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Semantics(
      container: true,
      label: 'On this page',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8, bottom: 6),
            child: Text(
              'ON THIS PAGE',
              style: t.typography.overline.copyWith(color: t.colors.textSubtle),
            ),
          ),
          for (final (i, title) in titles.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: DsLink(
                label: title,
                onPressed: () => onTap(i),
                style: DsLinkStyle(
                  textStyle: t.typography.small,
                  foreground: t.colors.textMuted,
                  underlineWidth: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A titled part of a page.
class DocSection extends StatelessWidget {
  const DocSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: t.typography.title.copyWith(color: t.colors.text),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// A smaller heading inside a section.
class DocHeading extends StatelessWidget {
  const DocHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: t.typography.heading.copyWith(color: t.colors.text),
        ),
      ),
    );
  }
}

/// A paragraph with light markup: `code`, **bold** and [links](/path).
/// Internal links (starting with `/`) open the page on the site.
class DocText extends StatelessWidget {
  const DocText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  static final _markup = RegExp(
    r'`([^`]+)`|\*\*([^*]+)\*\*|\[([^\]]+)\]\(([^)]+)\)',
  );

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final base =
        style ?? t.typography.body.copyWith(color: k.text, height: 1.65);
    final code = t.typography
        .mono(base)
        .copyWith(
          fontSize: (base.fontSize ?? 14) - 1,
          color: k.text,
          backgroundColor: k.neutral.tint,
        );
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _markup.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      if (m[1] != null) {
        spans.add(TextSpan(text: m[1], style: code));
      } else if (m[2] != null) {
        spans.add(
          TextSpan(
            text: m[2],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      } else {
        final target = m[4]!;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: DsLink(
              label: m[3]!,
              url: target.startsWith('/') ? null : Uri.tryParse(target),
              external: !target.startsWith('/'),
              onPressed: () => SiteLinks.of(context).open(target),
              inline: true,
              style: DsLinkStyle(textStyle: base),
            ),
          ),
        );
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kProseWidth),
      child: Text.rich(TextSpan(style: base, children: spans)),
    );
  }
}

/// A bulleted list of [DocText] lines.
class DocList extends StatelessWidget {
  const DocList(this.items, {super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final k = DsTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        for (final item in items)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 9, end: 10),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: DsBoxDecoration(
                    color: k.textSubtle,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Expanded(child: DocText(item)),
            ],
          ),
      ],
    );
  }
}

/// Applies the preview language (strings, formats, direction) to its
/// child, so examples speak the chosen language while the site stays
/// English.
class PreviewScope extends StatelessWidget {
  const PreviewScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final locale = SiteSettingsScope.of(context).settings.previewLocale;
    return Localizations.override(
      context: context,
      locale: locale,
      child: Directionality(
        textDirection: DsWidgetsLocalizations.directionOf(locale),
        child: child,
      ),
    );
  }
}

/// A live example over its source. [snippet] names a `// #region` in the
/// site's sources (see `tool/gen_snippets.py`), so the code shown is the
/// code that runs.
class Example extends StatelessWidget {
  const Example({
    super.key,
    required this.snippet,
    required this.child,
    this.minHeight = 160,
    this.padding = const EdgeInsets.all(32),
    this.alignment = Alignment.center,
    this.showCode = true,
  });

  final String snippet;
  final Widget child;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final bool showCode;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final code = siteSnippets[snippet];
    assert(code != null, 'no snippet "$snippet"; run tool/gen_snippets.py');
    final radius = Radius.circular(t.radii.card);
    final hasCode = showCode && code != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: padding,
          alignment: alignment,
          decoration: DsBoxDecoration(
            color: k.surface,
            borderRadius: hasCode
                ? BorderRadius.vertical(top: radius)
                : BorderRadius.all(radius),
            shadows: [DsShadow.innerRing(k.border)],
          ),
          child: PreviewScope(child: child),
        ),
        if (hasCode) CodeBlock(code, flush: true),
      ],
    );
  }
}

/// Keys and what they do.
class KeyboardTable extends StatelessWidget {
  const KeyboardTable(this.rows, {super.key});

  /// (keys, action) pairs, e.g. ('Space / Enter', 'Presses the button').
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => DocTable(
    columns: const ['Key', 'Action'],
    rows: [
      for (final (keys, action) in rows) [_Keys(keys), DocText(action)],
    ],
  );
}

class _Keys extends StatelessWidget {
  const _Keys(this.keys);

  final String keys;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, part) in keys.split(' / ').indexed) ...[
          if (i > 0)
            Text('or', style: t.typography.small.copyWith(color: k.textSubtle)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: DsBoxDecoration(
              color: k.control,
              borderRadius: BorderRadius.circular(t.radii.control(20)),
              shadows: [DsShadow.innerRing(k.borderControl)],
            ),
            child: Text(
              part,
              style: t.typography
                  .mono(t.typography.small)
                  .copyWith(color: k.text),
            ),
          ),
        ],
      ],
    );
  }
}

/// Parameters worth knowing, with their types.
class ApiTable extends StatelessWidget {
  const ApiTable(this.rows, {super.key});

  /// (name, type, description) triples.
  final List<(String, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final mono = t.typography.mono(t.typography.small);
    return DocTable(
      columns: const ['Parameter', 'Type', 'Description'],
      flex: const [3, 3, 6],
      rows: [
        for (final (name, type, description) in rows)
          [
            Text(name, style: mono.copyWith(color: t.colors.text)),
            Text(type, style: mono.copyWith(color: t.colors.info.text)),
            DocText(description),
          ],
      ],
    );
  }
}

/// A simple table for documentation: header row, hairlines, cells that
/// wrap. On a narrow window each row becomes a stacked card.
class DocTable extends StatelessWidget {
  const DocTable({
    super.key,
    required this.columns,
    required this.rows,
    this.flex,
  });

  final List<String> columns;
  final List<List<Widget>> rows;
  final List<int>? flex;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final head = t.typography.labelStrong.copyWith(color: k.textMuted);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        Widget cell(int i, Widget child) =>
            narrow ? child : Expanded(flex: flex?[i] ?? 1, child: child);
        return Container(
          decoration: DsBoxDecoration(
            color: k.surface,
            borderRadius: BorderRadius.circular(t.radii.card),
            shadows: [DsShadow.innerRing(k.border)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!narrow)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    spacing: 16,
                    children: [
                      for (final (i, c) in columns.indexed)
                        cell(i, Text(c, style: head)),
                    ],
                  ),
                ),
              for (final (r, row) in rows.indexed)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    border: (narrow && r == 0)
                        ? null
                        : Border(top: BorderSide(color: k.border)),
                  ),
                  child: narrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 6,
                          children: [
                            for (final (i, c) in row.indexed)
                              if (i == 0)
                                c
                              else
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 8,
                                  children: [
                                    SizedBox(
                                      width: 88,
                                      child: Text(columns[i], style: head),
                                    ),
                                    Expanded(child: c),
                                  ],
                                ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 16,
                          children: [
                            for (final (i, c) in row.indexed) cell(i, c),
                          ],
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A note set apart from the text.
class Callout extends StatelessWidget {
  const Callout(
    this.text, {
    super.key,
    this.status = DsStatus.info,
    this.title,
  });

  final String text;
  final String? title;
  final DsStatus status;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: kProseWidth),
    child: DsAlert(
      status: status,
      title: Text(title ?? 'Note'),
      description: DocText(text),
    ),
  );
}
