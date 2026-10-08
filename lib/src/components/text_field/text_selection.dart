import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/edge_fade_scroll.dart';
import '../../behavior/pressable.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/line.dart';
import '../../painting/surface.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../menu/menu.dart';
import 'text_selection_toolbar_style.dart';

/// Desen's selection handles: the knobs a touch user drags to change a
/// selection, painted in the caret color.
///
/// On iOS (and macOS) they are Apple's lollipops: a stem as tall as the
/// line with a round knob above the start and below the end, and no
/// handle under a collapsed caret. Elsewhere (Android, and Windows and
/// Linux touch screens) they are teardrops hanging below the line, one
/// under a collapsed caret too.
///
/// The edit menu is not built here: Desen's fields pass a
/// `contextMenuBuilder`, so [buildToolbar] is unused
/// ([TextSelectionHandleControls]). The framework widens each handle's
/// hit area to at least 48×48 around the knob, above the 44 touch target.
class DsTextSelectionControls extends TextSelectionControls
    with TextSelectionHandleControls {
  /// Creates handles of [color]: knobs of [size] and, on Apple platforms,
  /// stems of [stemWidth].
  DsTextSelectionControls({
    required this.color,
    required this.size,
    required this.stemWidth,
    this.platform,
  });

  /// Fill of the knobs and stems.
  final Color color;

  /// Diameter of a knob (the teardrop's width on Android).
  final double size;

  /// Width of the lollipop stem, usually the caret width.
  final double stemWidth;

  /// Picks the handle shape; [defaultTargetPlatform] when null.
  final TargetPlatform? platform;

  bool get _apple => switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => true,
    _ => false,
  };

  @override
  Size getHandleSize(double textLineHeight) =>
      _apple ? Size(size, textLineHeight + size) : Size.square(size);

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    final box = getHandleSize(textLineHeight);
    if (_apple) {
      return switch (type) {
        // Knob on top: the stem ends at the bottom of the line.
        TextSelectionHandleType.left => Offset(box.width / 2, box.height),
        // Turned over: the stem starts at the top of the line.
        TextSelectionHandleType.right => Offset(box.width / 2, size),
        TextSelectionHandleType.collapsed => Offset(
          box.width / 2,
          textLineHeight + size / 2,
        ),
      };
    }
    return switch (type) {
      // The point of the turned teardrop meets the bottom of the line;
      // its tip lies (√2 − 1)·r above the box, measured from its center.
      TextSelectionHandleType.collapsed => Offset(
        size / 2,
        -(math.sqrt2 - 1) * size / 2,
      ),
      TextSelectionHandleType.left => Offset(size, 0),
      TextSelectionHandleType.right => Offset.zero,
    };
  }

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    final box = getHandleSize(textLineHeight);
    if (_apple) {
      // Apple shows no handle under a caret; an empty box still takes the
      // drag that moves it.
      if (type == TextSelectionHandleType.collapsed) {
        return SizedBox.fromSize(size: box);
      }
      return SizedBox.fromSize(
        size: box,
        child: CustomPaint(
          painter: _LollipopPainter(
            color: color,
            knob: size,
            stem: stemWidth,
            knobOnTop: type == TextSelectionHandleType.left,
          ),
        ),
      );
    }
    Widget handle = SizedBox.fromSize(
      size: box,
      child: CustomPaint(
        painter: _TeardropPainter(color),
        child: onTap == null
            ? null
            : GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onTap,
              ),
      ),
    );
    // The square corner points up-left; turn it to point at the text.
    final angle = switch (type) {
      TextSelectionHandleType.left => math.pi / 2,
      TextSelectionHandleType.right => 0.0,
      TextSelectionHandleType.collapsed => math.pi / 4,
    };
    if (angle != 0) handle = Transform.rotate(angle: angle, child: handle);
    return handle;
  }

  @override
  bool operator ==(Object other) =>
      other is DsTextSelectionControls &&
      other.color == color &&
      other.size == size &&
      other.stemWidth == stemWidth &&
      other.platform == platform;

  @override
  int get hashCode => Object.hash(color, size, stemWidth, platform);
}

class _LollipopPainter extends CustomPainter {
  _LollipopPainter({
    required this.color,
    required this.knob,
    required this.stem,
    required this.knobOnTop,
  });

  final Color color;
  final double knob, stem;
  final bool knobOnTop;

  @override
  void paint(Canvas canvas, Size size) {
    final r = knob / 2;
    final cx = size.width / 2;
    final knobCenter = Offset(cx, knobOnTop ? r : size.height - r);
    final stemRect = knobOnTop
        ? Rect.fromLTRB(cx - stem / 2, r, cx + stem / 2, size.height)
        : Rect.fromLTRB(cx - stem / 2, 0, cx + stem / 2, size.height - r);
    final paint = Paint()..color = color;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(stemRect, Radius.circular(stem / 2)),
        paint,
      )
      ..drawCircle(knobCenter, r, paint);
  }

  @override
  bool shouldRepaint(_LollipopPainter old) =>
      old.color != color ||
      old.knob != knob ||
      old.stem != stem ||
      old.knobOnTop != knobOnTop;
}

/// A circle with its top-left quadrant squared off: the corner is the
/// point that touches the text.
class _TeardropPainter extends CustomPainter {
  _TeardropPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r))
      ..addRect(Rect.fromLTWH(0, 0, r, r));
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TeardropPainter old) => old.color != color;
}

/// The localized label of an edit menu item, never empty: Desen's own
/// words for the platform's actions, the item's label for an app's own
/// action (custom and process-text items), and a generic "Action" for one
/// that came without a label.
String dsContextMenuLabel(DsLocalizations l10n, ContextMenuButtonItem item) =>
    switch (item.type) {
      ContextMenuButtonType.cut => l10n.cut,
      ContextMenuButtonType.copy => l10n.copy,
      ContextMenuButtonType.paste => l10n.paste,
      ContextMenuButtonType.selectAll => l10n.selectAll,
      ContextMenuButtonType.delete => l10n.delete,
      ContextMenuButtonType.lookUp => l10n.lookUp,
      ContextMenuButtonType.searchWeb => l10n.searchWeb,
      ContextMenuButtonType.share => l10n.share,
      ContextMenuButtonType.liveTextInput => l10n.scanText,
      ContextMenuButtonType.custom =>
        (item.label?.trim().isNotEmpty ?? false)
            ? item.label!
            : l10n.editAction,
    };

/// The floating edit toolbar of touch screens: a pill on the floating
/// surface with a text button per action, above the selection, or below
/// it when there is no room above.
///
/// Android and iOS without the native edit menu use it, and so does a
/// touch screen on desktop. [anchors] and [buttonItems] usually come from
/// the [EditableTextState] (`contextMenuAnchors`, `contextMenuButtonItems`)
/// in a `contextMenuBuilder`, so the actions match the platform. Buttons
/// are [style]d `height` tall, the tap height (44 by default). When the
/// window is too narrow for every action, they split into pages, as on
/// iOS: a chevron at the end shows the next page, one at the start the
/// previous, and no action is cut.
class DsTextSelectionToolbar extends StatelessWidget {
  /// Creates the toolbar.
  const DsTextSelectionToolbar({
    super.key,
    required this.anchors,
    required this.buttonItems,
    this.style,
    this.semanticLabel,
  });

  /// Where the selection is: the toolbar goes above the primary anchor,
  /// or below the secondary one.
  final TextSelectionToolbarAnchors anchors;

  /// The actions, in order.
  final List<ContextMenuButtonItem> buttonItems;

  /// Style laid over the theme and defaults.
  final DsTextSelectionToolbarStyle? style;

  /// Names the toolbar for screen readers, e.g. "Spelling suggestions";
  /// none by default, where the buttons say what it is.
  final String? semanticLabel;

  /// Desen's default toolbar style under [theme].
  static DsTextSelectionToolbarStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsTextSelectionToolbarStyle(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: DsSpace.s4),
      background: k.overlay,
      shadows: theme.shadows.overlay,
      borderRadius: BorderRadius.circular(theme.radii.overlay),
      itemPadding: const EdgeInsets.symmetric(horizontal: DsSpace.s12),
      itemBackground: const Color(0x00000000),
      // Concentric with the bar, inset by its padding.
      itemBorderRadius: BorderRadius.circular(
        theme.radii.nested(theme.radii.overlay, DsSpace.s4),
      ),
      foreground: k.text,
      textStyle: theme.typography.body.copyWith(fontWeight: FontWeight.w500),
      dividerColor: k.border,
      margin: DsSpace.s8,
      pressed: DsTextSelectionToolbarStyle(itemBackground: k.press),
      disabled: DsTextSelectionToolbarStyle(foreground: k.onDisabled),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (buttonItems.isEmpty) return const SizedBox.shrink();
    final t = dsThemeOf(context);
    final l10n = DsLocalizations.of(context);
    final layers = [
      defaultStyle(t),
      DsTextSelectionToolbarTheme.of(context).style,
      style,
    ];
    final s = DsTextSelectionToolbarStyle.resolveLayers(layers, const {});
    final margin = s.margin!;
    final height = s.height!;
    final paddingAbove = MediaQuery.paddingOf(context).top + margin;
    final above = anchors.primaryAnchor;
    final below = anchors.secondaryAnchor ?? above;
    // Room for the toolbar between the selection and the top inset.
    final fitsAbove = height + margin <= above.dy - paddingAbove;
    final local = Offset(margin, paddingAbove);

    final labels = [
      for (final item in buttonItems) dsContextMenuLabel(l10n, item),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(margin, paddingAbove, margin, margin),
      child: CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove: above - local - Offset(0, margin),
          anchorBelow: below - local + Offset(0, margin),
          fitsAbove: fitsAbove,
        ),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: semanticLabel,
          child: DsSurface(
            decoration: DsBoxDecoration(
              color: s.background,
              borderRadius: s.borderRadius ?? BorderRadius.zero,
              shadows: s.shadows ?? const [],
            ),
            backdropFilter: s.backdropFilter,
            child: Padding(
              padding: s.padding ?? EdgeInsets.zero,
              child: _ToolbarPages(
                labels: labels,
                actions: [for (final item in buttonItems) item.onPressed],
                layers: layers,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The toolbar's buttons, split into pages when the width does not hold
/// them all: each page but the last ends in a chevron to the next, each
/// but the first starts with one back.
class _ToolbarPages extends StatefulWidget {
  const _ToolbarPages({
    required this.labels,
    required this.actions,
    required this.layers,
  });

  final List<String> labels;
  final List<VoidCallback?> actions;
  final List<DsTextSelectionToolbarStyle?> layers;

  @override
  State<_ToolbarPages> createState() => _ToolbarPagesState();
}

class _ToolbarPagesState extends State<_ToolbarPages> {
  int _page = 0;

  @override
  void didUpdateWidget(_ToolbarPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New actions start over on the first page.
    if (!listEquals(oldWidget.labels, widget.labels)) _page = 0;
  }

  /// The first item of each page, for [widths] in [room], with [chevron]
  /// wide page buttons and [divider] wide lines between buttons.
  static List<int> _pageStarts(
    List<double> widths,
    double room,
    double chevron,
    double divider,
  ) {
    final n = widths.length;
    double run(int from, int to) {
      var w = 0.0;
      for (var i = from; i < to; i++) {
        w += widths[i] + (i > from ? divider : 0);
      }
      return w;
    }

    if (!room.isFinite || run(0, n) <= room) return const [0];
    final starts = <int>[];
    var i = 0;
    while (i < n) {
      starts.add(i);
      final back = starts.length > 1 ? chevron + divider : 0.0;
      // The rest fits without a next button: the last page.
      if (back + run(i, n) <= room) break;
      var end = i + 1; // at least one action a page
      while (end < n && back + run(i, end + 1) + divider + chevron <= room) {
        end++;
      }
      i = end;
    }
    return starts;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final s = DsTextSelectionToolbarStyle.resolveLayers(
        widget.layers,
        const {},
      );
      final l10n = DsLocalizations.of(context);
      final scaler = MediaQuery.textScalerOf(context);
      final textStyle = DefaultTextStyle.of(context).style.merge(s.textStyle);
      final padding = (s.itemPadding ?? EdgeInsets.zero).horizontal;
      double measure(String label) {
        final painter = TextPainter(
          text: TextSpan(text: label, style: textStyle),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final width = painter.width.ceilToDouble();
        painter.dispose();
        return width + padding;
      }

      // A chevron is as tall as the text.
      final chevronSize = scaler.scale(
        textStyle.fontSize ?? dsThemeOf(context).typography.body.fontSize!,
      );
      final widths = [for (final label in widget.labels) measure(label)];
      // ds-raw: a divider is one logical pixel wide (DsLine)
      const divider = 1.0;
      final starts = _pageStarts(
        widths,
        constraints.maxWidth,
        chevronSize + padding,
        divider,
      );
      final page = _page.clamp(0, starts.length - 1);
      final from = starts[page];
      final to = page + 1 < starts.length
          ? starts[page + 1]
          : widget.labels.length;

      Widget line() => SizedBox(
        height: s.height! / 2,
        child: DsLine(color: s.dividerColor!, axis: Axis.vertical),
      );
      // The chevrons mirror themselves in right-to-left text.
      Widget chevron({required bool next}) => _ToolbarButton(
        icon: DsIcon(
          next ? DsIcons.chevronRight : DsIcons.chevronLeft,
          size: chevronSize,
        ),
        label: next ? l10n.nextPage : l10n.previousPage,
        onPressed: () => setState(() => _page = page + (next ? 1 : -1)),
        layers: widget.layers,
      );

      final children = <Widget>[
        if (page > 0) ...[chevron(next: false), line()],
        for (var i = from; i < to; i++) ...[
          if (i > from) line(),
          _ToolbarButton(
            label: widget.labels[i],
            onPressed: widget.actions[i],
            layers: widget.layers,
          ),
        ],
        if (page + 1 < starts.length) ...[line(), chevron(next: true)],
      ];
      // A single action wider than the window still scrolls rather than
      // overflow.
      return DsEdgeFadeScrollView(
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      );
    },
  );
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.onPressed,
    required this.layers,
    this.icon,
  });

  /// The button's text, or with [icon] its name for screen readers.
  final String label;
  final VoidCallback? onPressed;
  final List<DsTextSelectionToolbarStyle?> layers;

  /// Shown instead of the label.
  final Widget? icon;

  @override
  Widget build(BuildContext context) => DsPressable(
    onPressed: onPressed,
    semanticLabel: icon == null ? null : label,
    // The button is the tap height itself.
    minTapTarget: 0,
    builder: (context, states, _) {
      final s = DsTextSelectionToolbarStyle.resolveLayers(layers, states);
      return Container(
        constraints: BoxConstraints(minHeight: s.height!),
        padding: s.itemPadding,
        decoration: DsBoxDecoration(
          color: s.itemBackground,
          borderRadius: s.itemBorderRadius ?? BorderRadius.zero,
        ),
        // Shrink-wrapped and centered in the minimum height: a Container
        // alignment would fill the loose height the toolbar's layout
        // passes, and the buttons would cover the selection handles.
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: switch (icon) {
            final icon? => IconTheme.merge(
              data: IconThemeData(color: s.foreground),
              child: ExcludeSemantics(child: icon),
            ),
            null => Text(
              label,
              maxLines: 1,
              style: (s.textStyle ?? const TextStyle()).copyWith(
                color: s.foreground,
              ),
            ),
          },
        ),
      );
    },
  );
}

/// The replacements for a misspelled word, shown when the user taps a word
/// the spell checker flagged: up to [maxSuggestions] suggestions in
/// Desen's touch toolbar ([DsTextSelectionToolbar]), so it looks like the
/// edit menu.
///
/// Choosing a suggestion replaces the word, puts the caret after it and
/// closes the toolbar. The actions follow the platform: on iOS (and
/// macOS) a word without suggestions shows a disabled "No replacements
/// found"; elsewhere a Delete action follows the suggestions and removes
/// the word, as on Android.
///
/// Screen readers hear the toolbar named "Spelling suggestions" and each
/// suggestion as a button. The suggestions take keyboard focus (Enter or
/// Space picks one) while the field keeps its own, so the toolbar stays
/// open. Escape, or a tap outside the field and the toolbar, closes it;
/// focus goes back to the field.
///
/// [DsTextField] shows it by itself. For an [EditableText] of your own,
/// return it from the `spellCheckSuggestionsToolbarBuilder` of its
/// [SpellCheckConfiguration].
class DsSpellCheckSuggestionsToolbar extends StatelessWidget {
  /// Creates the toolbar for the misspelled word at the selection of
  /// [editableTextState].
  const DsSpellCheckSuggestionsToolbar({
    super.key,
    required this.editableTextState,
    this.style,
  });

  /// The most suggestions shown, as on iOS and Android.
  static const maxSuggestions = 3;

  /// The field whose word is replaced; its spell check results give the
  /// suggestions and its context menu anchors place the toolbar.
  final EditableTextState editableTextState;

  /// Style laid over the toolbar theme and defaults.
  final DsTextSelectionToolbarStyle? style;

  static bool get _apple => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => true,
    _ => false,
  };

  /// The actions for the flagged word at the selection, or null when the
  /// selection is not on one.
  List<ContextMenuButtonItem>? _items(DsLocalizations l10n) {
    final state = editableTextState;
    final span = state.findSuggestionSpanAtCursorIndex(
      state.currentTextEditingValue.selection.baseOffset,
    );
    if (span == null) return null;
    final suggestions = span.suggestions.take(maxSuggestions).toList();
    return [
      for (final suggestion in suggestions)
        ContextMenuButtonItem(
          label: suggestion,
          onPressed: () => _replace(span.range, suggestion),
        ),
      if (_apple && suggestions.isEmpty)
        ContextMenuButtonItem(
          label: l10n.noSpellingSuggestions,
          onPressed: null,
        ),
      if (!_apple)
        ContextMenuButtonItem(
          type: ContextMenuButtonType.delete,
          onPressed: () => _replace(span.range, ''),
        ),
    ];
  }

  /// Gives focus back to the field when the toolbar holds it, so it does
  /// not fall to the root as the toolbar goes away.
  void _refocusField() {
    final node = editableTextState.widget.focusNode;
    if (!node.hasPrimaryFocus) node.requestFocus();
  }

  void _close() {
    if (!editableTextState.mounted) return;
    _refocusField();
    editableTextState.hideToolbar(false);
  }

  /// Puts [text] in place of [range] with the caret after it, as the
  /// user's own edit (so `onChanged` hears it), and closes the toolbar.
  void _replace(TextRange range, String text) {
    final state = editableTextState;
    if (!state.mounted) return;
    _refocusField();
    final value = state.textEditingValue
        .replaced(range, text)
        .copyWith(
          selection: TextSelection.collapsed(offset: range.start + text.length),
        );
    state.userUpdateTextEditingValue(value, SelectionChangedCause.toolbar);
    // The renderer has the new text after the next layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mounted) {
        state.bringIntoView(state.textEditingValue.selection.extent);
      }
    });
    state.hideToolbar();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DsLocalizations.of(context);
    final items = _items(l10n);
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return TapRegion(
      // Taps on the field are its own (another word, the caret); only a
      // tap outside both closes the toolbar.
      groupId: EditableText,
      onTapOutside: (_) => _close(),
      child: Focus(
        // The suggestions' focus sits under the field's, so focusing one
        // keeps the field focused and the toolbar open.
        parentNode: editableTextState.widget.focusNode,
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _close();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: FocusTraversalGroup(
          child: DsTextSelectionToolbar(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: items,
            style: style,
            semanticLabel: l10n.spellingSuggestions,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}

/// The keyboard shortcut hint of a standard edit action on the current
/// platform ("⌘X" on Apple platforms, "Ctrl+X" elsewhere), or null.
String? dsEditShortcut(ContextMenuButtonType type, {TargetPlatform? platform}) {
  final apple = switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => true,
    _ => false,
  };
  final key = switch (type) {
    ContextMenuButtonType.cut => 'X',
    ContextMenuButtonType.copy => 'C',
    ContextMenuButtonType.paste => 'V',
    ContextMenuButtonType.selectAll => 'A',
    _ => null,
  };
  if (key == null) return null;
  return apple ? '⌘$key' : 'Ctrl+$key';
}

/// The desktop edit menu of a text field, opened by a right click or
/// Shift+F10 where the user asked for it: Cut, Copy, Paste and (except on
/// macOS, whose menus have none) Select all with their shortcuts, then any further actions the platform or the app
/// adds. An action that cannot run now (nothing selected to copy, a
/// read-only field to cut from, an empty clipboard) is shown disabled
/// rather than left out, as desktop menus do.
///
/// [buttonItems] usually come from
/// [EditableTextState.contextMenuButtonItems], so what is enabled always
/// matches the field.
class DsTextContextMenu extends StatelessWidget {
  /// Creates the menu.
  const DsTextContextMenu({
    super.key,
    required this.buttonItems,
    this.onDone,
    this.autofocus = true,
  });

  /// The actions the field offers now.
  final List<ContextMenuButtonItem> buttonItems;

  /// Closes the layer the menu sits in.
  final VoidCallback? onDone;

  /// Whether the first enabled item takes focus when the menu opens.
  final bool autofocus;

  /// The standard actions, always listed: macOS has no Select all in
  /// its edit menu (Flutter offers none there either).
  static List<ContextMenuButtonType> get _standard => [
    ContextMenuButtonType.cut,
    ContextMenuButtonType.copy,
    ContextMenuButtonType.paste,
    if (defaultTargetPlatform != TargetPlatform.macOS)
      ContextMenuButtonType.selectAll,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = DsLocalizations.of(context);
    ContextMenuButtonItem? find(ContextMenuButtonType type) =>
        buttonItems.where((i) => i.type == type).firstOrNull;
    final standard = _standard;
    final extra = [
      for (final item in buttonItems)
        if (!standard.contains(item.type) &&
            item.type != ContextMenuButtonType.selectAll)
          item,
    ];
    return DsMenu(
      autofocus: autofocus,
      onDone: onDone,
      children: [
        for (final type in standard)
          DsMenuItem(
            label: Text(
              dsContextMenuLabel(
                l10n,
                ContextMenuButtonItem(type: type, onPressed: null),
              ),
            ),
            shortcut: dsEditShortcut(type),
            onPressed: find(type)?.onPressed,
          ),
        if (extra.isNotEmpty) const DsMenuDivider(),
        for (final item in extra)
          DsMenuItem(
            label: Text(dsContextMenuLabel(l10n, item)),
            onPressed: item.onPressed,
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty('buttonItems', buttonItems));
  }
}
