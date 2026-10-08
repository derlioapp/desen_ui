import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// DsEdgeFade and DsEdgeFadeScrollView: a horizontal scrollable fades the
/// edge that hides content, and only that edge. Regression tests for the
/// behavior the toolbar, text fields and chip rows already share, now
/// that apps can use it.
void main() {
  final boundary = GlobalKey();
  const solid = Color(0xFF2050C0);

  /// A 200px window on a 600px solid strip, scrolled by [controller].
  Widget strip({
    required ScrollController controller,
    TextDirection direction = TextDirection.ltr,
    double width = 600,
    bool enabled = true,
    bool view = false,
  }) {
    const child = SizedBox(
      width: 600,
      height: 20,
      child: ColoredBox(color: solid),
    );
    final sized = SizedBox(width: width, height: 20, child: child);
    return Directionality(
      textDirection: direction,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: boundary,
          child: SizedBox(
            width: 200,
            child: view
                ? DsEdgeFadeScrollView(controller: controller, child: sized)
                : DsEdgeFade(
                    enabled: enabled,
                    child: SingleChildScrollView(
                      controller: controller,
                      scrollDirection: Axis.horizontal,
                      child: sized,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// The alpha (0–255) painted at the strip's left and right edge pixels.
  Future<(int, int)> edges(WidgetTester tester) async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await render.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!;
    });
    final w = render.size.width.round();
    int alpha(int x) => bytes!.getUint8((10 * w + x) * 4 + 3);
    return (alpha(0), alpha(w - 1));
  }

  testWidgets('fades only the edge that hides content', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(strip(controller: controller));
    await tester.pump();
    var (left, right) = await edges(tester);
    expect(left, 255);
    expect(right, lessThan(40));

    controller.jumpTo(200);
    await tester.pump();
    (left, right) = await edges(tester);
    expect(left, lessThan(40));
    expect(right, lessThan(40));

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    (left, right) = await edges(tester);
    expect(left, lessThan(40));
    expect(right, 255);
  });

  testWidgets('follows a right-to-left layout', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      strip(controller: controller, direction: TextDirection.rtl),
    );
    await tester.pump();
    final (left, right) = await edges(tester);
    expect(left, lessThan(40));
    expect(right, 255);
  });

  testWidgets('nothing fades when everything fits or when disabled', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(strip(controller: controller, width: 150));
    await tester.pump();
    expect(find.byType(ShaderMask), findsNothing);

    await tester.pumpWidget(strip(controller: controller, enabled: false));
    await tester.pump();
    expect(find.byType(ShaderMask), findsNothing);
    expect(await edges(tester), (255, 255));
  });

  testWidgets('the scroll view fades the same way', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(strip(controller: controller, view: true));
    await tester.pump();
    final (left, right) = await edges(tester);
    expect(left, 255);
    expect(right, lessThan(40));
  });
  testWidgets('a faded edge clips content painted past the box', (
    tester,
  ) async {
    // A scroll view that paints past its box, as one does to leave room
    // for focus rings, scrolled so content hides at the left.
    final controller = ScrollController(initialScrollOffset: 400);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: boundary,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: 200,
                child: DsEdgeFade(
                  child: SingleChildScrollView(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: const SizedBox(
                      width: 600,
                      height: 20,
                      child: ColoredBox(color: solid),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await render.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!;
    });
    final w = render.size.width.round();
    int alpha(int x) => bytes!.getUint8((10 * w + x) * 4 + 3);
    // Left of the box: clipped, not a sharp sliver of the hidden content.
    expect(alpha(10), 0);
  });
}
