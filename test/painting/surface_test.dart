import 'dart:ui' show ImageFilter;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Floating layers are opaque, and a style can turn them into frosted
/// glass with a translucent background and a `backdropFilter`.
void main() {
  final blur = ImageFilter.blur(sigmaX: 20, sigmaY: 20);

  testWidgets('a layer filters nothing by default', (tester) async {
    final controller = DsOverlayController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      DsApp(
        home: Column(
          children: [
            const DsToolbar(children: [Text('Araç')]),
            DsPopover(
              controller: controller,
              contentBuilder: (_) => const Text('İçerik'),
              child: const Text('Aç'),
            ),
          ],
        ),
      ),
    );
    controller.open();
    await tester.pumpAndSettle();
    expect(find.text('İçerik'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('component themes make floating layers glass', (tester) async {
    final controller = DsOverlayController();
    addTearDown(controller.dispose);
    const fill = Color(0xB8FFFFFF);
    await tester.pumpWidget(
      DsApp(
        home: DsComponentThemes(
          themes: [
            DsPopoverThemeData(
              style: DsPopoverStyle(background: fill, backdropFilter: blur),
            ),
            DsToolbarThemeData(
              style: DsToolbarStyle(background: fill, backdropFilter: blur),
            ),
          ],
          child: Column(
            children: [
              const DsToolbar(children: [Text('Araç')]),
              DsPopover(
                controller: controller,
                contentBuilder: (_) => const Text('İçerik'),
                child: const Text('Aç'),
              ),
            ],
          ),
        ),
      ),
    );
    controller.open();
    await tester.pumpAndSettle();

    final filters = find.byType(BackdropFilter);
    expect(filters, findsNWidgets(2), reason: 'the toolbar and the popover');
    for (final f in tester.widgetList<BackdropFilter>(filters)) {
      expect(f.filter, blur);
    }
    // The popover's fill sits over the blur, clipped to its corners.
    final popover = find.ancestor(
      of: find.text('İçerik'),
      matching: find.byType(BackdropFilter),
    );
    expect(
      find.ancestor(of: popover, matching: find.byType(ClipPath)),
      findsWidgets,
    );
    final fills = tester
        .widgetList<DecoratedBox>(
          find.descendant(of: popover, matching: find.byType(DecoratedBox)),
        )
        .map((d) => d.decoration)
        .whereType<DsBoxDecoration>()
        .map((d) => d.color);
    expect(fills, contains(fill));
  });

  testWidgets('outer shadows stay outside the clipped glass', (tester) async {
    const ring = DsShadow(color: Color(0xFF000000), spread: 1);
    const inset = DsShadow(color: Color(0xFF000000), spread: 1, inset: true);
    await tester.pumpWidget(
      Center(
        child: DsSurface(
          decoration: DsBoxDecoration(
            color: const Color(0x80FFFFFF),
            borderRadius: BorderRadius.circular(12),
            shadows: [ring, inset],
          ),
          backdropFilter: blur,
          width: 100,
          child: const SizedBox(height: 40),
        ),
      ),
    );
    final boxes = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration as DsBoxDecoration)
        .toList();
    expect(boxes, hasLength(2));
    expect(boxes.first.shadows, [ring], reason: 'outside the clip');
    expect(boxes.first.color, isNull);
    expect(boxes.last.shadows, [inset], reason: 'inside, over the blur');
    expect(boxes.last.color, const Color(0x80FFFFFF));
    expect(tester.getSize(find.byType(DsSurface)).width, 100);
  });
}
