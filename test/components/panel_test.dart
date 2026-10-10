import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The panel's style, scrolling, keyboard, route and presentation.
void main() {
  /// Sizes the test window.
  void window(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// An app with one button that opens the panel [panel] builds, in a
  /// 1000 x 700 window unless the test sizes it.
  Widget app(
    WidgetTester tester,
    Widget Function(BuildContext context) panel, {
    DsPanelPresentation presentation = DsPanelPresentation.auto,
    RouteSettings? routeSettings,
  }) {
    // Not sized by the test yet.
    if (tester.view.devicePixelRatio != 1) {
      window(tester, const Size(1000, 700));
    }
    return DsApp(
      home: Center(
        child: Builder(
          builder: (context) => DsButton(
            onPressed: () => showDsPanel<void>(
              context: context,
              presentation: presentation,
              routeSettings: routeSettings,
              builder: panel,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  /// The panel's surface: the box its style colors and sizes.
  Finder surface() => find
      .ancestor(of: find.text('Title'), matching: find.byType(DsSurface))
      .first;

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('style', () {
    testWidgets('a side panel takes its width, colors and margin from the '
        'panel\'s own style', (tester) async {
      const color = Color(0xFF123456);
      await tester.pumpWidget(
        app(
          tester,
          (_) => const DsPanel(
            title: Text('Title'),
            style: DsPanelStyle(
              width: 700,
              background: color,
              margin: EdgeInsets.zero,
              borderRadius: BorderRadius.zero,
            ),
            child: Text('Body'),
          ),
          presentation: DsPanelPresentation.side,
        ),
      );
      await open(tester);
      final rect = tester.getRect(surface());
      expect(rect.width, 700);
      expect(rect.right, 1000);
      expect(rect.top, 0);
      expect(rect.bottom, 700);
      final box = tester.widget<DsSurface>(surface());
      expect(box.decoration.color, color);
      expect(box.decoration.borderRadius, BorderRadius.zero);
    });

    testWidgets('a bottom sheet takes its widest size from the panel\'s own '
        'style', (tester) async {
      await tester.pumpWidget(
        app(
          tester,
          (_) => const DsPanel(
            title: Text('Title'),
            style: DsPanelStyle(sheetMaxWidth: 300),
            child: Text('Body'),
          ),
          presentation: DsPanelPresentation.bottom,
        ),
      );
      await open(tester);
      expect(tester.getSize(surface()).width, 300);
    });

    testWidgets('the panel\'s style lays over the theme\'s', (tester) async {
      await tester.pumpWidget(
        DsPanelTheme(
          data: const DsPanelThemeData(style: DsPanelStyle(width: 500)),
          child: app(
            tester,
            (_) => const DsPanel(
              title: Text('Title'),
              style: DsPanelStyle(margin: EdgeInsets.zero),
              child: Text('Body'),
            ),
            presentation: DsPanelPresentation.side,
          ),
        ),
      );
      await open(tester);
      final rect = tester.getRect(surface());
      expect(rect.width, 500, reason: 'the theme\'s width');
      expect(rect.right, 1000, reason: 'the panel\'s margin');
    });

    testWidgets('the close button takes the panel\'s closeStyle, not the '
        'app\'s button theme', (tester) async {
      const fill = Color(0xFF123456);
      await tester.pumpWidget(
        DsButtonTheme(
          data: const DsButtonThemeData(
            style: DsButtonStyle(background: Color(0xFFFF0000)),
          ),
          child: app(
            tester,
            (_) => DsPanel(
              title: const Text('Title'),
              style: DsPanelStyle(
                closeStyle: DsButtonStyle(
                  background: fill,
                  height: 36,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Body'),
            ),
            presentation: DsPanelPresentation.side,
          ),
        ),
      );
      await open(tester);
      final close = find.bySemanticsLabel('Close');
      final box = find.descendant(
        of: find.ancestor(of: close, matching: find.byType(DsButton)).first,
        matching: find.byType(AnimatedContainer),
      );
      final decoration =
          tester.widget<AnimatedContainer>(box).decoration! as DsBoxDecoration;
      expect(decoration.color, fill);
      expect(decoration.borderRadius, BorderRadius.circular(18));
      expect(tester.getSize(box).height, 36);
    });
  });

  group('content that scrolls itself', () {
    for (final presentation in [
      DsPanelPresentation.side,
      DsPanelPresentation.bottom,
    ]) {
      testWidgets('${presentation.name}: a ListView child with scrollable: '
          'false gets a bounded height', (tester) async {
        await tester.pumpWidget(
          app(
            tester,
            (_) => DsPanel(
              title: const Text('Title'),
              scrollable: false,
              footer: const Text('Footer'),
              child: ListView.builder(
                itemCount: 200,
                itemBuilder: (context, i) =>
                    SizedBox(height: 40, child: Text('Row $i')),
              ),
            ),
            presentation: presentation,
          ),
        );
        await open(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Row 0'), findsOneWidget);
        expect(find.text('Row 199'), findsNothing, reason: 'built lazily');
        // The footer stays in view below the list.
        expect(tester.getRect(find.text('Footer')).bottom, lessThan(700));
        await tester.drag(find.text('Row 3'), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(find.text('Row 0'), findsNothing, reason: 'the list scrolls');
      });
    }
  });

  group('keyboard scrolling', () {
    Widget longPanel(BuildContext context) => DsPanel(
      title: const Text('Title'),
      footer: DsButton(onPressed: () {}, child: const Text('Save')),
      child: Column(
        children: [
          for (var i = 0; i < 60; i++)
            SizedBox(height: 40, child: Text('Line $i')),
        ],
      ),
    );

    ScrollPosition body(WidgetTester tester) => tester
        .state<ScrollableState>(
          find
              .ancestor(
                of: find.text('Line 0'),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;

    testWidgets('Page Down, Page Up, arrows, End and Home scroll the body '
        'with focus on the close button', (tester) async {
      await tester.pumpWidget(
        app(tester, longPanel, presentation: DsPanelPresentation.side),
      );
      await open(tester);
      final focus = FocusManager.instance.primaryFocus;
      expect(
        focus?.context?.findAncestorWidgetOfExactType<DsButton>(),
        isNotNull,
        reason: 'the close button has focus',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      final page = body(tester).pixels;
      expect(page, greaterThan(100));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(body(tester).pixels, greaterThan(page));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(body(tester).pixels, page);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(body(tester).pixels, body(tester).maxScrollExtent);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(body(tester).pixels, lessThan(body(tester).maxScrollExtent));
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(body(tester).pixels, 0);
      expect(
        FocusManager.instance.primaryFocus,
        focus,
        reason: 'focus stays put',
      );
    });

    testWidgets('a focused text field keeps the keys', (tester) async {
      await tester.pumpWidget(
        app(
          tester,
          (_) => DsPanel(
            title: const Text('Title'),
            child: Column(
              children: [
                const DsTextField(autofocus: true, semanticLabel: 'Name'),
                for (var i = 0; i < 60; i++)
                  SizedBox(height: 40, child: Text('Line $i')),
              ],
            ),
          ),
          presentation: DsPanelPresentation.side,
        ),
      );
      await open(tester);
      for (final key in [
        LogicalKeyboardKey.pageDown,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.end,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
      }
      expect(body(tester).pixels, 0);
    });

    testWidgets('a body that fits leaves the keys alone', (tester) async {
      var downs = 0;
      await tester.pumpWidget(
        app(
          tester,
          (_) => Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.arrowDown) {
                downs++;
              }
              return KeyEventResult.ignored;
            },
            child: const DsPanel(title: Text('Title'), child: Text('Line 0')),
          ),
          presentation: DsPanelPresentation.side,
        ),
      );
      await open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(downs, 1, reason: 'passed on to the ancestors');
    });
  });

  testWidgets('showDsPanel passes its route settings', (tester) async {
    RouteSettings? settings;
    await tester.pumpWidget(
      app(tester, (context) {
        settings = ModalRoute.of(context)!.settings;
        return const DsPanel(title: Text('Title'), child: Text('Body'));
      }, routeSettings: const RouteSettings(name: 'filters', arguments: 7)),
    );
    await open(tester);
    expect(settings?.name, 'filters');
    expect(settings?.arguments, 7);
  });

  testWidgets('a bottom sheet\'s drag gives screen readers no scroll '
      'action', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        tester,
        (_) => const DsPanel(title: Text('Title'), child: Text('Body')),
        presentation: DsPanelPresentation.bottom,
      ),
    );
    await open(tester);
    expect(find.text('Body'), findsOneWidget);
    for (final action in [
      SemanticsAction.scrollUp,
      SemanticsAction.scrollDown,
    ]) {
      expect(find.semantics.byAction(action), findsNothing);
    }
    semantics.dispose();
  });

  testWidgets('a bottom sheet whose content refuses to close goes back in '
      'place after a dismissing drag', (tester) async {
    window(tester, const Size(390, 800));
    var refused = 0;
    await tester.pumpWidget(
      app(
        tester,
        (_) => PopScope(
          // Unsaved changes: the app asks before closing.
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) refused++;
          },
          child: const DsPanel(title: Text('Title'), child: Text('Body')),
        ),
        presentation: DsPanelPresentation.bottom,
      ),
    );
    await open(tester);
    final rest = tester.getRect(surface());
    await tester.drag(find.text('Title'), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(refused, 1);
    expect(find.text('Body'), findsOneWidget);
    expect(tester.getRect(surface()), rest);
  });

  group('auto presentation follows the window', () {
    Future<void> openResizable(WidgetTester tester) async {
      window(tester, const Size(1000, 700));
      await tester.pumpWidget(
        app(
          tester,
          (_) => DsPanel(
            title: const Text('Title'),
            child: DsButton(onPressed: () {}, child: const Text('Save')),
          ),
        ),
      );
      await open(tester);
    }

    testWidgets('a side panel turns into a bottom sheet and back, keeping '
        'focus', (tester) async {
      await openResizable(tester);
      Rect rect() => tester.getRect(surface());
      expect(rect().width, 400, reason: 'a side panel');
      expect(rect().height, greaterThan(600));
      final focus = FocusManager.instance.primaryFocus;
      expect(
        focus?.context?.findAncestorWidgetOfExactType<DsButton>(),
        isNotNull,
      );

      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();
      expect(rect().width, greaterThan(370), reason: 'a bottom sheet');
      expect(rect().height, lessThan(400), reason: 'it hugs its content');
      expect(rect().bottom, greaterThan(780));
      expect(FocusManager.instance.primaryFocus, focus);

      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpAndSettle();
      expect(rect().width, 400, reason: 'a side panel again');
      expect(FocusManager.instance.primaryFocus, focus);
    });

    testWidgets('it then closes the way it now sits: down', (tester) async {
      await openResizable(tester);
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final slide = tester.widget<FractionalTranslation>(
        find
            .ancestor(
              of: find.byType(DsPanel),
              matching: find.byType(FractionalTranslation),
            )
            .first,
      );
      expect(slide.translation.dx, 0);
      expect(slide.translation.dy, greaterThan(0));
      await tester.pumpAndSettle();
    });
  });
}
