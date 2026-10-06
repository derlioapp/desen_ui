import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Every customization scenario must have one obvious way,
/// in a few lines. These tests are the proof for DsButton.
void main() {
  final t = DsThemeData();
  const green = Color(0xFF1E9E5A);
  const red = Color(0xFFD03030);

  testWidgets('Ö1 · one instance: change the border color', (tester) async {
    await tester.pumpWidget(
      host(
        DsButton(
          variant: .secondary,
          style: const DsButtonStyle(borderColor: green),
          onPressed: () {},
          child: const Text('x'),
        ),
        theme: t,
      ),
    );
    expect(buttonDecoration(tester).shadows.first, const DsShadow.ring(green));
    // Everything else is still the secondary look.
    expect(buttonDecoration(tester).color, t.colors.control);
  });

  testWidgets('Ö2 · every button: default size sm', (tester) async {
    await tester.pumpWidget(
      host(
        DsButtonTheme(
          data: const DsButtonThemeData(size: .sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsButton(onPressed: () {}, child: const Text('a')),
              DsButton(
                variant: .secondary,
                onPressed: () {},
                child: const Text('b'),
              ),
            ],
          ),
        ),
        theme: t,
      ),
    );
    expect(buttonBoxSize(tester, 0).height, 32);
    expect(buttonBoxSize(tester, 1).height, 32);
  });

  testWidgets('Ö3 · one subtree only, merged with the outer theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        DsButtonTheme(
          data: const DsButtonThemeData(variant: .secondary, size: .sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsButton(onPressed: () {}, child: const Text('outside')),
              DsButtonTheme(
                data: const DsButtonThemeData(
                  style: DsButtonStyle(foreground: red),
                ),
                child: DsButton(onPressed: () {}, child: const Text('inside')),
              ),
            ],
          ),
        ),
        theme: t,
      ),
    );
    Color? ink(String label) => tester
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style
        .color;
    expect(ink('outside'), t.colors.text);
    expect(ink('inside'), red);
    // Inner theme kept the outer variant and size.
    expect(buttonDecoration(tester, 1).color, t.colors.control);
    expect(buttonBoxSize(tester, 1).height, 32);
  });

  testWidgets('Ö4 · style one state: a color only while pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        DsButton(
          style: const DsButtonStyle(pressed: DsButtonStyle(background: green)),
          onPressed: () {},
          child: const Text('x'),
        ),
        theme: t,
      ),
    );
    expect(buttonDecoration(tester).color, t.colors.accent);
    final g = await tester.startGesture(
      tester.getCenter(find.byType(DsButton)),
    );
    await tester.pumpAndSettle();
    expect(buttonDecoration(tester).color, green);
    await g.up();
    await tester.pumpAndSettle();
    expect(buttonDecoration(tester).color, t.colors.accent);
  });

  testWidgets('Ö5 · remove a value: no shadow, no border', (tester) async {
    await tester.pumpWidget(
      host(
        DsButton(
          variant: .secondary,
          style: const DsButtonStyle(
            shadows: [],
            borderColor: Color(0x00000000),
          ),
          onPressed: () {},
          child: const Text('x'),
        ),
        theme: t,
      ),
    );
    expect(visibleShadows(buttonDecoration(tester)), isEmpty);
  });

  testWidgets('Ö6 · replace inner parts: icons and the loading indicator', (
    tester,
  ) async {
    const custom = SizedBox(key: Key('my-spinner'), width: 10, height: 10);
    await tester.pumpWidget(
      host(
        DsButtonTheme(
          data: const DsButtonThemeData(loadingIndicator: custom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsButton(
                leading: const Text('←'),
                trailing: const Text('→'),
                onPressed: () {},
                child: const Text('x'),
              ),
              DsButton(loading: true, onPressed: () {}, child: const Text('y')),
            ],
          ),
        ),
        theme: t,
      ),
    );
    expect(find.text('←'), findsOneWidget);
    expect(find.text('→'), findsOneWidget);
    expect(find.byKey(const Key('my-spinner')), findsOneWidget);
    expect(find.byType(DsSpinner), findsNothing);
  });

  testWidgets('Ö7 · a new variant without forking: brand color', (
    tester,
  ) async {
    useTraditionalHighlights();
    final brand = DsButtonStyle.solid(
      background: green,
      foreground: const Color(0xFFFFFFFF),
    );
    await tester.pumpWidget(
      host(
        DsButton(style: brand, onPressed: () {}, child: const Text('x')),
        theme: t,
      ),
    );
    expect(buttonDecoration(tester).color, green);
    await hover(tester, find.byType(DsButton));
    final hovered = buttonDecoration(tester).color!;
    expect(hovered, isNot(green));
    expect(
      DsOklch.fromColor(hovered).l,
      lessThan(DsOklch.fromColor(green).l),
      reason: 'hover darkens in a light theme',
    );
  });

  testWidgets('Ö7b · a custom variant can start from a built-in one', (
    tester,
  ) async {
    final outline = DsButton.defaultStyle(
      t,
      variant: .secondary,
      size: .md,
    ).merge(const DsButtonStyle(background: Color(0x00000000), shadows: []));
    await tester.pumpWidget(
      host(
        DsButton(style: outline, onPressed: () {}, child: const Text('x')),
        theme: t,
      ),
    );
    final d = buttonDecoration(tester);
    expect(d.color, const Color(0x00000000));
    expect(visibleShadows(d), [DsShadow.ring(t.colors.borderControl)]);
  });

  testWidgets('Ö8 · same behavior, completely different look', (tester) async {
    useTraditionalHighlights();
    var taps = 0;
    final seen = <Set<WidgetState>>[];
    await tester.pumpWidget(
      host(
        DsPressable(
          onPressed: () => taps++,
          builder: (context, states, _) {
            seen.add({...states});
            return Container(
              width: 80,
              height: 30,
              color: states.contains(WidgetState.hovered) ? red : green,
            );
          },
        ),
      ),
    );
    await hover(tester, find.byType(DsPressable));
    expect(seen.last, contains(WidgetState.hovered));
    await tester.tap(find.byType(DsPressable));
    expect(taps, 1);
  });

  testWidgets('a base background wins over the default hover color', (
    tester,
  ) async {
    useTraditionalHighlights();
    await tester.pumpWidget(
      host(
        DsButton(
          style: const DsButtonStyle(background: red),
          onPressed: () {},
          child: const Text('x'),
        ),
        theme: t,
      ),
    );
    await hover(tester, find.byType(DsButton));
    expect(buttonDecoration(tester).color, red);
  });

  test('state styles stack in a fixed order, not in writing order', () {
    const a = DsButtonStyle(
      disabled: DsButtonStyle(background: red),
      hovered: DsButtonStyle(background: green),
    );
    final s = a.resolve({WidgetState.hovered, WidgetState.disabled});
    expect(s.background, red, reason: 'disabled outranks hovered');
  });

  test('merge keeps unset fields and merges text styles', () {
    const a = DsButtonStyle(
      background: red,
      textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
    const b = DsButtonStyle(textStyle: TextStyle(fontSize: 16));
    final m = a.merge(b);
    expect(m.background, red);
    expect(m.textStyle!.fontSize, 16);
    expect(m.textStyle!.fontWeight, FontWeight.w600);
  });
}
