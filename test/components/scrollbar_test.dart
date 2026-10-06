import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final theme = DsThemeData.light();
  final ink = theme.colors.textSubtle;
  const red = Color(0xFFFF0000);

  ScrollbarPainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.byWidgetPredicate(
                  (w) =>
                      w is CustomPaint &&
                      w.foregroundPainter is ScrollbarPainter,
                ),
              )
              .foregroundPainter!
          as ScrollbarPainter;

  RawScrollbar raw(WidgetTester tester) => tester.widget<RawScrollbar>(
    find.byWidgetPredicate((w) => w is RawScrollbar),
  );

  /// A 300 × 200 list ten times taller than its box, with a scrollbar.
  Widget list({
    ScrollController? controller,
    bool? alwaysVisible,
    DsScrollbarStyle? style,
  }) {
    final c = controller ?? ScrollController();
    return SizedBox(
      width: 300,
      height: 200,
      child: DsScrollbar(
        controller: c,
        alwaysVisible: alwaysVisible,
        style: style,
        child: ListView(
          controller: c,
          children: [
            for (var i = 0; i < 100; i++)
              SizedBox(height: 20, child: Text('$i')),
          ],
        ),
      ),
    );
  }

  /// A point on the thumb of [list] at rest: along the end edge, near the
  /// top.
  Offset onThumb(WidgetTester tester) =>
      tester.getTopRight(find.byType(DsScrollbar)) + const Offset(-5, 10);

  testWidgets('a thin, fully rounded thumb in translucent subtle ink', (
    tester,
  ) async {
    await tester.pumpWidget(host(list(alwaysVisible: true), theme: theme));
    await tester.pumpAndSettle();
    final p = painter(tester);
    expect(p.thickness, 6);
    expect(p.radius, const Radius.circular(3));
    expect(p.color, ink.withValues(alpha: .35));
    expect(p.crossAxisMargin, 2);
    expect(p.mainAxisMargin, 2);
    expect(p.trackColor.a, 0);
  });

  testWidgets('the thumb gets stronger under the pointer', (tester) async {
    await tester.pumpWidget(host(list(alwaysVisible: true), theme: theme));
    await tester.pumpAndSettle();
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(onThumb(tester));
    await tester.pumpAndSettle();
    expect(painter(tester).color, ink.withValues(alpha: .55));
    // Off the thumb, back to rest.
    await gesture.moveTo(tester.getCenter(find.byType(DsScrollbar)));
    await tester.pumpAndSettle();
    expect(painter(tester).color, ink.withValues(alpha: .35));
  });

  testWidgets('the thumb is strongest while dragged, and drags the list', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(list(controller: controller, alwaysVisible: true), theme: theme),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      onThumb(tester),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(painter(tester).color, ink.withValues(alpha: .7));
    expect(controller.offset, greaterThan(0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(painter(tester).color, isNot(ink.withValues(alpha: .7)));
  });

  testWidgets('style and theme lay over the defaults, per state', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        DsScrollbarTheme(
          data: const DsScrollbarThemeData(
            style: DsScrollbarStyle(thumbColor: red, thickness: 10),
          ),
          child: list(
            alwaysVisible: true,
            style: const DsScrollbarStyle(
              hovered: DsScrollbarStyle(thickness: 12),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(painter(tester).color, red);
    expect(painter(tester).thickness, 10);
    expect(painter(tester).radius, const Radius.circular(5));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(
      tester.getTopRight(find.byType(DsScrollbar)) + const Offset(-6, 10),
    );
    await tester.pumpAndSettle();
    expect(painter(tester).thickness, 12);
    // A color the theme sets wins over the library's hover color.
    expect(painter(tester).color, red);
  });

  testWidgets('alwaysVisible: the widget, then the theme, then off', (
    tester,
  ) async {
    await tester.pumpWidget(host(list(), theme: theme));
    expect(raw(tester).thumbVisibility, isFalse);
    await tester.pumpWidget(
      host(
        theme: theme,
        DsScrollbarTheme(
          data: const DsScrollbarThemeData(alwaysVisible: true),
          child: list(),
        ),
      ),
    );
    expect(raw(tester).thumbVisibility, isTrue);
    await tester.pumpWidget(
      host(
        theme: theme,
        DsScrollbarTheme(
          data: const DsScrollbarThemeData(alwaysVisible: true),
          child: list(alwaysVisible: false),
        ),
      ),
    );
    expect(raw(tester).thumbVisibility, isFalse);
  });

  testWidgets('works without a DsTheme above', (tester) async {
    await tester.pumpWidget(host(list(alwaysVisible: true)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(painter(tester).thickness, 6);
  });

  group('DsScrollBehavior', () {
    Widget scrolling() => host(
      ScrollConfiguration(
        behavior: const DsScrollBehavior(),
        child: SizedBox(
          height: 200,
          child: ListView(
            children: [
              for (var i = 0; i < 100; i++)
                SizedBox(height: 20, child: Text('$i')),
            ],
          ),
        ),
      ),
    );

    testWidgets(
      'adds a DsScrollbar on desktop',
      (tester) async {
        await tester.pumpWidget(scrolling());
        expect(find.byType(DsScrollbar), findsOneWidget);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      }),
    );

    testWidgets(
      'adds none on phones',
      (tester) async {
        await tester.pumpWidget(scrolling());
        expect(find.byType(DsScrollbar), findsNothing);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.iOS,
        TargetPlatform.android,
      }),
    );

    testWidgets('follows a DsScrollbarTheme', (tester) async {
      await tester.pumpWidget(
        DsScrollbarTheme(
          data: const DsScrollbarThemeData(
            style: DsScrollbarStyle(thumbColor: red),
          ),
          child: scrolling(),
        ),
      );
      // Scroll so the thumb shows.
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pump();
      expect(painter(tester).color, red);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });
}
