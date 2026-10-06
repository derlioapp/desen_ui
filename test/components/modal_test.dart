import 'dart:ui'
    show CheckedState, SemanticsRole, SemanticsValidationResult, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faz 6b: confirm dialog, panel, toast and select.
void main() {
  /// An app with one button that runs [onPressed] with its context.
  Widget app(
    void Function(BuildContext context) onPressed, {
    Size size = const Size(1000, 700),
    DsThemeData? theme,
  }) => MediaQuery(
    data: MediaQueryData(size: size),
    child: DsApp(
      theme: theme,
      home: Center(
        child: Builder(
          builder: (context) => DsButton(
            onPressed: () => onPressed(context),
            child: const Text('Aç'),
          ),
        ),
      ),
    ),
  );

  group('showDsConfirm', () {
    Future<bool?> ask(
      WidgetTester tester,
      Future<void> Function() answer,
    ) async {
      bool? result;
      await tester.pumpWidget(
        app(
          (context) async => result = await showDsConfirm(
            context: context,
            title: 'Projeyi sil?',
            description: 'Bu işlem geri alınamaz.',
            confirmLabel: 'Sil',
            destructive: true,
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      await answer();
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('confirm answers yes', (tester) async {
      expect(await ask(tester, () => tester.tap(find.text('Sil'))), isTrue);
    });

    testWidgets('cancel, Escape and the scrim answer no', (tester) async {
      expect(await ask(tester, () => tester.tap(find.text('Cancel'))), isFalse);
      expect(
        await ask(tester, () => tester.sendKeyEvent(LogicalKeyboardKey.escape)),
        isFalse,
      );
      expect(
        await ask(tester, () => tester.tapAt(const Offset(10, 10))),
        isFalse,
      );
    });

    testWidgets('system back answers no', (tester) async {
      expect(
        await ask(tester, () async {
          await tester.binding.handlePopRoute();
        }),
        isFalse,
      );
    });

    testWidgets('the safe choice has focus; Tab stays inside; focus returns', (
      tester,
    ) async {
      await tester.pumpWidget(
        app((context) => showDsConfirm(context: context, title: 'Emin misin?')),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      String focused() =>
          (FocusManager.instance.primaryFocus!.context!
                      .findAncestorWidgetOfExactType<DsButton>()!
                      .child
                  as Text)
              .data!;
      expect(focused(), 'Cancel');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focused(), 'Confirm');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focused(), 'Cancel', reason: 'focus is trapped in the dialog');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(focused(), 'Aç', reason: 'focus returns to the opener');
    });

    testWidgets('a dialog with no autofocus puts focus on its first control '
        '(ux M4)', (tester) async {
      await tester.pumpWidget(
        app(
          (context) => showDsDialog<void>(
            context: context,
            builder: (context) => DsDialog(
              title: const Text('Ayarlar'),
              actions: [
                DsButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Vazgeç'),
                ),
                DsButton(onPressed: () {}, child: const Text('Tamam')),
              ],
            ),
          ),
        ),
      );
      // Opened from the keyboard: a click does not focus the opener, and a
      // modal route gives focus back to the control that had it.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      String? focused() =>
          (FocusManager.instance.primaryFocus?.context
                      ?.findAncestorWidgetOfExactType<DsButton>()
                      ?.child
                  as Text?)
              ?.data;
      expect(focused(), 'Vazgeç');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focused(), 'Tamam');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(focused(), 'Aç', reason: 'focus returns to the opener');
    });

    testWidgets('announced as an alert dialog; carries the opener theme', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final dark = DsThemeData(brightness: Brightness.dark);
      await tester.pumpWidget(
        app(
          (context) => showDsConfirm(context: context, title: 'Emin misin?'),
          theme: dark,
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      final dialog = tester.getSemantics(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.role != null,
        ),
      );
      expect(dialog.getSemanticsData().role, SemanticsRole.alertDialog);
      final text = tester.widget<RichText>(
        find.descendant(
          of: find.text('Emin misin?'),
          matching: find.byType(RichText),
        ),
      );
      expect(text.text.style?.color, dark.colors.text);
      semantics.dispose();
    });
  });

  testWidgets('a non-dismissible dialog ignores Escape, the scrim and '
      'system back; its own action closes it (K-55)', (tester) async {
    await tester.pumpWidget(
      app(
        (context) => showDsDialog<void>(
          context: context,
          dismissible: false,
          builder: (context) => DsDialog(
            title: const Text('Bekle'),
            actions: [
              DsButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Bekle'), findsOneWidget);
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('Bekle'), findsNothing);
  });

  group('dialog layout and name (eng M3, bugs B13, ux V5, ux V3)', () {
    Future<void> open(
      WidgetTester tester, {
      required Size size,
      double textScale = 1,
      String message = 'Derlio Web ve 48 görev kalıcı olarak silinir.',
      EdgeInsets insets = EdgeInsets.zero,
      DsDensity? density,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            viewInsets: insets,
          ),
          child: DsApp(
            theme: density == null ? null : DsThemeData(density: density),
            home: Center(
              child: Builder(
                builder: (context) => DsButton(
                  onPressed: () => showDsConfirm(
                    context: context,
                    title: 'Projeyi sil?',
                    description: message,
                    confirmLabel: 'Kalıcı olarak sil',
                    cancelLabel: 'Projeyi koru',
                    destructive: true,
                    icon: const DsIcon(DsIcons.trash),
                  ),
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
    }

    Rect button(WidgetTester tester, String label) => tester.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(DsButton)),
    );

    testWidgets('320 x 480 at 200% text: no overflow, actions stack and '
        'stay on screen', (tester) async {
      await open(tester, size: const Size(320, 480), textScale: 2);
      expect(tester.takeException(), isNull);
      final cancel = button(tester, 'Projeyi koru');
      final confirm = button(tester, 'Kalıcı olarak sil');
      expect(confirm.bottom, lessThanOrEqualTo(480));
      expect(confirm.top, greaterThan(cancel.bottom), reason: 'stacked');
      expect(cancel.width, confirm.width);
    });

    testWidgets('a long message scrolls on a short window; actions stay', (
      tester,
    ) async {
      await open(
        tester,
        size: const Size(640, 320),
        density: DsDensity.compact,
        message: List.filled(30, 'Bu işlem geri alınamaz.').join(' '),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        button(tester, 'Kalıcı olarak sil').bottom,
        lessThanOrEqualTo(320),
      );
      final row = button(tester, 'Projeyi koru');
      expect(
        button(tester, 'Kalıcı olarak sil').top,
        row.top,
        reason: 'wide enough: side by side',
      );
    });

    testWidgets('narrow windows shrink the dialog', (tester) async {
      await open(tester, size: const Size(300, 600));
      expect(
        tester.getSize(find.byType(DsDialog)).width,
        lessThanOrEqualTo(300),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays above the on-screen keyboard', (tester) async {
      await open(
        tester,
        size: const Size(390, 844),
        insets: const EdgeInsets.only(bottom: 340),
      );
      expect(
        button(tester, 'Kalıcı olarak sil').bottom,
        lessThanOrEqualTo(844 - 340),
      );
    });

    testWidgets('named by its title for screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester, size: const Size(800, 600));
      final node = tester.getSemantics(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.role == SemanticsRole.alertDialog,
        ),
      );
      expect(node.label, 'Projeyi sil?');
      semantics.dispose();
    });
  });

  group('modal context (bugs B19, eng H2, eng L4)', () {
    testWidgets('an open dialog and its scrim follow a theme switch', (
      tester,
    ) async {
      late StateSetter setMode;
      var mode = DsThemeMode.light;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setMode = setState;
            return DsApp(
              themeMode: mode,
              home: Center(
                child: Builder(
                  builder: (context) => DsButton(
                    onPressed: () => showDsDialog<void>(
                      context: context,
                      builder: (_) => const DsDialog(title: Text('Hello')),
                    ),
                    child: const Text('Aç'),
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      Color scrim() => tester
          .widget<ColoredBox>(
            find.descendant(
              of: find.byType(ModalBarrier),
              matching: find.byType(ColoredBox),
            ),
          )
          .color;
      expect(DsTheme.of(tester.element(find.text('Hello'))).isDark, isFalse);
      final lightScrim = scrim();
      setMode(() => mode = DsThemeMode.dark);
      await tester.pumpAndSettle();
      final theme = DsTheme.of(tester.element(find.text('Hello')));
      expect(theme.isDark, isTrue);
      expect(scrim(), theme.colors.scrim);
      expect(scrim(), isNot(lightScrim));
    });

    testWidgets('carries the opener\'s subtree theme, component themes, '
        'direction and strings', (tester) async {
      final dark = DsThemeData(brightness: Brightness.dark);
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: DsTheme(
              data: dark,
              child: DsButtonTheme(
                data: const DsButtonThemeData(size: DsSize.xs),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: DsLocalizationScope(
                    localizations: const _Tr(),
                    child: Builder(
                      builder: (context) => DsButton(
                        onPressed: () =>
                            showDsConfirm(context: context, title: 'Q'),
                        child: const Text('Aç'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      final inside = tester.element(find.text('Q'));
      expect(DsTheme.of(inside), dark);
      expect(DsButtonTheme.of(inside).size, DsSize.xs);
      expect(Directionality.of(inside), TextDirection.rtl);
      expect(find.text('Vazgeç'), findsOneWidget);
    });

    testWidgets('disposes the curved animations it creates', (tester) async {
      final live = <Object>{};
      void track(ObjectEvent e) {
        if (e.object is! CurvedAnimation) return;
        if (e is ObjectCreated) live.add(e.object);
        if (e is ObjectDisposed) live.remove(e.object);
      }

      FlutterMemoryAllocations.instance.addListener(track);
      addTearDown(
        () => FlutterMemoryAllocations.instance.removeListener(track),
      );
      await tester.pumpWidget(
        app((context) => showDsConfirm(context: context, title: 'Q')),
      );
      await tester.pumpAndSettle();
      final before = live.length;
      await tester.tap(find.text('Aç'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final opening = live.length;
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(live.length, opening, reason: 'none allocated per frame');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(live.length, before);
    });
  });

  group('showDsPanel', () {
    Widget panelApp(Size size) => app(
      (context) => showDsPanel<void>(
        context: context,
        builder: (_) =>
            const DsPanel(title: Text('Ayrıntılar'), child: Text('İçerik')),
      ),
      size: size,
    );

    testWidgets('wide screens: from the end edge', (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(panelApp(const Size(1000, 700)));
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      final panel = tester.getRect(find.byType(DsPanel));
      expect(panel.right, greaterThan(900));
      expect(panel.left, greaterThan(500));
      await tester.tap(
        find.byWidgetPredicate((w) => w is DsIcon && w.icon == DsIcons.x),
      );
      await tester.pumpAndSettle();
      expect(find.text('İçerik'), findsNothing);
    });

    testWidgets('narrow screens: a bottom sheet that drags away', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(panelApp(const Size(390, 800)));
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      final panel = tester.getRect(find.byType(DsPanel));
      expect(panel.bottom, greaterThan(760));
      expect(panel.width, greaterThan(350));
      await tester.drag(find.text('Ayrıntılar'), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.text('İçerik'), findsNothing);
    });

    Future<void> openSheet(
      WidgetTester tester, {
      bool dismissible = true,
      EdgeInsets insets = EdgeInsets.zero,
    }) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: const Size(390, 800), viewInsets: insets),
          child: DsApp(
            home: Center(
              child: Builder(
                builder: (context) => DsButton(
                  onPressed: () => showDsPanel<void>(
                    context: context,
                    presentation: DsPanelPresentation.bottom,
                    dismissible: dismissible,
                    builder: (_) => const DsPanel(
                      title: Text('Ayrıntılar'),
                      child: Text('İçerik'),
                    ),
                  ),
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
    }

    testWidgets('a non-dismissible sheet ignores drag, fling and Escape and '
        'has no close button (bugs B4, ux V18)', (tester) async {
      await openSheet(tester, dismissible: false);
      expect(
        find.byWidgetPredicate((w) => w is DsIcon && w.icon == DsIcons.x),
        findsNothing,
      );
      await tester.fling(find.text('Ayrıntılar'), const Offset(0, 400), 2000);
      await tester.pumpAndSettle();
      await tester.drag(find.text('Ayrıntılar'), const Offset(0, 300));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('İçerik'), findsOneWidget);
    });

    testWidgets('a non-dismissible sheet ignores system back; a '
        'dismissible one closes (K-55)', (tester) async {
      await openSheet(tester, dismissible: false);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('İçerik'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await openSheet(tester);
      expect(find.text('İçerik'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('İçerik'), findsNothing);
    });

    testWidgets('a panel opens with focus on its first control (ux M4)', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          (context) => showDsPanel<void>(
            context: context,
            presentation: DsPanelPresentation.side,
            builder: (_) => DsPanel(
              title: const Text('Ayrıntılar'),
              showClose: false,
              child: DsButton(onPressed: () {}, child: const Text('Kaydet')),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      final button = FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<DsButton>();
      expect((button?.child as Text?)?.data, 'Kaydet');
    });

    testWidgets('an explicit close button closes a non-dismissible panel', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          (context) => showDsPanel<void>(
            context: context,
            presentation: DsPanelPresentation.side,
            dismissible: false,
            builder: (_) => const DsPanel(
              title: Text('Ayrıntılar'),
              showClose: true,
              child: Text('İçerik'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('İçerik'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close').last);
      await tester.pumpAndSettle();
      expect(find.text('İçerik'), findsNothing);
    });

    testWidgets('a slow drag past a third of the sheet height dismisses '
        '(bugs B31)', (tester) async {
      await openSheet(tester);
      final height = tester.getSize(find.byType(DsPanel)).height;
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Ayrıntılar')),
      );
      // Slowly, so it is not a fling: half the sheet's height.
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(Offset(0, height / 2 / 20));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('İçerik'), findsNothing);
    });

    testWidgets('a sheet stays above the on-screen keyboard (ux V17)', (
      tester,
    ) async {
      await openSheet(tester, insets: const EdgeInsets.only(bottom: 300));
      expect(
        tester.getRect(find.byType(DsPanel)).bottom,
        lessThanOrEqualTo(800 - 300),
      );
    });

    testWidgets('a panel is a dialog named by its title (ux V3)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openSheet(tester);
      final node = tester.getSemantics(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.role == SemanticsRole.dialog,
        ),
      );
      expect(node.label, 'Ayrıntılar');
      semantics.dispose();
    });
  });

  group('showDsToast', () {
    testWidgets('shows, pauses on hover, then leaves', (tester) async {
      await tester.pumpWidget(
        app(
          (context) => showDsToast(
            context: context,
            title: 'Kaydedildi',
            status: DsStatus.success,
            duration: const Duration(seconds: 2),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(find.text('Kaydedildi'), findsOneWidget);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(
        location: tester.getCenter(find.text('Kaydedildi')),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Kaydedildi'), findsOneWidget, reason: 'paused');
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Kaydedildi'), findsNothing);
    });

    testWidgets('the action runs and dismisses; a new toast replaces', (
      tester,
    ) async {
      var undone = 0;
      var n = 0;
      await tester.pumpWidget(
        app(
          (context) => showDsToast(
            context: context,
            title: 'Silindi ${++n}',
            actionLabel: 'Geri al',
            onAction: () => undone++,
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(find.text('Silindi 1'), findsNothing);
      expect(find.text('Silindi 2'), findsOneWidget);
      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(find.text('Silindi 2'), findsNothing);
    });

    testWidgets('announced as a live region', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app((context) => showDsToast(context: context, title: 'Kaydedildi')),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.text('Kaydedildi'))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      semantics.dispose();
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    });
  });

  group('DsSelect', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.macOS]) {
      testWidgets('${platform.name}: lines up with a text field beside it; '
          'the tap area grows without the layout', (tester) async {
        var opened = 0;
        await tester.pumpWidget(
          DsApp(
            theme: DsThemeData(platform: platform),
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 600,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    const Expanded(
                      child: DsField(
                        label: Text('E-posta'),
                        child: DsTextField(),
                      ),
                    ),
                    Expanded(
                      child: DsField(
                        label: const Text('Rol'),
                        child: DsSelect<String>(
                          value: null,
                          onChanged: (_) => opened++,
                          options: const [
                            DsSelectOption(value: 'a', label: 'Admin'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        final field = tester.getRect(find.byType(DsTextField));
        final select = tester.getRect(find.byType(DsSelect<String>));
        expect(select.top, field.top);
        expect(select.height, field.height);
        if (platform == TargetPlatform.android) {
          // Just above the drawn box, inside the 44px tap area.
          await tester.tapAt(Offset(select.center.dx, select.top - 1.5));
          await tester.pumpAndSettle();
          expect(find.text('Admin'), findsOneWidget, reason: 'opened');
        }
      });
    }

    Widget select(String? value, ValueChanged<String?>? onChanged) => DsApp(
      home: Center(
        child: SizedBox(
          width: 260,
          child: DsSelect<String>(
            value: value,
            onChanged: onChanged,
            semanticLabel: 'Proje',
            options: const [
              DsSelectOption(value: 'web', label: 'Derlio Web'),
              DsSelectOption(value: 'mobile', label: 'Derlio Mobil'),
              DsSelectOption(value: 'marketing', label: 'Pazarlama sitesi'),
              DsSelectOption(
                value: 'archive',
                label: 'Arşiv',
                detail: 'salt okunur',
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );

    testWidgets('placeholder, open at trigger width, choose, focus back', (
      tester,
    ) async {
      String? value;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (c, set) => select(value, (v) => set(() => value = v)),
        ),
      );
      expect(find.text('Select'), findsOneWidget);
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(DsMenu)).width,
        greaterThanOrEqualTo(260),
      );
      await tester.tap(find.text('Derlio Mobil'));
      await tester.pumpAndSettle();
      expect(value, 'mobile');
      expect(find.text('Derlio Web'), findsNothing, reason: 'closed');
      expect(find.text('Derlio Mobil'), findsOneWidget);
    });

    testWidgets('keyboard: the current option has focus; arrows, Enter', (
      tester,
    ) async {
      String? value = 'mobile';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (c, set) => select(value, (v) => set(() => value = v)),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final focused = FocusManager.instance.primaryFocus!.context!
          .findAncestorWidgetOfExactType<DsMenuItem>()!;
      expect((focused.label as Text).data, 'Derlio Mobil');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(value, 'web', reason: 'Arşiv is disabled: wraps to the first');
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<DsSelect<String>>(),
        isNotNull,
        reason: 'focus is back on the trigger',
      );
    });

    testWidgets('typing while closed picks without opening', (tester) async {
      String? value = 'web';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (c, set) => select(value, (v) => set(() => value = v)),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();
      expect(value, 'marketing');
      expect(find.byType(DsMenu), findsNothing);
    });

    testWidgets('announces what it chooses and the current value', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(select('web', (_) {}));
      final data = tester
          .getSemantics(find.bySemanticsLabel('Proje'))
          .getSemanticsData();
      expect(data.value, 'Derlio Web', reason: 'the value is a value');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isExpanded, Tristate.isFalse);
      expect(data.validationResult, SemanticsValidationResult.none);
      await tester.tap(find.text('Derlio Web'));
      await tester.pumpAndSettle();
      final option = tester
          .getSemantics(find.text('Derlio Mobil').last)
          .getSemanticsData();
      expect(option.role, SemanticsRole.menuItemRadio);
      expect(option.flagsCollection.isChecked, CheckedState.isFalse);
      semantics.dispose();
    });

    testWidgets('an error is announced and shown with an icon, not color '
        'alone (ux V8, V9)', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: SizedBox(
              width: 260,
              child: DsSelect<String>(
                value: null,
                error: true,
                onChanged: (_) {},
                semanticLabel: 'Proje',
                options: const [DsSelectOption(value: 'a', label: 'A')],
              ),
            ),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.bySemanticsLabel('Proje'))
          .getSemanticsData();
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect(
        find.byWidgetPredicate(
          (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('an emptied fieldError shadow list does not crash (eng M1)', (
      tester,
    ) async {
      final theme = DsThemeData(
        adjustShadows: (s, c, b) => s.copyWith(fieldError: const []),
      );
      await tester.pumpWidget(
        DsApp(
          theme: theme,
          home: Center(
            child: SizedBox(
              width: 200,
              child: DsSelect<String>(
                value: null,
                error: true,
                onChanged: (_) {},
                options: const [DsSelectOption(value: 'a', label: 'A')],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        DsSelect.defaultStyle(theme).resolve({WidgetState.error}).borderColor,
        theme.colors.danger.text,
      );
    });

    testWidgets('works in an unbounded width, as wide as its longest option '
        '(eng M2)', (tester) async {
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsSelect<String>(
                  value: 'a',
                  onChanged: (_) {},
                  options: const [
                    DsSelectOption(value: 'a', label: 'A'),
                    DsSelectOption(value: 'b', label: 'A much longer one'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final width = tester.getSize(find.byType(DsSelect<String>)).width;
      expect(width, greaterThan(140));
      expect(width, lessThan(400));
    });

    testWidgets('type-ahead with nothing chosen can pick the first option '
        '(bugs B17)', (tester) async {
      String? value;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => DsApp(
            home: Center(
              child: SizedBox(
                width: 200,
                child: DsSelect<String>(
                  value: value,
                  onChanged: (v) => setState(() => value = v),
                  options: const [
                    DsSelectOption(value: 'apple', label: 'Apple'),
                    DsSelectOption(value: 'avocado', label: 'Avocado'),
                    DsSelectOption(value: 'banana', label: 'Banana'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      expect(value, 'apple');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      expect(value, 'avocado');
    });

    testWidgets('disabled while open, its menu closes (bugs B32)', (
      tester,
    ) async {
      var enabled = true;
      late StateSetter set;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return select('web', enabled ? (_) {} : null);
          },
        ),
      );
      await tester.tap(find.text('Derlio Web'));
      await tester.pumpAndSettle();
      expect(find.byType(DsMenu), findsOneWidget);
      set(() => enabled = false);
      await tester.pumpAndSettle();
      expect(find.byType(DsMenu), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('options without an icon line up with those that have one '
        '(visual L5)', (tester) async {
      await tester.pumpWidget(
        DsApp(
          home: Center(
            child: SizedBox(
              width: 240,
              child: DsSelect<String>(
                value: 'a',
                onChanged: (_) {},
                options: const [
                  DsSelectOption(
                    value: 'a',
                    label: 'With icon',
                    leading: DsIcon(DsIcons.folder),
                  ),
                  DsSelectOption(value: 'b', label: 'Without'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('With icon'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Without')).dx,
        tester.getTopLeft(find.text('With icon').last).dx,
      );
    });

    testWidgets('Tab chooses the focused option, closes and moves on', (
      tester,
    ) async {
      String? value = 'web';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (c, set) => DsApp(
            home: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 260,
                    child: DsSelect<String>(
                      value: value,
                      onChanged: (v) => set(() => value = v),
                      options: const [
                        DsSelectOption(value: 'web', label: 'Derlio Web'),
                        DsSelectOption(value: 'mobile', label: 'Derlio Mobil'),
                      ],
                    ),
                  ),
                  DsButton(onPressed: () {}, child: const Text('Kaydet')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(value, 'mobile');
      expect(find.byType(DsMenu), findsNothing);
      expect(
        (FocusManager.instance.primaryFocus!.context!
                    .findAncestorWidgetOfExactType<DsButton>()!
                    .child
                as Text)
            .data,
        'Kaydet',
      );
    });
  });
}

class _Tr extends DsLocalizationsEn {
  const _Tr();

  @override
  String get cancel => 'Vazgeç';
}
