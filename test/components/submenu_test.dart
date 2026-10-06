import 'dart:ui' show SemanticsRole, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Submenus: `DsMenuItem.submenu`, WAI-ARIA menu keys, hover delay
/// and the safe triangle, placement, RTL.
void main() {
  late DsOverlayController controller;
  late List<String> chosen;
  setUp(() {
    controller = DsOverlayController();
    chosen = [];
  });
  tearDown(() => controller.dispose());

  List<Widget> items() => [
    DsMenuItem(
      label: const Text('Düzenle'),
      onPressed: () => chosen.add('Düzenle'),
    ),
    DsMenuItem.submenu(
      label: const Text('Taşı'),
      submenu: [
        DsMenuItem(
          label: const Text('Arşiv'),
          onPressed: () => chosen.add('Arşiv'),
        ),
        DsMenuItem(
          label: const Text('Belgeler'),
          onPressed: () => chosen.add('Belgeler'),
        ),
        DsMenuItem(
          label: const Text('Bütçe'),
          onPressed: () => chosen.add('Bütçe'),
        ),
      ],
    ),
    DsMenuItem(
      label: const Text('Paylaş…'),
      onPressed: () => chosen.add('Paylaş'),
    ),
    DsMenuItem(label: const Text('Sil'), onPressed: () => chosen.add('Sil')),
  ];

  Widget app({
    TextDirection direction = TextDirection.ltr,
    AlignmentGeometry alignment = Alignment.topCenter,
  }) => DsApp(
    builder: (context, child) =>
        Directionality(textDirection: direction, child: child!),
    home: Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: DsMenuAnchor(
          controller: controller,
          semanticLabel: 'Dosya',
          items: items(),
          child: DsButton(
            onPressed: controller.toggle,
            child: const Text('Menü'),
          ),
        ),
      ),
    ),
  );

  String? focusedLabel() =>
      (FocusManager.instance.primaryFocus?.context
                  ?.findAncestorWidgetOfExactType<DsMenuItem>()
                  ?.label
              as Text?)
          ?.data;

  Future<void> openWithKeyboard(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Menü'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedLabel(), 'Taşı');
  }

  group('keyboard', () {
    testWidgets('Right opens and focuses the first item; Left closes and '
        'returns focus', (tester) async {
      await openWithKeyboard(tester);
      expect(find.text('Arşiv'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Arşiv'), findsOneWidget);
      expect(focusedLabel(), 'Arşiv');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedLabel(), 'Belgeler', reason: 'arrows move in the submenu');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('Arşiv'), findsNothing);
      expect(focusedLabel(), 'Taşı');
      expect(controller.isOpen, isTrue, reason: 'the parent stays open');
    });

    testWidgets('Enter and Space open it too', (tester) async {
      await openWithKeyboard(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(focusedLabel(), 'Arşiv');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(focusedLabel(), 'Arşiv');
    });

    testWidgets('Escape closes one level at a time', (tester) async {
      await openWithKeyboard(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Arşiv'), findsNothing);
      expect(controller.isOpen, isTrue);
      expect(focusedLabel(), 'Taşı');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(find.text('Düzenle'), findsNothing);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<DsButton>(),
        isNotNull,
        reason: 'focus is back on the trigger',
      );
    });

    testWidgets('type-ahead works per level', (tester) async {
      await openWithKeyboard(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      expect(focusedLabel(), 'Belgeler');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      expect(focusedLabel(), 'Bütçe');
      // "P" matches nothing in the submenu; the parent's "Paylaş…" is not
      // reached from here.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      expect(focusedLabel(), 'Bütçe');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      expect(focusedLabel(), 'Paylaş…');
    });

    testWidgets('choosing in the submenu runs it and closes every level', (
      tester,
    ) async {
      await openWithKeyboard(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, ['Belgeler']);
      expect(controller.isOpen, isFalse);
      expect(find.text('Belgeler'), findsNothing);
      expect(find.text('Taşı'), findsNothing);
    });

    testWidgets('Tab in the submenu closes every level and moves on', (
      tester,
    ) async {
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsMenuAnchor(
                  controller: controller,
                  items: items(),
                  child: DsButton(
                    onPressed: controller.toggle,
                    child: const Text('Menü'),
                  ),
                ),
                DsButton(onPressed: () {}, child: const Text('Sonraki')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(focusedLabel(), 'Arşiv');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(find.text('Arşiv'), findsNothing);
      final focused = FocusManager.instance.primaryFocus!.context!
          .findAncestorWidgetOfExactType<DsButton>()!;
      expect((focused.child as Text).data, 'Sonraki');
    });

    testWidgets('moving to another item closes an open submenu', (
      tester,
    ) async {
      await openWithKeyboard(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      // Open by pointer-less click path: activate, then arrow away.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(focusedLabel(), 'Paylaş…');
      expect(find.text('Arşiv'), findsNothing);
    });
  });

  group('pointer', () {
    Future<TestGesture> mouse(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      return gesture;
    }

    testWidgets('resting on the item opens it after the submenu delay, '
        'without taking focus', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      final gesture = await mouse(tester);
      await gesture.moveTo(tester.getCenter(find.text('Taşı')));
      final delay = const DsMotion().submenuDelay;
      await tester.pump(delay * .6);
      expect(find.text('Arşiv'), findsNothing, reason: 'not before the delay');
      await tester.pump(delay * .6);
      await tester.pumpAndSettle();
      expect(find.text('Arşiv'), findsOneWidget);
      expect(focusedLabel(), 'Taşı', reason: 'focus stays on the item');
    });

    testWidgets('passing over the item does not open it', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      final gesture = await mouse(tester);
      await gesture.moveTo(tester.getCenter(find.text('Taşı')));
      await tester.pump(const DsMotion().submenuDelay ~/ 3);
      await gesture.moveTo(tester.getCenter(find.text('Sil')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Arşiv'), findsNothing);
    });

    testWidgets('a click opens it at once', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Taşı'));
      await tester.pumpAndSettle();
      expect(find.text('Arşiv'), findsOneWidget);
      await tester.tap(find.text('Arşiv'));
      await tester.pumpAndSettle();
      expect(chosen, ['Arşiv']);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('moving diagonally toward the submenu keeps it open (safe '
        'triangle); resting on another item hands over after the delay', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      final gesture = await mouse(tester);
      final trigger = tester.getRect(
        find
            .ancestor(of: find.text('Taşı'), matching: find.byType(DsMenuItem))
            .first,
      );
      await gesture.moveTo(trigger.center);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text('Arşiv'), findsOneWidget);
      final submenu = tester.getRect(find.byType(DsMenu).last);
      expect(submenu.left, greaterThanOrEqualTo(trigger.right - 1));

      // Toward the submenu's lower part, crossing "Paylaş…" on the way.
      final share = tester.getRect(
        find.ancestor(
          of: find.text('Paylaş…'),
          matching: find.byType(DsMenuItem),
        ),
      );
      await gesture.moveTo(Offset(trigger.right - 4, trigger.bottom - 2));
      await gesture.moveTo(Offset(trigger.right - 2, share.top + 3));
      await tester.pump(const DsMotion().submenuDelay ~/ 3);
      expect(find.text('Arşiv'), findsOneWidget, reason: 'still aiming');
      expect(focusedLabel(), 'Taşı');

      // It stops there: after the delay the item under it takes over.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(focusedLabel(), 'Paylaş…');
      expect(find.text('Arşiv'), findsNothing);
    });

    testWidgets('reaching the submenu ends the trip; its items take focus', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      final gesture = await mouse(tester);
      final trigger = tester.getRect(
        find
            .ancestor(of: find.text('Taşı'), matching: find.byType(DsMenuItem))
            .first,
      );
      await gesture.moveTo(trigger.center);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await gesture.moveTo(Offset(trigger.right - 2, trigger.bottom + 3));
      await gesture.moveTo(tester.getCenter(find.text('Belgeler')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Arşiv'), findsOneWidget);
      expect(focusedLabel(), 'Belgeler');
    });

    testWidgets('moving away from the triangle hands over at once', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      final gesture = await mouse(tester);
      await gesture.moveTo(tester.getCenter(find.text('Taşı')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      // Straight down to the start of "Sil": away from the submenu.
      final sil = tester.getRect(find.text('Sil'));
      await gesture.moveTo(sil.centerLeft);
      await tester.pumpAndSettle();
      expect(focusedLabel(), 'Sil');
      expect(find.text('Arşiv'), findsNothing);
    });
  });

  group('placement', () {
    testWidgets('opens on the end side, its first item level with the item', (
      tester,
    ) async {
      await openWithKeyboard(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      final item = tester.getRect(
        find
            .ancestor(of: find.text('Taşı'), matching: find.byType(DsMenuItem))
            .first,
      );
      final first = tester.getRect(
        find
            .ancestor(of: find.text('Arşiv'), matching: find.byType(DsMenuItem))
            .first,
      );
      expect(first.left, greaterThan(item.right));
      expect(first.top, moreOrLessEquals(item.top, epsilon: 0.5));
    });

    testWidgets('flips to the start side at the window edge', (tester) async {
      await tester.pumpWidget(app(alignment: Alignment.topRight));
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      final item = tester.getRect(
        find
            .ancestor(of: find.text('Taşı'), matching: find.byType(DsMenuItem))
            .first,
      );
      final submenu = tester.getRect(find.byType(DsMenu).last);
      expect(submenu.right, lessThanOrEqualTo(item.left + 1));
      expect(submenu.right, lessThanOrEqualTo(tester.view.physicalSize.width));
    });

    testWidgets('RTL: opens to the left, Left opens and Right closes', (
      tester,
    ) async {
      await tester.pumpWidget(app(direction: TextDirection.rtl));
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Arşiv'), findsNothing, reason: 'Right is "back"');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(focusedLabel(), 'Arşiv');
      final item = tester.getRect(
        find
            .ancestor(of: find.text('Taşı'), matching: find.byType(DsMenuItem))
            .first,
      );
      final submenu = tester.getRect(find.byType(DsMenu).last);
      expect(submenu.right, lessThanOrEqualTo(item.left + 1));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Arşiv'), findsNothing);
      expect(focusedLabel(), 'Taşı');
    });
  });

  testWidgets('semantics: a menu item that is expanded or collapsed; the '
      'submenu is a menu named by it', (tester) async {
    final semantics = tester.ensureSemantics();
    await openWithKeyboard(tester);
    var data = tester.getSemantics(find.text('Taşı')).getSemanticsData();
    expect(data.role, SemanticsRole.menuItem);
    expect(data.flagsCollection.isExpanded, Tristate.isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    data = tester.getSemantics(find.text('Taşı')).getSemanticsData();
    expect(data.flagsCollection.isExpanded, Tristate.isTrue);
    expect(
      find.bySemanticsLabel('Taşı'),
      findsWidgets,
      reason: 'the submenu is named by its item',
    );
    semantics.dispose();
  });

  testWidgets('works in a context menu', (tester) async {
    await tester.pumpWidget(
      DsApp(
        home: Center(
          child: DsContextMenuRegion(
            items: items(),
            child: const SizedBox(width: 300, height: 200),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SizedBox).last),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'Arşiv');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, ['Arşiv']);
    expect(find.text('Düzenle'), findsNothing);
  });

  testWidgets('needs only an Overlay, no app or DsScope', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Center(
                  child: SizedBox(width: 220, child: DsMenu(children: items())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Taşı'));
    await tester.pumpAndSettle();
    expect(find.text('Arşiv'), findsOneWidget);
    await tester.tap(find.text('Belgeler'));
    await tester.pumpAndSettle();
    expect(chosen, ['Belgeler']);
    expect(find.text('Arşiv'), findsNothing);
  });

  testWidgets('a disabled submenu item does not open', (tester) async {
    await tester.pumpWidget(
      DsApp(
        home: Center(
          child: DsMenu(
            children: [
              DsMenuItem(label: const Text('A'), onPressed: () {}),
              const DsMenuItem.submenu(
                label: Text('Taşı'),
                enabled: false,
                submenu: [DsMenuItem(label: Text('Arşiv'), onPressed: null)],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Taşı'));
    await tester.pumpAndSettle();
    expect(find.text('Arşiv'), findsNothing);
  });
}
