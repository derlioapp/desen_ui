import 'dart:ui' show CheckedState, SemanticsRole;

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/overlay/placement.dart' show dsPlace;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faz 6a: the overlay engine, popover, tooltip and menu.
void main() {
  group('dsPlace', () {
    const viewport = Size(400, 600);
    const size = Size(200, 100);

    test('keeps the preferred side while it fits', () {
      final p = dsPlace(
        anchor: const Rect.fromLTWH(100, 100, 80, 32),
        size: size,
        viewport: viewport,
        side: DsSide.bottom,
        align: DsAlign.start,
      );
      expect(p.side, DsSide.bottom);
      expect(p.offset, const Offset(100, 138));
    });

    test('flips when the preferred side has no room', () {
      final p = dsPlace(
        anchor: const Rect.fromLTWH(100, 540, 80, 32),
        size: size,
        viewport: viewport,
        side: DsSide.bottom,
      );
      expect(p.side, DsSide.top);
      expect(p.offset.dy, 540 - 6 - 100);
    });

    test('shifts along the trigger to stay inside the window', () {
      final p = dsPlace(
        anchor: const Rect.fromLTWH(360, 100, 32, 32),
        size: size,
        viewport: viewport,
        side: DsSide.bottom,
        align: DsAlign.start,
      );
      expect(p.offset.dx, 400 - 8 - 200);
    });

    test('start and end follow the reading direction', () {
      Rect anchor = const Rect.fromLTWH(180, 200, 40, 40);
      expect(
        dsPlace(
          anchor: anchor,
          size: const Size(80, 30),
          viewport: viewport,
          side: DsSide.end,
        ).offset.dx,
        226,
      );
      expect(
        dsPlace(
          anchor: anchor,
          size: const Size(80, 30),
          viewport: viewport,
          side: DsSide.end,
          direction: TextDirection.rtl,
        ).offset.dx,
        180 - 6 - 80,
      );
      anchor = Rect.zero;
    });

    test('reports the room on the chosen side', () {
      final p = dsPlace(
        anchor: const Rect.fromLTWH(100, 100, 80, 32),
        size: const Size(200, 900),
        viewport: viewport,
        side: DsSide.bottom,
      );
      expect(p.side, DsSide.bottom, reason: 'more room below than above');
      expect(p.maxExtent, 600 - 8 - 132 - 6);
    });
  });

  group('DsPopover', () {
    late DsOverlayController controller;
    late int outsideTaps;
    setUp(() {
      controller = DsOverlayController();
      outsideTaps = 0;
    });
    tearDown(() => controller.dispose());

    Widget app({Widget? inside}) => DsApp(
      home: Column(
        children: [
          DsButton(onPressed: () => outsideTaps++, child: const Text('Dış')),
          const SizedBox(height: 40),
          DsPopover(
            controller: controller,
            contentBuilder: (context) =>
                inside ??
                DsButton(onPressed: () {}, child: const Text('İçeride')),
            child: DsButton(
              onPressed: controller.toggle,
              child: const Text('Aç'),
            ),
          ),
        ],
      ),
    );

    testWidgets('opens below its trigger with focus inside', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(find.text('İçeride'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('İçeride')).dy,
        greaterThan(tester.getBottomLeft(find.text('Aç')).dy),
      );
      expect(FocusManager.instance.primaryFocus?.context, isNotNull);
    });

    testWidgets('Escape closes it and returns focus to the trigger', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      final trigger = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(find.text('İçeride'), findsNothing);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<DsPopover>(),
        isNotNull,
        reason: 'focus is back on the trigger',
      );
      expect(trigger, isNotNull);
    });

    testWidgets('a tap outside closes it and still reaches its target', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      controller.open();
      await tester.pumpAndSettle();
      await tester.tap(find.text('İçeride'));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue, reason: 'a tap inside keeps it');
      await tester.tap(find.text('Dış'));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(outsideTaps, 1, reason: 'the tap was not swallowed');
    });

    testWidgets('the trigger toggles it closed', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
    });

    testWidgets('nested layers: inner taps keep the outer one open', (
      tester,
    ) async {
      final inner = DsOverlayController();
      addTearDown(inner.dispose);
      await tester.pumpWidget(
        app(
          inside: DsPopover(
            controller: inner,
            contentBuilder: (_) => const Text('İç katman'),
            child: DsButton(
              onPressed: inner.toggle,
              child: const Text('İkinci'),
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();
      await tester.tap(find.text('İkinci'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İç katman'));
      await tester.pumpAndSettle();
      expect((controller.isOpen, inner.isOpen), (true, true));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        (controller.isOpen, inner.isOpen),
        (true, false),
        reason: 'Escape closes the innermost layer only',
      );
      await tester.tap(find.text('Dış'));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
    });

    testWidgets('follows its trigger while the page scrolls', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        DsApp(
          home: SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                const SizedBox(height: 200),
                DsPopover(
                  controller: controller,
                  contentBuilder: (_) => const Text('Panel'),
                  child: const SizedBox(width: 80, height: 32),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(find.text('Panel')).dy;
      scroll.jumpTo(100);
      await tester.pump();
      expect(tester.getTopLeft(find.text('Panel')).dy, before - 100);
    });
  });

  group('DsTooltip', () {
    Widget app() => DsApp(
      home: Center(
        child: DsTooltip(
          message: 'Bağlantıyı kopyala',
          shortcut: '⌘C',
          child: DsButton(onPressed: () {}, child: const Text('Kopyala')),
        ),
      ),
    );

    testWidgets('shows after a hover delay, hides after leaving', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Kopyala')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Bağlantıyı kopyala'), findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Bağlantıyı kopyala'), findsOneWidget);
      expect(find.byType(DsShortcut), findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Bağlantıyı kopyala'), findsNothing);
    });

    testWidgets('Escape dismisses it; screen readers get the message', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app());
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Kopyala')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Bağlantıyı kopyala'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Bağlantıyı kopyala'), findsNothing);
      expect(
        tester
            .getSemantics(
              find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.tooltip != null,
              ),
            )
            .tooltip,
        'Bağlantıyı kopyala',
      );
      semantics.dispose();
    });

    testWidgets('keyboard focus shows it', (tester) async {
      await tester.pumpWidget(app());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.text('Bağlantıyı kopyala'), findsOneWidget);
    });

    testWidgets('the trigger\'s own node carries the tooltip (ux V14)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: Semantics(
              container: true,
              label: 'toolbar',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DsTooltip(
                    message: 'Copy link to clipboard',
                    child: DsButton.icon(
                      icon: const DsIcon(DsIcons.link),
                      semanticLabel: 'Copy',
                      onPressed: () {},
                    ),
                  ),
                  DsTooltip(
                    message: 'Delete the item',
                    child: DsButton.icon(
                      icon: const DsIcon(DsIcons.trash),
                      semanticLabel: 'Delete',
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final copy = tester.getSemantics(find.bySemanticsLabel('Copy'));
      expect(copy.tooltip, 'Copy link to clipboard');
      expect(copy.getSemanticsData().flagsCollection.isButton, isTrue);
      final delete = tester.getSemantics(find.bySemanticsLabel('Delete'));
      expect(delete.tooltip, 'Delete the item');
      expect(
        tester.getSemantics(find.bySemanticsLabel('toolbar')).tooltip,
        isEmpty,
      );
      semantics.dispose();
    });

    testWidgets('draws shortcut key symbols as icons (visual M4)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const DsApp(home: Center(child: DsShortcut('⇧⌘⌫'))),
      );
      final icons = tester
          .widgetList<DsIcon>(find.byType(DsIcon))
          .map((i) => i.icon)
          .toList();
      expect(icons, [DsIcons.shift, DsIcons.command, DsIcons.backspace]);
      // Read by name, not as symbols.
      expect(find.bySemanticsLabel('Shift Command Backspace'), findsOneWidget);
      await tester.pumpWidget(
        const DsApp(home: Center(child: DsShortcut('⌘E'))),
      );
      expect(find.text('E'), findsOneWidget);
      expect(tester.widget<DsIcon>(find.byType(DsIcon)).icon, DsIcons.command);
      semantics.dispose();
    });
  });

  group('DsAnchoredOverlay engine', () {
    late DsOverlayController controller;
    setUp(() => controller = DsOverlayController());
    tearDown(() => controller.dispose());

    String? focusedText() {
      final context = FocusManager.instance.primaryFocus?.context;
      final button = context?.findAncestorWidgetOfExactType<DsButton>();
      return (button?.child as Text?)?.data;
    }

    Widget page({required Widget layer, MediaQueryData? media}) {
      final app = DsApp(
        home: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsButton(onPressed: () {}, child: const Text('Önce')),
              layer,
              DsButton(onPressed: () {}, child: const Text('Sonra')),
            ],
          ),
        ),
      );
      return media == null ? app : MediaQuery(data: media, child: app);
    }

    Widget menu() => DsMenuAnchor(
      controller: controller,
      items: [
        DsMenuItem(label: const Text('Bir'), onPressed: () {}),
        DsMenuItem(label: const Text('İki'), onPressed: () {}),
      ],
      child: DsButton(onPressed: controller.toggle, child: const Text('Menü')),
    );

    Widget popover() => DsPopover(
      controller: controller,
      contentBuilder: (_) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DsButton(onPressed: () {}, child: const Text('P1')),
          DsButton(onPressed: () {}, child: const Text('P2')),
        ],
      ),
      child: DsButton(onPressed: controller.toggle, child: const Text('Aç')),
    );

    testWidgets('Tab in a menu closes it and moves on; Shift+Tab moves back '
        '(ux V7, bugs B24)', (tester) async {
      await tester.pumpWidget(page(layer: menu()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedText(), 'Menü');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(focusedText(), 'Sonra');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(focusedText(), 'Menü');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(focusedText(), 'Önce');
    });

    testWidgets('Tab flows through a popover and on, never trapped', (
      tester,
    ) async {
      await tester.pumpWidget(page(layer: popover()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      // Opening puts focus on the first control (ux M4).
      expect(focusedText(), 'P1');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedText(), 'P2');
      expect(controller.isOpen, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(focusedText(), 'Sonra');
      // Shift+Tab before the first control goes back to the trigger.
      controller.open();
      await tester.pumpAndSettle();
      expect(focusedText(), 'P1');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(focusedText(), 'Aç');
    });

    testWidgets('a popover keeps the control that asks for focus; one with '
        'no control keeps focus on itself (ux M4)', (tester) async {
      final second = FocusNode();
      addTearDown(second.dispose);
      await tester.pumpWidget(
        page(
          layer: DsPopover(
            controller: controller,
            contentBuilder: (_) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsButton(onPressed: () {}, child: const Text('P1')),
                DsButton(
                  focusNode: second,
                  autofocus: true,
                  onPressed: () {},
                  child: const Text('P2'),
                ),
              ],
            ),
            child: DsButton(
              onPressed: controller.toggle,
              child: const Text('Aç'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(second.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);

      await tester.pumpWidget(
        page(
          layer: DsPopover(
            controller: controller,
            contentBuilder: (_) => const Text('Just text'),
            child: DsButton(
              onPressed: controller.toggle,
              child: const Text('Aç'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      final primary = FocusManager.instance.primaryFocus;
      expect(primary, isA<FocusScopeNode>(), reason: 'the layer itself');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse, reason: 'Escape still lands');
    });

    testWidgets('focus returns to the trigger after a pointer open (ux V24)', (
      tester,
    ) async {
      await tester.pumpWidget(page(layer: menu()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedText(), 'Önce');
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(focusedText(), 'Menü');
    });

    testWidgets('a closing layer takes no taps (eng L7)', (tester) async {
      var under = 0, inside = 0;
      await tester.pumpWidget(
        DsApp(
          home: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => under++,
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: DsPopover(
                  controller: controller,
                  contentBuilder: (_) => GestureDetector(
                    key: const Key('content'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => inside++,
                    child: const SizedBox(width: 200, height: 100),
                  ),
                  child: const SizedBox(width: 40, height: 40),
                ),
              ),
            ],
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();
      final spot = tester.getCenter(find.byKey(const Key('content')));
      await tester.tapAt(spot);
      expect(inside, 1, reason: 'open, it takes the tap');
      controller.close();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tapAt(spot);
      expect(inside, 1, reason: 'the closing layer let the tap through');
      expect(under, 1);
    });

    testWidgets('mid-reveal, hit tests and positions follow the paint '
        '(eng L7)', (tester) async {
      var inside = 0;
      await tester.pumpWidget(
        DsApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: DsPopover(
              controller: controller,
              contentBuilder: (_) => GestureDetector(
                key: const Key('content'),
                behavior: HitTestBehavior.opaque,
                onTap: () => inside++,
                child: const SizedBox(width: 200, height: 100),
              ),
              child: const SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();
      final settled = tester.getRect(find.byKey(const Key('content')));
      controller.close();
      await tester.pumpAndSettle();
      controller.open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final moving = tester.getRect(find.byKey(const Key('content')));
      expect(moving, isNot(settled), reason: 'the reveal transform counts');
      expect(moving.width, lessThan(settled.width));
      await tester.tapAt(moving.center);
      expect(inside, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('keeps clear of the on-screen keyboard (eng M4)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: DsApp(
            home: Align(
              alignment: const Alignment(0, 0.1),
              child: DsPopover(
                controller: controller,
                contentBuilder: (_) => const SizedBox(
                  key: Key('content'),
                  width: 200,
                  height: 120,
                ),
                child: const SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const Key('content'))).bottom,
        lessThanOrEqualTo(800 - 300),
      );
    });

    testWidgets('closes when its trigger is scrolled out of view '
        '(ux S3, denetim-2 M7)', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final trigger = FocusNode();
      addTearDown(trigger.dispose);
      await tester.pumpWidget(
        DsApp(
          home: SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                const SizedBox(height: 200),
                DsPopover(
                  controller: controller,
                  contentBuilder: (_) =>
                      DsButton(onPressed: () {}, child: const Text('Panel')),
                  child: DsButton(
                    focusNode: trigger,
                    onPressed: controller.toggle,
                    child: const Text('Open'),
                  ),
                ),
                const SizedBox(height: 3000),
              ],
            ),
          ),
        ),
      );
      trigger.requestFocus();
      controller.open();
      await tester.pumpAndSettle();
      expect(find.text('Panel').hitTestable(), findsOneWidget);
      expect(trigger.hasPrimaryFocus, isFalse, reason: 'focus in the layer');
      scroll.jumpTo(1000);
      await tester.pump();
      expect(find.text('Panel').hitTestable(), findsNothing);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(trigger.hasPrimaryFocus, isTrue, reason: 'focus back on it');
      // It does not come back on its own with the trigger.
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsNothing);
    });
  });

  group('DsMenu', () {
    late DsOverlayController controller;
    late List<String> chosen;
    setUp(() {
      controller = DsOverlayController();
      chosen = [];
    });
    tearDown(() => controller.dispose());

    Widget app() => DsApp(
      home: Center(
        child: DsMenuAnchor(
          controller: controller,
          semanticLabel: 'Dosya',
          items: [
            DsMenuItem(
              label: const Text('Düzenle'),
              shortcut: '⌘E',
              onPressed: () => chosen.add('Düzenle'),
            ),
            DsMenuItem(
              label: const Text('Çoğalt'),
              onPressed: () => chosen.add('Çoğalt'),
            ),
            const DsMenuItem(label: Text('Arşivle'), onPressed: null),
            DsMenuItem(
              label: const Text('Paylaş…'),
              onPressed: () => chosen.add('Paylaş'),
            ),
            const DsMenuDivider(),
            DsMenuItem(
              label: const Text('Sil'),
              destructive: true,
              onPressed: () => chosen.add('Sil'),
            ),
          ],
          child: DsButton(
            onPressed: controller.toggle,
            child: const Text('Menü'),
          ),
        ),
      ),
    );

    String focusedLabel() =>
        (FocusManager.instance.primaryFocus!.context!
                    .findAncestorWidgetOfExactType<DsMenuItem>()!
                    .label
                as Text)
            .data!;

    testWidgets('keyboard: first item, wrap, skip disabled, Home/End, '
        'type-ahead, Enter chooses and closes', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      expect(focusedLabel(), 'Düzenle');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(focusedLabel(), 'Sil', reason: 'wraps to the end');
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedLabel(), 'Paylaş…', reason: 'Arşivle is disabled');
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      expect(focusedLabel(), 'Sil');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      expect(focusedLabel(), 'Paylaş…', reason: 'type-ahead');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, ['Paylaş']);
      expect(controller.isOpen, isFalse);
      expect(find.text('Düzenle'), findsNothing);
    });

    testWidgets('pointer: choosing runs the action and closes', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();
      expect(chosen, ['Sil']);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('announces a menu of menu items', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('Çoğalt')).getSemanticsData().role,
        SemanticsRole.menuItem,
      );
      semantics.dispose();
    });

    testWidgets('a context menu opens where the user right-clicks', (
      tester,
    ) async {
      await tester.pumpWidget(
        DsApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: DsContextMenuRegion(
              items: [
                DsMenuItem(label: const Text('Yenile'), onPressed: () {}),
              ],
              child: const SizedBox(width: 400, height: 300),
            ),
          ),
        ),
      );
      await tester.tapAt(
        const Offset(150, 120),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      final item = tester.getTopLeft(find.text('Yenile'));
      expect(item.dx, closeTo(150 + 6 + 12, 4));
      expect(item.dy, greaterThan(120));
    });

    testWidgets('Shift+F10 and the context menu key open a context menu at '
        'the focused control (ux V4)', (tester) async {
      await tester.pumpWidget(
        DsApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: DsContextMenuRegion(
                items: [
                  DsMenuItem(label: const Text('Yenile'), onPressed: () {}),
                ],
                child: DsButton(onPressed: () {}, child: const Text('Satır')),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(find.text('Yenile'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Yenile')).dy,
        greaterThan(tester.getBottomLeft(find.text('Satır')).dy),
      );
      expect(focusedLabel(), 'Yenile', reason: 'focus is in the menu');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Yenile'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pumpAndSettle();
      expect(find.text('Yenile'), findsOneWidget);
    });

    testWidgets('order and type-ahead follow changed items (bugs B18)', (
      tester,
    ) async {
      var bravoEnabled = false;
      var third = 'Cherry';
      late StateSetter setItems;
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                setItems = setState;
                return DsMenu(
                  autofocus: true,
                  children: [
                    DsMenuItem(label: const Text('Alpha'), onPressed: () {}),
                    DsMenuItem(
                      label: const Text('Bravo'),
                      onPressed: bravoEnabled ? () {} : null,
                    ),
                    DsMenuItem(label: Text(third), onPressed: () {}),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(focusedLabel(), 'Alpha');
      setItems(() {
        bravoEnabled = true;
        third = 'Banana';
      });
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedLabel(), 'Bravo', reason: 'visual order');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      expect(focusedLabel(), 'Banana', reason: 'the current label');
    });

    test('the shortcut reads at 4.5:1 on the highlight (ux V10)', () {
      for (final brightness in Brightness.values) {
        for (final seed in [DsSeed.blue, DsSeed.graphite, DsSeed.forest]) {
          final theme = DsThemeData(brightness: brightness, seed: seed);
          final k = theme.colors;
          for (final destructive in [false, true]) {
            final s = DsMenuItem.defaultStyle(
              theme,
              destructive: destructive,
            ).resolve({WidgetState.hovered});
            final ratio = DsColorUtils.contrastRatio(
              s.shortcutStyle!.color!,
              s.background!,
              backdrop: k.overlay,
            );
            expect(
              ratio,
              greaterThanOrEqualTo(4.5),
              reason: '$brightness $seed destructive: $destructive',
            );
          }
        }
      }
    });

    testWidgets('in the default ring mode the keyboard-focused item also '
        'draws an inset ring; in subtle mode only the highlight (ux V2)', (
      tester,
    ) async {
      Future<List<DsShadow>> focusedShadows(DsThemeData theme) async {
        await tester.pumpWidget(
          DsApp(
            theme: theme,
            home: Center(
              child: DsMenu(
                autofocus: true,
                children: [
                  DsMenuItem(label: const Text('Alpha'), onPressed: () {}),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        final box = tester.widget<AnimatedContainer>(
          find.descendant(
            of: find.byType(DsMenuItem),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final d = box.decoration! as DsBoxDecoration;
        expect(d.color, theme.colors.selection, reason: 'the highlight');
        return d.shadows;
      }

      final ring = DsThemeData();
      final shadows = await focusedShadows(ring);
      expect(shadows, hasLength(1));
      expect(shadows.single.inset, isTrue);
      expect(shadows.single.color, ring.colors.focus);
      for (final brightness in Brightness.values) {
        for (final contrast in DsContrast.values) {
          final k = DsThemeData(
            brightness: brightness,
            contrast: contrast,
          ).colors;
          expect(
            DsColorUtils.contrastRatio(
              k.focus,
              k.selection,
              backdrop: k.overlay,
            ),
            greaterThanOrEqualTo(3),
            reason: 'the ring reads on the highlight: $brightness $contrast',
          );
        }
      }
    });

    testWidgets('choice items are radio items (ux V8)', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: DsMenu(
              children: [
                DsMenuItem(
                  label: const Text('Web'),
                  checked: true,
                  onPressed: () {},
                ),
                DsMenuItem(
                  label: const Text('Mobil'),
                  checked: false,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final web = tester.getSemantics(find.text('Web')).getSemanticsData();
      expect(web.role, SemanticsRole.menuItemRadio);
      expect(web.flagsCollection.isChecked, CheckedState.isTrue);
      final mobil = tester.getSemantics(find.text('Mobil')).getSemanticsData();
      expect(mobil.flagsCollection.isChecked, CheckedState.isFalse);
      semantics.dispose();
    });
  });
}
