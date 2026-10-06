import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'links.dart';
import 'pages.dart';
import 'registry.dart';

/// The header's search: a field-like button (an icon on phones) that
/// opens the command palette. Ctrl/⌘+K opens it from anywhere.
class SiteSearchButton extends StatefulWidget {
  const SiteSearchButton({super.key, required this.compact});

  /// An icon button instead of the field-like one.
  final bool compact;

  @override
  State<SiteSearchButton> createState() => _SiteSearchButtonState();
}

class _SiteSearchButtonState extends State<SiteSearchButton> {
  bool _open = false;

  @override
  void initState() {
    super.initState();
    // Anywhere on the page, not only below a focused widget.
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyK) {
      return false;
    }
    final keys = HardwareKeyboard.instance;
    if (!keys.isMetaPressed && !keys.isControlPressed) return false;
    _show();
    return true;
  }

  Future<void> _show() async {
    if (_open || !mounted) return;
    _open = true;
    final links = SiteLinks.of(context);
    final path = await showDsModal<String>(
      context: context,
      builder: (_) => const _Palette(),
    );
    _open = false;
    if (path != null) links.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final mac = switch (t.platform) {
      TargetPlatform.macOS || TargetPlatform.iOS => true,
      _ => false,
    };
    if (widget.compact) {
      return DsButton.icon(
        variant: .ghost,
        semanticLabel: 'Search the documentation',
        icon: const DsIcon(DsIcons.search),
        onPressed: _show,
      );
    }
    return DsPressable(
      onPressed: _show,
      semanticLabel: 'Search the documentation',
      builder: (context, states, _) => Container(
        width: 240,
        height: t.sizes.md,
        padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 8, 0),
        decoration: DsBoxDecoration(
          color: states.contains(WidgetState.hovered)
              ? k.controlHover
              : k.field,
          borderRadius: BorderRadius.circular(t.radii.control(t.sizes.md)),
          shadows: [
            DsShadow.innerRing(k.borderControl),
            if (states.contains(WidgetState.focused)) ...t.focusShadows,
          ],
        ),
        child: Row(
          spacing: 8,
          children: [
            DsIcon(DsIcons.search, size: 16, color: k.textSubtle),
            Expanded(
              child: Text(
                'Search docs…',
                style: t.typography.small.copyWith(color: k.textSubtle),
              ),
            ),
            DsShortcut(
              mac ? '⌘K' : 'Ctrl+K',
              textStyle: t.typography.caption.copyWith(color: k.textSubtle),
            ),
          ],
        ),
      ),
    );
  }
}

/// A search box over every page; arrows move, Enter opens, Escape closes.
class _Palette extends StatefulWidget {
  const _Palette();

  @override
  State<_Palette> createState() => _PaletteState();
}

class _PaletteState extends State<_Palette> {
  String _query = '';
  int _active = 0;
  final _scroll = ScrollController();

  static final _all = [
    for (final group in siteGroups)
      for (final page in group.pages) (group, page),
  ];

  List<(SiteGroup, SitePage)> get _results {
    final q = dsFoldCase(_query.trim());
    if (q.isEmpty) return _all;
    bool hit(String s) => dsFoldCase(s).contains(q);
    return [
      for (final r in _all)
        if (hit(r.$2.title) || r.$2.keywords.any(hit)) r,
    ];
  }

  void _move(int by, int count) {
    if (count == 0) return;
    setState(() => _active = (_active + by) % count);
  }

  @override
  void initState() {
    super.initState();
    // Before the text field, which keeps Up, Down and Enter for itself.
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyUpEvent || !mounted) return false;
    final results = _results;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _move(1, results.length);
      case LogicalKeyboardKey.arrowUp:
        _move(-1, results.length);
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter:
        if (event is KeyRepeatEvent || results.isEmpty) return false;
        Navigator.of(context)
            .pop(results[_active.clamp(0, results.length - 1)].$2.path);
      default:
        return false;
    }
    return true;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final results = _results;
    final active = results.isEmpty ? -1 : _active.clamp(0, results.length - 1);
    void open(int i) => Navigator.of(context).pop(results[i].$2.path);
    final width = MediaQuery.sizeOf(context).width;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Search the documentation',
      child: Container(
        width: (width - 32).clamp(0, 560),
        constraints: const BoxConstraints(maxHeight: 460),
        decoration: DsBoxDecoration(
          color: k.overlay,
          borderRadius: BorderRadius.circular(t.radii.overlay),
          shadows: t.shadows.overlay,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: DsSearchField(
                autofocus: true,
                placeholder: 'Search pages',
                onChanged: (q) => setState(() {
                  _query = q;
                  _active = 0;
                }),
              ),
            ),
            Container(height: 1, color: k.border),
            Flexible(
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No page matches “${_query.trim()}”.',
                        textAlign: TextAlign.center,
                        style: t.typography.small.copyWith(color: k.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(6),
                      itemCount: results.length,
                      itemBuilder: (context, i) => _Result(
                        group: results[i].$1.title,
                        title: results[i].$2.title,
                        active: i == active,
                        onPressed: () => open(i),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.group,
    required this.title,
    required this.active,
    required this.onPressed,
  });

  final String group, title;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    if (active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Scrollable.ensureVisible(
            context,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
          Scrollable.ensureVisible(
            context,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          );
        }
      });
    }
    return Semantics(
      selected: active,
      child: DsPressable(
        onPressed: onPressed,
        semanticLabel: '$title, $group',
        builder: (context, states, _) {
          final lit = active || states.contains(WidgetState.hovered);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: DsBoxDecoration(
              color: lit ? k.selection : null,
              borderRadius: BorderRadius.circular(
                t.radii.nested(t.radii.overlay, DsSpace.s6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: t.typography.body.copyWith(
                      color: lit ? k.onSelection : k.text,
                    ),
                  ),
                ),
                Text(
                  group,
                  style: t.typography.small.copyWith(
                    color: lit ? k.onSelection : k.textSubtle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
