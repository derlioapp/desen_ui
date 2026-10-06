import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/helpers.dart';

/// DsFocusRing: the theme's focus ring around a control of your own,
/// shown for keyboard focus only.
void main() {
  final theme = DsThemeData();
  const box = SizedBox(width: 120, height: 40);
  final corners = BorderRadius.circular(12);

  DsBoxDecoration ring(WidgetTester tester) =>
      tester
              .widget<AnimatedContainer>(
                find
                    .descendant(
                      of: find.byType(DsFocusRing),
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .foregroundDecoration!
          as DsBoxDecoration;

  testWidgets('draws nothing while not focused', (tester) async {
    await tester.pumpWidget(
      host(
        DsFocusRing(focused: false, borderRadius: corners, child: box),
        theme: theme,
      ),
    );
    expect(ring(tester).shadows, isEmpty);
    expect(ring(tester).borderRadius, corners);
  });

  testWidgets('focused, draws the theme ring with the given corners', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        DsFocusRing(focused: true, borderRadius: corners, child: box),
        theme: theme,
      ),
    );
    expect(ring(tester).shadows, theme.shadows.focusOffset);
    expect(ring(tester).shadows, theme.focusShadows);
    expect(ring(tester).borderRadius, corners);
    // Above the child: a foreground decoration, no fill.
    expect(ring(tester).color, isNull);
  });

  testWidgets('works without a theme', (tester) async {
    await tester.pumpWidget(host(const DsFocusRing(focused: true, child: box)));
    expect(ring(tester).shadows, DsThemeData().shadows.focusOffset);
    expect(ring(tester).borderRadius, BorderRadius.zero);
  });

  testWidgets('takes another ring, e.g. the tight one of a bordered '
      'control', (tester) async {
    await tester.pumpWidget(
      host(
        DsFocusRing(
          focused: true,
          shadows: theme.shadows.focusTight,
          child: box,
        ),
        theme: theme,
      ),
    );
    expect(ring(tester).shadows, theme.shadows.focusTight);
  });

  testWidgets('hides after a pointer press, shows again on a key press', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const DsFocusRing(focused: true, child: box), theme: theme),
    );
    expect(ring(tester).shadows, isNotEmpty);

    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    expect(ring(tester).shadows, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(ring(tester).shadows, isNotEmpty);
  });

  testWidgets('never changes the layout', (tester) async {
    Future<Size> sizeWith({required bool focused}) async {
      await tester.pumpWidget(
        host(
          DsFocusRing(focused: focused, child: box),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(DsFocusRing));
    }

    expect(await sizeWith(focused: false), const Size(120, 40));
    expect(await sizeWith(focused: true), const Size(120, 40));
  });

  testWidgets('fades in with the tone motion', (tester) async {
    Widget tree(bool focused) => host(
      DsFocusRing(focused: focused, child: box),
      theme: theme,
    );
    await tester.pumpWidget(tree(false));
    await tester.pumpWidget(tree(true));
    final container = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(DsFocusRing),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(container.duration, theme.motion.toneDuration);
    expect(container.curve, theme.motion.toneCurve);
  });

  testWidgets('on DsPressable: Tab shows the ring, a click does not', (
    tester,
  ) async {
    useTraditionalHighlights();
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      host(
        DsPressable(
          focusNode: node,
          onPressed: () {},
          builder: (context, states, _) => DsFocusRing(
            focused: states.contains(WidgetState.focused),
            borderRadius: corners,
            child: box,
          ),
        ),
        theme: theme,
      ),
    );
    await tester.tap(find.byType(DsPressable));
    node.requestFocus();
    await tester.pumpAndSettle();
    expect(ring(tester).shadows, isEmpty, reason: 'focus after a click');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(ring(tester).shadows, theme.focusShadows);
  });
}
