import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The touch loupe of DsTextField: shown on iOS and Android while a handle
/// is dragged or a long press selects, never on desktop.
void main() {
  const text = 'hello brave world';

  Widget app(Widget child) => DsApp(
    theme: DsThemeData(),
    themeMode: DsThemeMode.light,
    home: Center(child: SizedBox(width: 320, child: child)),
  );

  RenderEditable renderEditable(WidgetTester tester) => tester
      .state<EditableTextState>(
        find.byWidgetPredicate((w) => w is EditableText),
      )
      .renderEditable;

  /// The global position of the text offset [offset] in the field.
  Offset textOffset(WidgetTester tester, int offset) {
    final render = renderEditable(tester);
    final caret = render.getLocalRectForCaret(TextPosition(offset: offset));
    return render.localToGlobal(caret.center);
  }

  Finder loupe() => find.byType(DsTextMagnifier);

  /// Holds a long press at [offset] (past the double-tap window after a
  /// focusing tap) and returns the held gesture.
  Future<TestGesture> holdLongPress(WidgetTester tester, int offset) async {
    await tester.tapAt(textOffset(tester, offset));
    await tester.pump(const Duration(milliseconds: 500));
    final gesture = await tester.startGesture(textOffset(tester, offset));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pump();
    return gesture;
  }

  testWidgets(
    'a long press shows the loupe, which follows the finger and goes on '
    'release',
    (tester) async {
      await tester.pumpWidget(app(const DsTextField(initialValue: text)));
      final gesture = await holdLongPress(tester, 8);
      expect(loupe(), findsOneWidget);
      expect(find.byType(RawMagnifier), findsOneWidget);

      final before = tester.getCenter(find.byType(RawMagnifier));
      await gesture.moveTo(textOffset(tester, 14));
      await tester.pump(const Duration(seconds: 1));
      final after = tester.getCenter(find.byType(RawMagnifier));
      expect(after.dx, greaterThan(before.dx));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(loupe(), findsNothing);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );

  testWidgets('dragging a selection handle shows the loupe on iOS', (
    tester,
  ) async {
    await tester.pumpWidget(app(const DsTextField(initialValue: text)));
    await tester.longPressAt(textOffset(tester, 8));
    await tester.pumpAndSettle();
    final selection = tester
        .state<EditableTextState>(
          find.byWidgetPredicate((w) => w is EditableText),
        )
        .textEditingValue
        .selection;
    expect((selection.start, selection.end), (6, 11));
    expect(loupe(), findsNothing);

    // The end handle is the lollipop further right.
    final handles = find
        .byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_LollipopPainter',
        )
        .evaluate()
        .map((e) => tester.getCenter(find.byWidget(e.widget)))
        .toList();
    expect(handles, hasLength(2));
    final end = handles.reduce((a, b) => a.dx > b.dx ? a : b);
    final gesture = await tester.startGesture(end);
    await gesture.moveTo(textOffset(tester, text.length - 2));
    await tester.pump();
    expect(loupe(), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(loupe(), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('desktop shows no loupe', (tester) async {
    await tester.pumpWidget(app(const DsTextField(initialValue: text)));
    final gesture = await holdLongPress(tester, 8);
    await gesture.moveTo(textOffset(tester, 14));
    await tester.pump();
    expect(loupe(), findsNothing);
    expect(find.byType(RawMagnifier), findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();

    // The configuration builds nothing here at all.
    final built = DsTextMagnifier.configuration.magnifierBuilder(
      tester.element(find.byType(DsTextField)),
      MagnifierController(),
      ValueNotifier(MagnifierInfo.empty),
    );
    expect(built, isNull);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('floats its lift above the line, at the style size', (
    tester,
  ) async {
    await tester.pumpWidget(app(const DsTextField(initialValue: text)));
    final gesture = await holdLongPress(tester, 8);
    // Past the entrance: full size and opacity.
    await tester.pump(const Duration(seconds: 1));
    final style = DsTextMagnifier.defaultStyle(DsThemeData());
    final rect = tester.getRect(find.byType(RawMagnifier));
    expect(rect.size, Size(style.width!, style.height!));
    final line = textOffset(tester, 8).dy;
    expect(rect.bottom, moreOrLessEquals(line - style.lift!, epsilon: 0.5));
    final magnifier = tester.widget<RawMagnifier>(find.byType(RawMagnifier));
    expect(magnifier.magnificationScale, style.magnification);
    await gesture.up();
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('takes its style from a DsTextMagnifierTheme around the field', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const DsTextMagnifierTheme(
          data: DsTextMagnifierThemeData(
            style: DsTextMagnifierStyle(magnification: 1.5, width: 96),
          ),
          child: DsTextField(initialValue: text),
        ),
      ),
    );
    final gesture = await holdLongPress(tester, 8);
    await tester.pump(const Duration(seconds: 1));
    final magnifier = tester.widget<RawMagnifier>(find.byType(RawMagnifier));
    expect(magnifier.magnificationScale, 1.5);
    expect(tester.getSize(find.byType(RawMagnifier)).width, 96);
    await gesture.up();
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('a disabled field shows no loupe', (tester) async {
    await tester.pumpWidget(
      app(const DsTextField(initialValue: text, enabled: false)),
    );
    final gesture = await tester.startGesture(textOffset(tester, 8));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pump();
    expect(loupe(), findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  group('exit', () {
    /// The loupe's opacity, from its fade.
    double opacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find.descendant(of: loupe(), matching: find.byType(Opacity)).first,
        )
        .opacity;

    /// The loupe's scale, from its grow and shrink.
    double scale(WidgetTester tester) => tester
        .widget<Transform>(
          find.descendant(of: loupe(), matching: find.byType(Transform)).first,
        )
        .transform
        .storage[0]; // the x scale; the z scale of a 2D scale stays 1

    testWidgets(
      'on release the loupe fades and shrinks away before it goes',
      (tester) async {
        await tester.pumpWidget(app(const DsTextField(initialValue: text)));
        final gesture = await holdLongPress(tester, 8);
        await tester.pump(const Duration(seconds: 1));
        expect(opacity(tester), 1);
        expect(scale(tester), moreOrLessEquals(1));

        await gesture.up();
        await tester.pump();
        final exit = DsThemeData().motion.toneDuration;
        await tester.pump(exit ~/ 2);
        expect(loupe(), findsOneWidget, reason: 'still on its way out');
        expect(opacity(tester), inExclusiveRange(0, 1));
        expect(scale(tester), lessThan(1));

        await tester.pumpAndSettle();
        expect(loupe(), findsNothing);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.iOS,
        TargetPlatform.android,
      }),
    );

    testWidgets('with reduced motion it only fades', (tester) async {
      // The scope takes reduced motion from the platform, not the theme.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.pumpWidget(
        DsApp(
          theme: DsThemeData(),
          themeMode: DsThemeMode.light,
          home: const Center(
            child: SizedBox(width: 320, child: DsTextField(initialValue: text)),
          ),
        ),
      );
      final gesture = await holdLongPress(tester, 8);
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pump();
      await tester.pump(DsThemeData().motion.toneDuration ~/ 2);
      expect(loupe(), findsOneWidget);
      expect(opacity(tester), inExclusiveRange(0, 1));
      expect(scale(tester), moreOrLessEquals(1));
      await tester.pumpAndSettle();
      expect(loupe(), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('the controller drives the exit and gets its animation back '
        'when the loupe goes', (tester) async {
      const anchor = Key('anchor');
      await tester.pumpWidget(app(const SizedBox(key: anchor)));
      final controller = MagnifierController();
      final info = ValueNotifier(
        const MagnifierInfo(
          globalGesturePosition: Offset(160, 300),
          caretRect: Rect.fromLTWH(160, 290, 2, 20),
          fieldBounds: Rect.fromLTWH(0, 280, 320, 40),
          currentLineBoundaries: Rect.fromLTWH(0, 290, 320, 20),
        ),
      );
      addTearDown(info.dispose);
      final context = tester.element(find.byKey(anchor));
      await controller.show(
        context: context,
        builder: (_) =>
            DsTextMagnifier(magnifierInfo: info, controller: controller),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(loupe(), findsOneWidget);
      expect(controller.animationController, isNotNull);
      expect(controller.shown, isTrue);

      final hidden = controller.hide();
      await tester.pump();
      await tester.pump(DsThemeData().motion.toneDuration ~/ 2);
      expect(loupe(), findsOneWidget);
      expect(controller.shown, isFalse, reason: 'on its way out');

      await tester.pumpAndSettle();
      await hidden;
      expect(loupe(), findsNothing);
      expect(controller.overlayEntry, isNull);
      expect(controller.animationController, isNull);
    });

    testWidgets('without a controller it still shows', (tester) async {
      final info = ValueNotifier(
        const MagnifierInfo(
          globalGesturePosition: Offset(160, 300),
          caretRect: Rect.fromLTWH(160, 290, 2, 20),
          fieldBounds: Rect.fromLTWH(0, 280, 320, 40),
          currentLineBoundaries: Rect.fromLTWH(0, 290, 320, 20),
        ),
      );
      addTearDown(info.dispose);
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 320,
            height: 600,
            child: DsTextMagnifier(magnifierInfo: info),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(opacity(tester), 1);
    });
  });
}
