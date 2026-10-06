import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsFieldSurface: the box a text field draws, around content of your own,
/// from the text field's own style layers.
void main() {
  final theme = DsThemeData();
  final k = theme.colors;
  const clear = Color(0x00000000);

  DsBoxDecoration well(WidgetTester tester, [Type of = DsFieldSurface]) =>
      tester
              .widget<AnimatedContainer>(
                find
                    .descendant(
                      of: find.byType(of),
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .decoration!
          as DsBoxDecoration;

  /// The inner edge: the inset ring that paints.
  DsShadow? edge(DsBoxDecoration d) =>
      d.shadows.where((x) => x.inset && x.color.a > 0).firstOrNull;

  Widget surface({
    Set<WidgetState> states = const {},
    bool readOnly = false,
    DsTextFieldStyle? style,
  }) => DsFieldSurface(
    states: states,
    readOnly: readOnly,
    style: style,
    child: const Text('Ocean blue'),
  );

  testWidgets('works without a scope: the text field well', (tester) async {
    await tester.pumpWidget(host(surface()));
    final d = well(tester);
    final t = DsThemeData();
    expect(d.color, t.colors.field);
    expect(edge(d)!.color, t.colors.borderField);
    expect(edge(d)!.spread, 1);
  });

  testWidgets('rounded as a control of its height, at least that tall', (
    tester,
  ) async {
    await tester.pumpWidget(host(surface(), theme: theme));
    final height = theme.sizes.md;
    expect(well(tester).borderRadius, theme.radii.controlCorners(null, height));
    expect(tester.getSize(find.byType(DsFieldSurface)).height, height);

    // A taller box keeps the proportion.
    await tester.pumpWidget(
      host(surface(style: const DsTextFieldStyle(height: 48)), theme: theme),
    );
    expect(well(tester).borderRadius, theme.radii.controlCorners(null, 48));
    expect(tester.getSize(find.byType(DsFieldSurface)).height, 48);
  });

  testWidgets('draws exactly what a text field draws', (tester) async {
    await tester.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [const DsTextField(), surface()],
        ),
        theme: theme,
      ),
    );
    final field = well(tester, DsTextField);
    final box = well(tester);
    expect(box.color, field.color);
    expect(box.borderRadius, field.borderRadius);
    expect(box.shadows, field.shadows);
  });

  testWidgets('focused: a 2px edge in the focus color, kept under the '
      'pointer', (tester) async {
    for (final states in [
      {WidgetState.focused},
      {WidgetState.focused, WidgetState.hovered},
    ]) {
      await tester.pumpWidget(host(surface(states: states), theme: theme));
      final e = edge(well(tester))!;
      expect(e.color, k.focus, reason: '$states');
      expect(e.spread, 2, reason: '$states');
    }
  });

  testWidgets('hovered: the edge strengthens', (tester) async {
    await tester.pumpWidget(
      host(surface(states: {WidgetState.hovered}), theme: theme),
    );
    expect(edge(well(tester))!.color, k.textSubtle);
  });

  testWidgets('error: a 2px danger edge; focus still shows', (tester) async {
    final danger = theme.shadows.fieldError.first.color;
    await tester.pumpWidget(
      host(surface(states: {WidgetState.error}), theme: theme),
    );
    var e = edge(well(tester))!;
    expect(e.color, danger);
    expect(e.spread, 2);

    await tester.pumpWidget(
      host(
        surface(states: {WidgetState.error, WidgetState.focused}),
        theme: theme,
      ),
    );
    e = edge(well(tester))!;
    expect(e.color, k.focus);
    expect(e.spread, 2);
  });

  testWidgets('inside a DsField with an error, shows it without being '
      'told', (tester) async {
    await tester.pumpWidget(
      host(
        DsField(
          label: const Text('Color'),
          errorText: 'Pick a color.',
          child: surface(),
        ),
        theme: theme,
      ),
    );
    expect(edge(well(tester))!.color, theme.shadows.fieldError.first.color);
  });

  testWidgets('disabled: dimmed fill, faint edge, dimmed content', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(surface(states: {WidgetState.disabled}), theme: theme),
    );
    final d = well(tester);
    expect(d.color, k.disabled);
    expect(edge(d)!.color, k.border);
    final text = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Ocean blue'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    expect(text.style.color, k.onDisabled);
  });

  testWidgets('read-only: no fill, a hairline edge; disabled wins', (
    tester,
  ) async {
    await tester.pumpWidget(host(surface(readOnly: true), theme: theme));
    var d = well(tester);
    expect(d.color, clear);
    expect(edge(d)!.color, k.border);
    expect(edge(d)!.spread, 1);

    await tester.pumpWidget(
      host(
        surface(readOnly: true, states: {WidgetState.disabled}),
        theme: theme,
      ),
    );
    d = well(tester);
    expect(d.color, k.disabled);
  });

  testWidgets('content takes the field text and icon look', (tester) async {
    await tester.pumpWidget(
      host(
        DsFieldSurface(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DsIcon(DsIcons.calendar),
              Builder(
                builder: (context) {
                  final icon = IconTheme.of(context);
                  expect(icon.color, k.textMuted);
                  expect(icon.size, DsTextField.defaultStyle(theme).iconSize);
                  return const Text('Today');
                },
              ),
            ],
          ),
        ),
        theme: theme,
      ),
    );
    final text = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Today'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    expect(text.style.color, k.text);
    expect(
      text.style.fontSize,
      DsTextField.defaultStyle(theme).textStyle!.fontSize,
    );
  });

  testWidgets('follows the text field theme; its own style wins', (
    tester,
  ) async {
    const tint = Color(0xFFF2F7FF);
    const ink = Color(0xFF123456);
    await tester.pumpWidget(
      host(
        DsTextFieldTheme(
          data: DsTextFieldThemeData(
            style: DsTextFieldStyle(
              background: tint,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: surface(style: const DsTextFieldStyle(borderColor: ink)),
        ),
        theme: theme,
      ),
    );
    final d = well(tester);
    expect(d.color, tint);
    expect(d.borderRadius, BorderRadius.circular(4));
    expect(edge(d)!.color, ink);
  });

  testWidgets('shrink-wraps its content, holding it at the start', (
    tester,
  ) async {
    await tester.pumpWidget(host(surface(), theme: theme));
    final box = tester.getRect(find.byType(DsFieldSurface));
    final text = tester.getRect(find.text('Ocean blue'));
    final padding = DsTextField.defaultStyle(theme).padding!
        .resolve(TextDirection.ltr);
    expect(box.width, closeTo(text.width + padding.horizontal, .01));
    expect(text.left - box.left, closeTo(padding.left, .01));
    // Vertically centered.
    expect(text.center.dy, closeTo(box.center.dy, .5));
  });

  testWidgets('fills a tight width and keeps the content at the start in '
      'RTL', (tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(width: 300, child: surface()),
        theme: theme,
        direction: TextDirection.rtl,
      ),
    );
    final box = tester.getRect(find.byType(DsFieldSurface));
    final text = tester.getRect(find.text('Ocean blue'));
    expect(box.width, 300);
    final padding = DsTextField.defaultStyle(theme).padding!
        .resolve(TextDirection.rtl);
    expect(box.right - text.right, closeTo(padding.right, .01));
  });

  testWidgets('animates state changes, follows a theme change directly', (
    tester,
  ) async {
    Duration duration() => tester
        .widget<AnimatedContainer>(
          find
              .descendant(
                of: find.byType(DsFieldSurface),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        )
        .duration;
    await tester.pumpWidget(host(surface(), theme: theme));
    expect(duration(), Duration.zero);
    await tester.pumpWidget(
      host(surface(states: {WidgetState.hovered}), theme: theme),
    );
    expect(duration(), theme.motion.toneDuration);
    await tester.pumpWidget(
      host(
        surface(states: {WidgetState.hovered}),
        theme: DsThemeData(brightness: Brightness.dark),
      ),
    );
    expect(duration(), Duration.zero);
  });

  testWidgets('on DsPressable: a field-like trigger', (tester) async {
    useTraditionalHighlights();
    var opened = 0;
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      host(
        DsPressable(
          focusNode: node,
          onPressed: () => opened++,
          builder: (context, states, _) =>
              DsFieldSurface(states: states, child: const Text('Pick')),
        ),
        theme: theme,
      ),
    );
    await tester.tap(find.text('Pick'));
    expect(opened, 1);
    node.requestFocus();
    await tester.pumpAndSettle();
    // A click never shows focus; the keyboard does.
    expect(edge(well(tester))!.color, isNot(k.focus));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(edge(well(tester))!.color, k.focus);
  });
}
